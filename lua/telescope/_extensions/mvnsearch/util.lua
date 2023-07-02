local actions = require("telescope.actions")
local state = require("telescope.actions.state")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local telescope_config = require("telescope.config").values
local telescope_utils = require("telescope.utils")
local entry_display = require("telescope.pickers.entry_display")

local curl = require('plenary.curl')
local xml2lua = require("xml2lua")
local xml_handler = require("xmlhandler.tree")

local config = require("telescope._extensions.mvnsearch.config")
local pagers = require("telescope._extensions.mvnsearch.pagers")
local inserters = require("telescope._extensions.mvnsearch.inserters")

local api_endpoint = "https://search.maven.org/solrsearch/select"

local function file_exists(filepath)
    local f = io.open(filepath)
    return f ~= nil and io.close(f)
end

local function parse_xml_response(xml)
    local maven_handler = xml_handler:new()
    local maven_parser = xml2lua.parser(maven_handler)
    maven_parser:parse(xml)
    local packages = {}
    for _, doc in pairs(maven_handler.root.response.result.doc) do
        local package = {}
        for _, str in pairs(doc.str) do
            package[str._attr.name] = str[1]
        end
        package[doc.long._attr.name] = tonumber(doc.long[1])
        package[doc.int._attr.name] = tonumber(doc.int[1])
        table.insert(packages, package)
    end
    return packages, tonumber(maven_handler.root.response.result._attr.numFound)
end

local function make_query(query, rows, start)
    start = start or 0
    local response = curl.get(api_endpoint, {
        query = {
            q = query,
            rows = tostring(rows),
            start = tostring(start),
            wt = "xml"
        },
    })
    if response.status ~= 200 then
        error("Request failed with status " .. response.status .. ": " .. response.body)
        return
    end
    return parse_xml_response(response.body)
end

local function make_query_async(query, rows, start, callback)
    start = start or 0
    curl.get(api_endpoint, {
        query = {
            q = query,
            rows = tostring(rows),
            start = tostring(start),
            wt = "xml"
        },
        callback = function(response)
            if response.status ~= 200 then
                error("Request failed with status " .. response.status .. ": " .. response.body)
                return
            end
            local packages, total = parse_xml_response(response.body)
            callback(packages, total)
        end
    })
end


local function maven_finder(packages)
    local displayer = entry_display.create {
        separator = " ",
        items = {
            { width = 48 },
            { width = 36 },
            { width = 20 },
            { remaining = true }
        }
    }
    return finders.new_table {
        results = packages,
        entry_maker = function(package)
            return {
                ordinal = package.id,
                display = function(entry)
                    return displayer {
                        entry.package.g,
                        entry.package.a,
                        entry.package.latestVersion,
                        entry.package.versionCount
                    }
                end,
                package = package
            }
        end
    }
end

local function maven_picker(opts, packages, total)
    return pickers.new(opts, {
        results_title = "Maven Central Search",
        sorter = telescope_config.generic_sorter(opts),
        finder = maven_finder(packages),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                config.default_action(prompt_bufnr, opts)
            end)
            for mode, mappings in pairs(config.mappings) do
                for mapping, action in pairs(mappings) do
                    map(mode, mapping, action)
                end
            end
            pagers.new(opts.query, opts.rows, total, prompt_bufnr)
            return true
        end,
    })
end

local function default_find_command()
    local cmd = nil
    if 1 == vim.fn.executable "rg" then
        cmd = { "rg", "--files", "--color", "never" }
        for filename, _ in pairs(inserters) do
            cmd[#cmd + 1] = "-g"
            cmd[#cmd + 1] = filename
        end
    elseif 1 == vim.fn.executable "fd" then
        cmd = {
            "fd",
            "--type",
            "f",
            "--color",
            "never",
            table.concat(vim.tbl_keys(inserters), "|")
        }
    elseif 1 == vim.fn.executable "find" and vim.fn.has "win32" == 0 then
        cmd = { "find", ".", "-type", "f", "-and", "(" }
        for filename, _ in pairs(inserters) do
            cmd[#cmd + 1] = "-name"
            cmd[#cmd + 1] = filename
            cmd[#cmd + 1] = "-or"
        end
        cmd[#cmd] = ")"
    end
    return cmd
end

local function build_script_picker(opts, package)
    local find_command = (function()
        if opts.find_command then
            if type(opts.find_command) == "function" then
                return opts.find_command(opts)
            end
            return opts.find_command
        end
    end)()

    if not find_command then
        telescope_utils.notify("mvnsearch.find_build_script", {
            msg = "You need to install either find, fd, rg or specify your own find command.",
            level = "ERROR",
        })
        return
    end

    return pickers.new(opts, {
        results_title = "Choose build script to insert to",
        sorter = telescope_config.file_sorter(opts),
        finder = finders.new_oneshot_job(find_command, opts),
        previewer = telescope_config.file_previewer(opts),
        attach_mappings = function (prompt_bufnr, map)
            actions.select_default:replace(function ()
                actions.close(prompt_bufnr)

                local filename = state.get_selected_entry()[1]
                local inserter = inserters[vim.fs.basename(filename)]
                if not inserter then
                    telescope_utils.notify("mvnsearch.insert_package", {
                        msg = "Inserter not found for " .. filename,
                        level = "ERROR",
                    })
                end
                inserter.insert(package, filename, opts)
            end)
            return true
        end
    })
end

return {
    file_exists = file_exists,
    make_query = make_query,
    make_query_async = make_query_async,
    maven_picker = maven_picker,
    maven_finder = maven_finder,
    default_find_command = default_find_command,
    build_script_picker = build_script_picker
}
