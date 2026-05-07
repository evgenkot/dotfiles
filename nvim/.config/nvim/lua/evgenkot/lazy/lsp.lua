return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "mason-org/mason.nvim",
        "mason-org/mason-lspconfig.nvim",
        "j-hui/fidget.nvim",
        "hrsh7th/cmp-nvim-lsp",
    },

    config = function()
        require("fidget").setup({})
        require("mason").setup()

        local capabilities = vim.tbl_deep_extend(
            "force",
            {},
            vim.lsp.protocol.make_client_capabilities(),
            require("cmp_nvim_lsp").default_capabilities())

        vim.lsp.config("*", {
            capabilities = capabilities,
        })

        require("evgenkot.lsp")

        require("mason-lspconfig").setup({
            ensure_installed = {
                "lua_ls",
                "rust_analyzer",
                "ts_ls",
                "clangd",
                "gopls",
                "helm_ls",
                "yamlls",
            },
            automatic_enable = true,
        })

        vim.diagnostic.config({
            float = {
                focusable = false,
                style = "minimal",
                border = "single",
                source = "always",
                header = "",
                prefix = "",
            },
        })
    end
}
