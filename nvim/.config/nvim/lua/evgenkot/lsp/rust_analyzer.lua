return {
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
