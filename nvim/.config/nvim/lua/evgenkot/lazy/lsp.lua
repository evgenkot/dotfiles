return {
    "neovim/nvim-lspconfig",
    dependencies = {
        { "mason-org/mason.nvim", version = "^1.0.0" },
        { "mason-org/mason-lspconfig.nvim", version = "^1.0.0" },
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

        -- mason-lspconfig: list of servers to ensure installed and set up
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
        })

        -- Use setup_handlers to configure servers. Use vim.lsp.config and vim.lsp.enable
        require("mason-lspconfig").setup_handlers({
            -- default handler: configure with capabilities and enable
            function(server_name)
                vim.lsp.config(server_name, {
                    capabilities = capabilities,
                })
                vim.lsp.enable(server_name)
            end,

            ["helm_ls"] = function()
                vim.lsp.config("helm_ls", {
                    capabilities = capabilities,
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
                vim.lsp.enable("helm_ls")
            end,

            ["yamlls"] = function()
                vim.lsp.config("yamlls", {
                    capabilities = capabilities,
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
                vim.lsp.enable("yamlls")
            end,

            ["lua_ls"] = function()
                vim.lsp.config("lua_ls", {
                    capabilities = capabilities,
                    settings = {
                        Lua = {
                            runtime = { version = "Lua 5.1" },
                            diagnostics = {
                                globals = { "bit", "vim", "it", "describe", "before_each", "after_each" },
                            },
                        },
                    },
                })
                vim.lsp.enable("lua_ls")
            end,

            ["rust_analyzer"] = function()
                vim.lsp.config("rust_analyzer", {
                    capabilities = capabilities,
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
                vim.lsp.enable("rust_analyzer")
            end,
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

