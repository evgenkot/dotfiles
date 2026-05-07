return {
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
}
