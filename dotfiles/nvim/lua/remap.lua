vim.g.mapleader = " "

-- thanks primeagen
MAP("x", "<leader>p", [["_dP]], { desc = "paste over text but keep clipboard" })
MAP({ "n", "v" }, "<leader>y", [["+y]], { desc = "yank selection to system clipboard" })
MAP("n", "<leader>Y", [["+Y]], { desc = "yank line to system clipboard" })
MAP({ "n", "v" }, "<leader>d", '"_d', { desc = "delete without yank" })
MAP("n", "J", "mzJ`z", { desc = "better line joins" })
MAP(
	"n",
	"<leader>sr",
	[[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
	{ desc = "instant search and replace current word" }
)
MAP("v", "J", ":m '>+1<CR>gv=gv", { desc = "move line down" })
MAP("v", "K", ":m '<-2<CR>gv=gv", { desc = "move line up" })

-- Center cursor on various movements
MAP("n", "<C-d>", "<C-d>zz", { desc = "1/2 page down + center cursor" })
MAP("n", "<C-u>", "<C-u>zz", { desc = "1/2 page up + center cursor" })
MAP("n", "n", "nzz", { desc = "center cursor on next search result" })
MAP("n", "N", "Nzz", { desc = "center cursor on previous search result" })

-- Start/end of line movements
MAP("n", "H", "^", { desc = "move to first non-blank character of line" })
MAP("n", "L", "$", { desc = "move to last character of line" })

-- Switch panes
MAP("n", "<C-h>", "<C-w>h", { desc = "switch to left pane" })
MAP("n", "<C-j>", "<C-w>j", { desc = "switch to below pane" })
MAP("n", "<C-k>", "<C-w>k", { desc = "switch to above pane" })
MAP("n", "<C-l>", "<C-w>l", { desc = "switch to right pane" })

-- Visual mode mappings
MAP("v", "<C-d>", "<C-d>zz", { desc = "1/2 page down + center cursor" })
MAP("v", "<C-u>", "<C-u>zz", { desc = "1/2 page up + center cursor" })
MAP("v", "n", "nzz", { desc = "center cursor on next search result" })
MAP("v", "N", "Nzz", { desc = "center cursor on previous search result" })

-- switch buffers
-- MAP('n', '<leader>h', ":bprevious<CR>", { desc = "previous buffer" })
-- MAP('n', '<leader>l', ":bnext<CR>", { desc = "next buffer" })

-- not needed now that I use conform
-- MAP('n', '<leader>gg', "gg=G``", {desc = "Indent entire file and return to last edit position"})

MAP(
	"n",
	"<leader>tt",
	"<cmd>:vs<cr><cmd>term<cr>",
	{ desc = "open a terminal in a vertical split" }
)

MAP("n", "<leader>qq", "<cmd>clo<cr>", { desc = "close window" })

MAP(
	"n",
	"<leader><esc><esc>",
	"<cmd>silent nohl<cr>",
	{ desc = "disable search highlight" }
)
