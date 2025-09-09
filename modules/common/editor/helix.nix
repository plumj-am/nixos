{ lib, ... }:
let
  inherit (lib) enabled;
in
{
  programs.helix = enabled {
    settings.theme = "gruvbox_dark_hard";
    settings.editor = {
      auto-completion    = true;
      bufferline         = "multiple";
      color-modes        = true;
      cursorline         = true;
      file-picker.hidden = false;
      idle-timeout       = 0;
      shell              = [ "nu" "--commands" ];
      text-width         = 100;
    };
    settings.editor.cursor-shape = {
      insert = "block";
      normal = "block";
      select = "block";
    };
    settings.editor.statusline.mode = {
      insert = "INSERT";
      normal = "NORMAL";
      select = "SELECT";
    };
    settings.editor.indent-guides = {
      character = "▏";
      render = true;
    };
    settings.editor.whitespace = {
      characters.tab = "→";
      render.tab     = "all";
    };
  };
}
