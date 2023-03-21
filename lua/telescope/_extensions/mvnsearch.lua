local telescope = require("telescope")
local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values
local entry_display = require("telescope.pickers.entry_display")

local http_request = require("http.request")
local http_util = require("http.util")
local xml2lua = require("xml2lua")
local xml_handler = require("xmlhandler.tree")

local config = require("telescope._extensions.mvnsearch.config")
local mvnsearch_actions = require("telescope._extensions.mvnsearch.actions")

local api_endpoint = "https://search.maven.org/solrsearch/select"

local function make_query(query)
    local url = api_endpoint .. '?' .. http_util.dict_to_query {
        q = query,
        rows = "200",
        wt = "xml"
    }
    local headers, stream = assert(http_request.new_from_uri(url):go())
    local xml = assert(stream:get_body_as_string())
    if headers:get(":status") ~= "200" then
        error(string.format("Not ok response: %s", xml))
    end
    local maven_handler = xml_handler:new()
    local maven_parser = xml2lua.parser(maven_handler)
    local packages = {}
    maven_parser:parse(xml)
    for _, doc in pairs(maven_handler.root.response.result.doc) do
        local package = {}
        for _, str in pairs(doc.str) do
            package[str._attr.name] = str[1]
        end
        package[doc.long._attr.name] = tonumber(doc.long[1])
        package[doc.int._attr.name] = tonumber(doc.int[1])
        table.insert(packages, package)
    end
    return packages
end

local function mvnsearch(opts)
    for key, value in pairs(config) do
        if not opts[key] then
            opts[key] = value
        end
    end

    if not opts.query then
        print("Options must have 'query' key")
    end
    local displayer = entry_display.create({
        separator = " ",
        items = {
            { width = 48 },
            { width = 36 },
            { width = 20 },
            { remaining = true }
        }
    })

    pickers.new(opts, {
        results_title = "Maven Central Search: " .. opts.query,
        sorter = conf.generic_sorter(opts),
        finder = finders.new_table {
            results = make_query(opts.query),
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
        },
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                opts.default_action(prompt_bufnr)
            end)
            for mode, mappings in pairs(config.mappings) do
                for mapping, action in pairs(mappings) do
                    map(mode, mapping, action)
                end
            end
            return true
        end
    }):find()
end

vim.api.nvim_create_user_command("MvnSearch", function(context)
    mvnsearch {
        query = context.fargs[1],
        action = config.action,
        gradle_macro = config.gradle_macro,
        yank_register = config.yank_register,
        preferred_build_system = config.preferred_build_system
    }
end, { nargs = 1 })


return telescope.register_extension {
    setup = function(opts)
        config.setup {
            default_action = mvnsearch_actions.insert_to_build_script,
            mappings = {
                n = {
                    y = mvnsearch_actions.yank,
                },
                i = {
                }
            }
        }
        config.setup(opts)
    end,
    exports = {
        mvnsearch = mvnsearch
    }
}
