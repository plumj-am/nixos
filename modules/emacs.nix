{
  flake.modules.common.emacs =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.meta) getExe;
      inherit (config) theme;

      # Overlay applied locally via appendOverlays instead of `nixpkgs.overlays`:
      # only the wrapper below needs the overlay attrs, so host pkgs stay untouched.
      withEmacsOverlay = pkgs: pkgs.appendOverlays [ inputs.emacs-overlay.overlays.default ];

      lspServers = [
        pkgs.nil
        pkgs.nixd
        pkgs.markdown-oxide
        pkgs.taplo
        pkgs.yaml-language-server
        pkgs.vscode-json-languageserver
        pkgs.haskell-language-server
      ];

      emacsTheme = if theme.isDark then "doom-gruvbox" else "doom-gruvbox-light";
      font = "${theme.font.mono.name}-${toString theme.font.size.tiny}";

      # not on MELPA
      jjMode =
        let
          d = builtins.substring 0 8 inputs.jj-mode-el.lastModifiedDate;
        in
        (epkgs pkgs).melpaBuild {
          pname = "jj-mode";
          version = "0.0.1-unstable-${lib.substring 0 4 d}-${lib.substring 4 2 d}-${lib.substring 6 2 d}";
          src = inputs.jj-mode-el;
          files = ''("jj-mode.el")'';
          packageRequires = [ (epkgs pkgs).magit ];
        };

      initElText = # scheme
        ''
          ;;; init.el --- Declarative configuration. -*- lexical-binding: t; -*-
          ;;; Commentary:
          ;; Managed by Nix; packages come from emacsWithPackagesFromUsePackage.
          ;;; Code:

          (setq package-enable-at-startup nil
                package-quickstart nil
                native-comp-async-report-warnings-errors 'silent)

          ;; UI
          (add-to-list 'default-frame-alist '(font . "${font}"))
          (set-face-attribute 'default nil :font "${font}")
          (menu-bar-mode -1)
          (tool-bar-mode -1)
          (scroll-bar-mode -1)
          (global-hl-line-mode 1)

          (setq scroll-margin 8
            scroll-conservatively 101
            scroll-step 1
            auto-window-vscroll nil)

          (add-hook 'prog-mode-hook #'display-line-numbers-mode)
          (add-hook 'org-mode-hook #'display-line-numbers-mode)

          ;; jj/git owns history; keep the tree clean.
          (setq make-backup-files nil
                create-lockfiles nil
                use-short-answers t
                project-vc-extra-root-markers '(".jj"))

          (recentf-mode 1)
          (save-place-mode 1)

          (use-package doom-themes
            :config
            (load-theme '${emacsTheme} t))

          ;; Load before helix: its require-time setup wires avy/mc into goto mode.
          (use-package avy
            :demand t)
          (use-package multiple-cursors
            :demand t)

          (use-package helix
            :demand t
            :config
            (helix-mode)
            ;; jj-mode (magit-section) owns its own keys (n/p/g/c/...);
            ;; keep modal editing out of *jj-log* & co.
            (advice-add #'helix-mode-maybe-activate :before-while
                        (lambda () (not (derived-mode-p 'jj-mode)))))

          (which-key-mode 1)

          (use-package vertico
            :demand t
            :config (vertico-mode 1))
          (use-package orderless
            :demand t
            :custom (completion-styles '(orderless basic)))
          (use-package marginalia
            :demand t
            :config (marginalia-mode 1))
          (use-package consult)
          (use-package corfu
            :demand t
            :custom
            (corfu-auto t)
            (corfu-auto-delay 0.1)
            (corfu-auto-prefix 1)
            :init (global-corfu-mode 1))
          (use-package cape
            :config (add-to-list 'completion-at-point-functions #'cape-file))

          ;; Org
          (setq org-directory "~/notes"
                org-agenda-files (list org-directory)
                org-log-done 'time)
          (with-eval-after-load 'org
            (require 'org-tempo))
          (use-package org-modern
            :hook (org-mode . org-modern-mode))

          (use-package rust-mode
            :mode ("\\.rs\\'" . rust-ts-mode))

          (use-package nix-mode
            :mode ("\\.nix\\'" . nix-ts-mode))

          ;; Tree-sitter
          (add-to-list 'treesit-extra-load-path "${(epkgs pkgs).treesit-grammars.with-all-grammars}/lib")
          (setq treesit-font-lock-level 4)
          (setq major-mode-remap-alist
                '((yaml-mode . yaml-ts-mode)
                  (json-mode . json-ts-mode)
                  (toml-mode . toml-ts-mode)
                  (bash-mode . bash-ts-mode)
                  (c-mode . c-ts-mode)
                  (c++-mode . c++-ts-mode)
                  (python-mode . python-ts-mode)
                  (js-mode . js-ts-mode)
                  (typescript-mode . typescript-ts-mode)
                  (tsx-mode . tsx-ts-mode)
                  (markdown-mode . markdown-ts-mode)
                  (haskell-mode . haskell-ts-mode)
                  (nix-mode . nix-ts-mode)
                  (nushell-mode . nushell-ts-mode)))

          (use-package nix-ts-mode)
          (use-package nushell-ts-mode)
          (use-package markdown-ts-mode)
          (use-package haskell-ts-mode)

          ;; Terminal
          (use-package vterm
            :custom
            (vterm-shell "${getExe pkgs.nushell}")
            (vterm-always-compile-module nil))

          (global-unset-key (kbd "C-v"))
          (keymap-global-set "C-S-v" #'clipboard-yank)

          (defun vterm-new ()
            "Start a fresh vterm buffer."
            (interactive)
            (vterm (generate-new-buffer-name "vterm")))
          (keymap-global-set "C-v t" #'vterm-new)

          (setq jj-executable "${getExe pkgs.jujutsu}")
          ;; see package definition above
          (use-package jj-mode
            :ensure nil
            :bind ("C-v j" . jj-log))

          ;; Eglot (built-in)
          (use-package eglot
            :ensure nil
            :hook ((rust-ts-mode nix-ts-mode haskell-ts-mode markdown-ts-mode
                    yaml-ts-mode json-ts-mode toml-ts-mode typescript-ts-mode
                    tsx-ts-mode bash-ts-mode nushell-ts-mode) . eglot-ensure)
            :custom (eglot-autoshutdown t)
            :config
            ;; Prepend overrides; defaults below remain for unlisted modes.
            (setq eglot-server-programs
                  (append '((nix-ts-mode "nil")
                            (rust-ts-mode "rust-analyzer")
                            (haskell-ts-mode "haskell-language-server")
                            (yaml-ts-mode "yaml-language-server")
                            (json-ts-mode "vscode-json-languageserver" "--stdio")
                            (toml-ts-mode "taplo" "lsp")
                            (markdown-ts-mode "markdown-oxide" "server")
                            (typescript-ts-mode "deno" "lsp")
                            (tsx-ts-mode "deno" "lsp")
                            (bash-ts-mode "bash-language-server")
                            (nushell-ts-mode "nu" "--lsp"))
                          eglot-server-programs)))

          (use-package eldoc
            :ensure nil
            :hook (prog-mode . eldoc-mode)
            :custom
            (eldoc-idle-delay 0.1)
            (eldoc-echo-area-use-multiline-p nil)
            (eldoc-echo-area-prefer-doc-buffer t)
            :config
            (add-to-list 'display-buffer-alist
                         '("\\*eldoc"
                           (display-buffer-reuse-window
                            display-buffer-at-bottom)
                           (window-height . 0.25)
                           (preserve-size . (nil . t)))))

          (defun my/eldoc-toggle ()
            "Toggle the Eldoc documentation window."
            (interactive)
            (let* ((buffer (eldoc-doc-buffer))
                   (window (get-buffer-window buffer t)))
              (if (window-live-p window)
                  (delete-window window)
                (display-buffer buffer))))

          (with-eval-after-load 'helix
            (helix-define-key 'space "k" #'my/eldoc-toggle))

          ;; Make C-w a prefix
          (global-unset-key (kbd "C-w"))
          (define-prefix-command 'window-prefix)
          (global-set-key (kbd "C-w") 'window-prefix)

          (define-key window-prefix (kbd "h") #'windmove-left)
          (define-key window-prefix (kbd "j") #'windmove-down)
          (define-key window-prefix (kbd "k") #'windmove-up)
          (define-key window-prefix (kbd "l") #'windmove-right)
          (define-key window-prefix (kbd "w") #'other-window)
          (define-key window-prefix (kbd "s") #'split-window-below)
          (define-key window-prefix (kbd "x") #'split-window-right)
          (define-key window-prefix (kbd "q") #'delete-window)

          (use-package windresize)
          (define-key window-prefix (kbd "r") #'windresize)

          (provide 'init)
          ;;; init.el ends here
        '';

      initElFile = pkgs.writers.writeText "init.el" initElText;

      epkgs = pkgs: (withEmacsOverlay pkgs).emacsPackagesFor (withEmacsOverlay pkgs).emacs30-pgtk;

      package = (withEmacsOverlay pkgs).emacsWithPackagesFromUsePackage {
        config = initElFile;
        package = (withEmacsOverlay pkgs).emacs30-pgtk;
        alwaysEnsure = true;
        extraEmacsPackages = epkgs: [
          epkgs.treesit-grammars.with-all-grammars
          epkgs.eldoc-box
          epkgs.magit
          jjMode
        ];
      };
    in
    {
      services.emacs = {
        enable = true;
        inherit package;
        startWithGraphical = true;
      };

      hjem.extraModule = {
        packages = [ package ] ++ lspServers;

        xdg.config.files = {
          "emacs/init.el".source = initElFile;

          "emacs/early-init.el".text = # scheme
            ''
              ;;; early-init.el --- Pre-init. -*- lexical-binding: t; -*-
              (setq package-enable-at-startup nil
                    native-comp-async-report-warnings-errors 'silent
                    gc-cons-threshold (* 100 1024 1024))
              (fset #'yes-or-no-p #'y-or-n-p)
            '';

        };
      };
    };
}
