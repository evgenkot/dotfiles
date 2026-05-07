local yaml_schemas = require("evgenkot.yaml-schemas")
yaml_schemas.setup()

return {
    filetypes = { "yaml", "yml" },
    settings = {
        yaml = {
            schemas = yaml_schemas.get_schemas(),
            completion = true,
            hover = true,
        },
    },
}
