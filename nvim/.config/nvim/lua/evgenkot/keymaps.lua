-- Centralized plugin keymaps
-- All plugin-related key mappings defined in one place.

local opts = { noremap = true, silent = true }

-- LSP keymaps
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "Diagnostic float" }))
vim.keymap.set("n", "gD", vim.lsp.buf.type_definition, vim.tbl_extend("force", opts, { desc = "Type definition" }))
vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
vim.keymap.set("n", "<leader>gd", vim.lsp.buf.type_definition, vim.tbl_extend("force", opts, { desc = "Type definition" }))
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename symbol" }))

-- Telescope keymaps (deferred require)
vim.keymap.set("n", "<leader>ff", function()
    require("telescope.builtin").find_files()
end, vim.tbl_extend("force", opts, { desc = "Find files" }))

vim.keymap.set("n", "<leader>fgf", function()
    require("telescope.builtin").git_files()
end, vim.tbl_extend("force", opts, { desc = "Git files" }))

vim.keymap.set("n", "<leader>fw", function()
    local word = vim.fn.expand("<cword>")
    require("telescope.builtin").grep_string({ search = word })
end, vim.tbl_extend("force", opts, { desc = "Grep word under cursor" }))

vim.keymap.set("n", "<leader>fW", function()
    local word = vim.fn.expand("<cWORD>")
    require("telescope.builtin").grep_string({ search = word })
end, vim.tbl_extend("force", opts, { desc = "Grep WORD under cursor" }))

vim.keymap.set("n", "<leader>fgr", function()
    require("telescope.builtin").grep_string({ search = vim.fn.input("Grep > ") })
end, vim.tbl_extend("force", opts, { desc = "Grep string" }))

vim.keymap.set("n", "<leader>fh", function()
    require("telescope.builtin").help_tags()
end, vim.tbl_extend("force", opts, { desc = "Help tags" }))

-- Gitsigns keymaps
vim.keymap.set("n", "<leader>gp", "<cmd>Gitsigns preview_hunk_inline<CR>", vim.tbl_extend("force", opts, { desc = "Preview hunk inline" }))
vim.keymap.set("n", "<leader>gb", "<cmd>Gitsigns toggle_current_line_blame<CR>", vim.tbl_extend("force", opts, { desc = "Toggle line blame" }))
vim.keymap.set("n", "<leader>gr", "<cmd>Gitsigns reset_hunk<CR>", vim.tbl_extend("force", opts, { desc = "Reset hunk" }))

-- Undotree keymap
vim.keymap.set("n", "<leader>u", "<cmd>UndotreeToggle<CR>", vim.tbl_extend("force", opts, { desc = "Toggle undotree" }))

-- Ansible Vault keymaps (visual mode)
vim.keymap.set("v", "<leader>ae", ":<C-u>VaultEncryptRange<CR>", vim.tbl_extend("force", opts, { desc = "Ansible Vault Encrypt" }))
vim.keymap.set("v", "<leader>ad", ":<C-u>VaultDecryptRange<CR>", vim.tbl_extend("force", opts, { desc = "Ansible Vault Decrypt" }))
