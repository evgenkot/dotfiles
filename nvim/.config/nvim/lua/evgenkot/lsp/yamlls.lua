return {
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
}
