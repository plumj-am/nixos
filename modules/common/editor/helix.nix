{ lib, config, ... }:
let
  inherit (lib) enabled;
in
{
  programs.helix = enabled {
    settings.theme = config.theme.helix;
    settings.editor = {
      true-color         = true;
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
