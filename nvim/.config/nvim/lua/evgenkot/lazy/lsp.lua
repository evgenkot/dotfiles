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
            handlers = {
                function(server_name) -- default handler (optional)
                    require("lspconfig")[server_name].setup {
                        capabilities = capabilities
                    }
                end,

                ["helm_ls"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.helm_ls.setup {
                        capabilities = capabilities,
                        -- filetypes commonly used by helm-ls
                        filetypes = { "helm", "helmfile" },
                        settings = {
                            ["helm-ls"] = {
                                -- use yaml-language-server for richer YAML features (as recommended).
                                -- path may be "yaml-language-server" (if installed via npm) or the mason-installed binary.
                                yamlls = {
                                    enabled = true,
                                    -- path can be a string or array; change if your yaml-language-server binary is elsewhere
                                    path = "yaml-language-server",
                                    -- glob which files to enable the yamlls integration for
                                    enabledForFilesGlob = "*.{yaml,yml}",
                                    initTimeoutSeconds = 3,
                                    -- diagnostics control is optional; adjust as needed
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
                            }
                        },
                    }
                end,

                ["yamlls"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.yamlls.setup {
                        capabilities = capabilities,
                        -- limit yamlls attachment to plain yaml buffers (so helm templates with ft=helm don't get yamlls)
                        filetypes = { "yaml", "yml" },
                        settings = {
                            yaml = {
                                -- add schemas you want. This is an example mapping to the kubernetes schema for templates.
                                -- Extend these mappings with your project's schema URLs -> globs
                                schemas = {
                                    ["https://json.schemastore.org/chart.json"] = "Chart.yaml",
                                    -- e.g. ["https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/keda.sh/scaledobject_v1alpha1.json"] = "templates/**",
                                },
                                completion = true,
                                hover = true,
                            },
                        },


                    }
                end,



                ["lua_ls"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.lua_ls.setup {
                        capabilities = capabilities,
                        settings = {
                            Lua = {
                                runtime = { version = "Lua 5.1" },
                                diagnostics = {
                                    globals = { "bit", "vim", "it", "describe", "before_each", "after_each" },
                                }
                            }
                        }
                    }
                end,
                ["rust_analyzer"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.rust_analyzer.setup {
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
                    }
                end,
            }
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
                { name = 'luasnip' }, -- For luasnip users.
            }, {
                    { name = 'buffer' },
                })
        })

        vim.api.nvim_set_keymap('n', '<leader>e', '<cmd>lua vim.diagnostic.open_float()<CR>', { noremap = true, silent = true })
        vim.api.nvim_set_keymap("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", { noremap = true, silent = true })
        vim.api.nvim_set_keymap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", { noremap = true, silent = true })
        vim.api.nvim_set_keymap("n", "<leader>gd", "<cmd>lua vim.lsp.buf.type_definition()<CR>", { noremap = true, silent = true })
        vim.api.nvim_set_keymap('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', { noremap = true, silent = true })

        vim.diagnostic.config({
            -- update_in_insert = true,
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
