local o = vim.o

o.fileformat = "unix"
o.fileformats = "unix,dos"

o.autochdir = false

o.termguicolors = true
o.mouse = ""

o.tabstop = 8
o.softtabstop = 8
o.shiftwidth = 8
o.expandtab = false

o.pumheight = 8

o.ignorecase = true
o.smartcase = true

o.smartindent = true

o.smoothscroll = true

o.scrolloff = 8
o.sidescrolloff = 10
o.signcolumn = "no"

o.wrap = false
o.splitright = true
o.splitbelow = true

o.number = true
o.relativenumber = true
o.incsearch = true
o.hlsearch = true

o.showmode = false
o.showtabline = 0

o.colorcolumn = "80"

o.cursorline = true

o.completeopt = "menuone,noselect"

-- Shell configuration handled by system

o.updatetime = 50

o.guicursor = ""

o.undofile = true
o.swapfile = false
o.backup = false
o.writebackup = false

o.fillchars = "eob:~,fold: ,foldopen:,foldsep: ,foldclose:,vert:▏,lastline:▏"
o.conceallevel = 0
o.foldcolumn = "0"
o.foldenable = false
o.foldlevel = 99
o.foldlevelstart = 99
o.foldmethod = "indent"
--o.foldexpr = 'nvim_treesitter#foldexpr()'
--o.foldexpr = 'v:lua.vim.lsp.foldexpr()'
