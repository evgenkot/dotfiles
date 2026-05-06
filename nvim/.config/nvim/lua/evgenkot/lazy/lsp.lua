return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "mason-org/mason.nvim",
        "mason-org/mason-lspconfig.nvim",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "hrsh7th/nvim-cmp",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
        "j-hui/fidget.nvim",
    },

    config = function()
        local cmp = require('cmp')
        local cmp_lsp = require("cmp_nvim_lsp")
        local capabilities = vim.tbl_deep_extend(
            "force",
            {},
            vim.lsp.protocol.make_client_capabilities(),
            cmp_lsp.default_capabilities())

        require("fidget").setup({})
        require("mason").setup()

        -- Global defaults applied to every server configured via vim.lsp.config
        vim.lsp.config("*", {
            capabilities = capabilities,
        })

        -- Per-server configuration (merged with the "*" defaults above)
        vim.lsp.config("helm_ls", {
            filetypes = { "helm", "helmfile" },
            settings = {
                ["helm-ls"] = {
                    yamlls = {
                        enabled = true,
                        path = "yaml-language-server",
                        enabledForFilesGlob = "*.{yaml,yml}",
                        initTimeoutSeconds = 3,
                        diagnosticsLimit = 50,
                        showDiagnosticsDirectly = false,
                    },
                    valuesFiles = {
                        mainValuesFile = "values.yaml",
                        lintOverlayValuesFile = "values.lint.yaml",
                        additionalValuesFilesGlobPattern = "values*.yaml",
                    },
                    helmLint = {
                        enabled = true,
                        ignoredMessages = {},
                    },
                    logLevel = "info",
                },
            },
        })

        vim.lsp.config("yamlls", {
            filetypes = { "yaml", "yml" },
            settings = {
                yaml = {
                    schemas = {
                        ["https://json.schemastore.org/chart.json"] = "Chart.yaml",
                    },
                    completion = true,
                    hover = true,
                },
            },
        })

        vim.lsp.config("lua_ls", {
            settings = {
                Lua = {
                    runtime = { version = "Lua 5.1" },
                    diagnostics = {
                        globals = { "bit", "vim", "it", "describe", "before_each", "after_each" },
                    },
                },
            },
        })

        vim.lsp.config("rust_analyzer", {
            settings = {
                ["rust-analyzer"] = {
                    diagnostics = {
                        enable = true,
                        disabled = { "unresolved-proc-macro" },
                        enableExperimental = true,
                    },
                },
            },
        })

        -- mason-lspconfig v2: installs listed servers and, with
        -- automatic_enable = true (the default), calls vim.lsp.enable()
        -- for each installed server, picking up the vim.lsp.config above.
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

        local cmp_select = { behavior = cmp.SelectBehavior.Select }

        cmp.setup({
            snippet = {
                expand = function(args)
                    require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
                end,
            },
            mapping = cmp.mapping.preset.insert({
                ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
                ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
                ['<C-y>'] = cmp.mapping.confirm({ select = true }),
                ["<C-Space>"] = cmp.mapping.complete(),
            }),
            sources = cmp.config.sources({
                { name = 'nvim_lsp' },
                { name = 'luasnip' },
            }, {
                    { name = 'buffer' },
                })
        })

        -- Keymaps
        vim.api.nvim_set_keymap('n', '<leader>e', '<cmd>lua vim.diagnostic.open_float()<CR>', { noremap = true, silent = true })
        vim.api.nvim_set_keymap("n", "gD", "<cmd>lua vim.lsp.buf.type_definition()<CR>", { noremap = true, silent = true })
        vim.api.nvim_set_keymap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", { noremap = true, silent = true })
        vim.api.nvim_set_keymap("n", "<leader>gd", "<cmd>lua vim.lsp.buf.type_definition()<CR>", { noremap = true, silent = true })
        vim.api.nvim_set_keymap('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', { noremap = true, silent = true })

        -- Diagnostics UI
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
