{
  programs.nvf.settings.vim = {
    leaderKey = " ";
    lineNumberMode = "relNumber";
    preventJunkFiles = true; # covers swapfile, backup, writebackup
    cmdHeight = 1;
    updateTime = 50;
    showMode = false;
    bell = "none";
    mapTimeout = 500;
    search = {
      ignorecase = true;
      smartcase = true;
    };
    tabWidth = 8;
    shiftWidth = 8;
    expandTab = false;
    autoIndent = true;
    smartIndent = true;
    splitBelow = true;
    splitRight = true;
    showTabline = 0;
    wordWrap = false;

    # these via lua because they are not supported above
    luaConfigRC.options = # lua
      ''
        local o = vim.o
        o.fileformat = "unix"
        o.fileformats = "unix,dos"
        o.termguicolors = true
        o.mouse = ""
        o.softtabstop = 8
        o.pumheight = 8
        o.smoothscroll = true
        o.scrolloff = 8
        o.sidescrolloff = 10
        o.signcolumn = "no"
        o.incsearch = true
        o.hlsearch = true
        o.colorcolumn = "80"
        o.cursorline = true
        o.completeopt = "menuone,noselect"
        o.guicursor = ""
        o.undofile = true
        o.swapfile = false
        o.backup = false
        o.writebackup = false
        o.fillchars = "eob:~,fold: ,foldopen:,foldsep: ,foldclose:,vert:▏,lastline:▏"
        o.conceallevel = 0
        o.foldcolumn = "0"
        o.foldenable = false
        o.foldlevel = 99
        o.foldlevelstart = 99
        o.foldmethod = "indent"
        o.autochdir = false
      '';
  };
}
