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

local function gradle_kotlin_dsl(package, opts)
    insert_into_gradle("build.gradle.kts", format_kotlin_dsl(package), opts)
end

local function format_groovy_dsl(package)
    return "implementation '" .. gradle_id(package) .. "'"
end

local function gradle_groovy_dsl(package, opts)
    insert_into_gradle("build.gradle", format_groovy_dsl(package), opts)
end

-- TODO: Maven support


return {
    groovy_gradle = {
        script_path = "build.gradle",
        insert = gradle_groovy_dsl,
        format = format_groovy_dsl
    },
    kotlin_gradle = {
        script_path = "build.gradle.kts",
        insert = gradle_kotlin_dsl,
        format = format_kotlin_dsl
    }
}
