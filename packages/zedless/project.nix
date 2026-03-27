{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.zedless =
        (pkgs.zed-editor.overrideAttrs (old: {
          nativeBuildInputs = old.nativeBuildInputs ++ [
            pkgs.ast-grep
            (pkgs.python3.withPackages (p: [ p.toml ]))
          ];
          preBuild = ''
            cd ..
            python3 ${inputs.zedless-patches}/patch.py
            cd source
          '';
        })).fhs;
    };
}
