return {
    "lervag/vimtex",
    ft = { "tex", "latex", "bib" },
    init = function()
        vim.g.vimtex_view_method = "zathura"
    end
}
