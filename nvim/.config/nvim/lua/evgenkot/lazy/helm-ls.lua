return {
    {
        "qvalentin/helm-ls.nvim",
        ft = "helm",
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
        },
        opts = {
            conceal_templates = {
                enabled = true,
            },
            indent_hints = {
                enabled = true,
                only_for_current_line = true,
            },
        },
    },
}
