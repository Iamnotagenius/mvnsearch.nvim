local xml2lua = require("xml2lua")
local handler = require("xmlhandler.tree")

local function gradle_id(package)
    return package.id .. ':' .. package.latestVersion
end

local function insert_into_gradle(filename, depstr, opts)
    vim.cmd("e! " .. filename)
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes(string.gsub(opts.gradle_macro, "{depstr}", depstr), true, false, true),
        'n', false)
end

local function format_kotlin_dsl(package)
    return 'implementation("' .. gradle_id(package) .. '")'
end

local function gradle_kotlin_dsl(package, filename, opts)
    insert_into_gradle(filename, format_kotlin_dsl(package), opts)
end

local function format_groovy_dsl(package)
    return "implementation '" .. gradle_id(package) .. "'"
end

local function gradle_groovy_dsl(package, filename, opts)
    insert_into_gradle(filename, format_groovy_dsl(package), opts)
end

local function format_maven(package)
    return xml2lua.toXml({
        groupId = package.g,
        artifactId = package.a,
        version = package.latestVersion
    }, "dependency")
end

local function maven(package, filename, opts)
    local mvnhandler = handler:new()
    xml2lua.parser(mvnhandler):parse(xml2lua.loadFile(filename))
    local project = mvnhandler.root.project
    if not project.dependencies or not project.dependencies.dependency then
        project.dependencies = { dependency = {} }
    end
    table.insert(project.dependencies.dependency, {
        groupId = package.g,
        artifactId = package.a,
        version = package.latestVersion
    })
    local decl_str = "<?xml"
    if type(opts.xml_declaration) == "function" then
        local result = opts.xml_declaration(filename)
        if type(result) == "string" then
            decl_str = decl_str .. result
        elseif type(result) == "table" then
            for key, value in pairs(opts.xml_declaration) do
                decl_str = decl_str .. ' ' .. string.format('%s="%s"', key, value)
            end
        end
    elseif type(opts.xml_declaration) == "table" then
        for key, value in pairs(opts.xml_declaration) do
            decl_str = decl_str .. ' ' .. string.format('%s="%s"', key, value)
        end
    elseif type(opts.xml_declaration) == "string" then
        decl_str = decl_str .. opts.xml_declaration
    end
    decl_str = decl_str .. "?>"

    local pom = io.open(filename, "w")
    if not pom then
        error("Cannot open " .. filename)
    end
    pom:write(decl_str .. '\n' .. xml2lua.toXml(mvnhandler.root))
    pom:close()
end

return {
    ["build.gradle"] = {
        insert = gradle_groovy_dsl,
        format = format_groovy_dsl
    },
     ["build.gradle.kts"] = {
        insert = gradle_kotlin_dsl,
        format = format_kotlin_dsl
    },
    ["pom.xml"] = {
        insert = maven,
        format = format_maven
    }
}
