local yaml_schemas = require("evgenkot.yaml-schemas")
yaml_schemas.setup()

return {
    filetypes = { "yaml", "yml", "yaml.ansible" },
    get_language_id = function()
        return "yaml"
    end,
    settings = {
        yaml = {
            schemas = yaml_schemas.get_schemas(),
            -- Local-only schema setup: don't let yamlls fetch the online
            -- SchemaStore catalog (fails/errors when offline).
            schemaStore = {
                enable = false,
                url = "",
            },
            completion = true,
            hover = true,
        },
    },
}
