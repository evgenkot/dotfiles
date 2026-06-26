local jinja = require("evgenkot.jinja")

local ansible_role_dirs = {
    "defaults",
    "handlers",
    "meta",
    "tasks",
    "vars",
}

local ansible_project_dirs = {
    "group_vars",
    "host_vars",
    "inventories",
    "inventory",
    "playbooks",
}

local ansible_playbook_names = {
    ["playbook.yaml"] = true,
    ["playbook.yml"] = true,
    ["site.yaml"] = true,
    ["site.yml"] = true,
}

local function read_lines(path, count)
    local ok, lines = pcall(vim.fn.readfile, path, "", count)
    if ok then
        return lines
    end

    return {}
end

local function is_ansible_path(path)
    local normalized = path:gsub("\\", "/")
    local name = vim.fn.fnamemodify(normalized, ":t")
    if ansible_playbook_names[name] then
        return true
    end

    for _, dir in ipairs(ansible_role_dirs) do
        if normalized:match("/roles/[^/]+/" .. dir .. "/") then
            return true
        end
    end

    for _, dir in ipairs(ansible_project_dirs) do
        if normalized:match("/" .. dir .. "/") then
            return true
        end
    end

    return false
end

local function has_ansible_config(path)
    local dir = vim.fn.fnamemodify(path, ":p:h")
    return vim.fs.find("ansible.cfg", { path = dir, upward = true, type = "file" })[1] ~= nil
end

local function looks_like_ansible_playbook(path)
    local text = "\n" .. table.concat(read_lines(path, 80), "\n")
    if not text:match("\n%s*%-") then
        return false
    end

    return text:match("\n%s*hosts%s*:") ~= nil
end

local function yaml_filetype(path)
    if has_ansible_config(path) or is_ansible_path(path) or looks_like_ansible_playbook(path) then
        return "yaml.ansible"
    end

    return "yaml"
end

vim.filetype.add({
    extension = {
        j2 = function(path)
            return jinja.source_filetype(path)
        end,
        jinja = "jinja",
        jinja2 = "jinja",
        yaml = yaml_filetype,
        yml = yaml_filetype,
    },
})
