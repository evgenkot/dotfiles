local parsers = {
    "vim",
    "vimdoc",
    "query",
    "javascript",
    "typescript",
    "tsx",
    "html",
    "css",
    "c",
    "cpp",
    "c_sharp",
    "java",
    "jinja",
    "jinja_inline",
    "lua",
    "luadoc",
    "rust",
    "jsdoc",
    "bash",
    "python",
    "go",
    "gomod",
    "gosum",
    "gowork",
    "gotmpl",
    "helm",
    "yaml",
    "vrl",
    "markdown",
    "markdown_inline",
    "templ",
}

return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = function()
        require("nvim-treesitter").install(parsers):wait(300000)
    end,
    config = function()
        local treesitter = require("nvim-treesitter")

        treesitter.setup()

        local installed = {}
        for _, parser in ipairs(treesitter.get_installed()) do
            installed[parser] = true
        end

        local missing = {}
        for _, parser in ipairs(parsers) do
            if not installed[parser] then
                table.insert(missing, parser)
            end
        end

        if #missing > 0 then
            treesitter.install(missing)
        end

        local enabled = {}
        for _, parser in ipairs(parsers) do
            enabled[parser] = true
        end

        vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("evgenkot_treesitter", { clear = true }),
            callback = function(args)
                local filetype = vim.bo[args.buf].filetype
                local parser = vim.treesitter.language.get_lang(filetype) or filetype

                if not enabled[parser] then
                    return
                end

                pcall(vim.treesitter.start, args.buf, parser)
                vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end,
        })
    end
}
