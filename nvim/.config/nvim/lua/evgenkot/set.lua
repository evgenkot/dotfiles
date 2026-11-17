vim.opt.nu = true
vim.opt.relativenumber = true

-- Accept Normal/Visual commands when the system layout is Russian.
local function escape_langmap(str)
    return vim.fn.escape(str, [[;,"|\]])
end

local en = [[`qwertyuiop[]asdfghjkl;'zxcvbnm,.]]
local ru = [[ёйцукенгшщзхъфывапролджэячсмитьбю]]
local en_shift = [[~QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>]]
local ru_shift = [[ЁЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ]]

vim.opt.langmap = table.concat({
    escape_langmap(ru_shift) .. ";" .. escape_langmap(en_shift),
    escape_langmap(ru) .. ";" .. escape_langmap(en),
}, ",")
vim.opt.langremap = false

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.g.netrw_banner = 0

vim.opt.smartindent = true

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
