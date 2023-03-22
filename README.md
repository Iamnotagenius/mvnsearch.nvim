# mvnsearch.nvim
Convenient way to add dependencies to your Java/Kotlin project using Neovim with Telescope.

It uses REST API from [Maven Central Repository](https://central.sonatype.org/search/rest-api-guide)

## Dependencies
- **[Telescope](https://github.com/nvim-telescope/telescope.nvim)** - after all this is just another telescope extension
- **[xml2lua](https://github.com/manoelcampos/xml2lua)** - for parsing xml response 
- **[lua-http](https://github.com/daurnimator/lua-http)** - for making request

## Installation
Using [packer.nvim](https://github.com/wbthomason/packer.nvim):
```lua
use {
    'nvim-telescope/telescope.nvim',
    requires = {
        { 'nvim-lua/plenary.nvim' },
        {
            'Iamnotagenius/mvnsearch.nvim',
            rocks = {
                'http', 'xml2lua'
            }
        }
    },
}
```

## Usage
This extension provides `mvnsearch` picker and `:MvnSearch` command with query argument.
So you can use:
 - `:Telescope mvnsearch query=spring`
 - `:MvnSearch spring`

> Of course you also can use Telescope's api to call `mvnsearch` picker from lua.

### Features
You can:
 - search through packages
 - make new queries from prompt
 - yank dependecy strings...
 - ...or insert them directly to `gradle.build(.kts)`

Insertion works like this:
1. mvnsearch searches for build script in vim's cwd and determines how to format a package.
2. Inserts formatted package to build script (currently using macro).
3. If it does not find any build script, it fallbacks to yanking.

All mappings are described in [Configuration](#configuration)

> Queries are paginated, so if you didn't find desired package, try to go to next page

## Configuration
You can configure this extension just like other ones using `telescope.setup` (default configuration is used in this example):

```lua
local mvnsearch = telescope.extensions.mvnsearch

telescope.setup {
    -- ...
    extensions = {
        -- ...
        mvnsearch = {
            gradle_macro = '/dependencies<CR>$%O{depstr}<Esc>==:w<CR>', -- Macro for pasting dependecy string in build.gradle(.kts); {depstr} is replaced with dependecy string
            yank_register = 'd', -- Register for dependecy string to yank to
            preferred_build_system = mvnsearch.inserters.kotlin_gradle, -- Fallback format of dependecy string
            default_action = mvnsearch.actions.insert_to_build_script, -- Action on select_default
            mappings = {
                n = {
                    y = mvnsearch.actions.yank,
                    n = mvnsearch.actions.next_page,
                    p = mvnsearch.actions.prev_page,
                    o = mvnsearch.actions.insert_to_build_script
                },
                i = {
                    ['<C-y>'] = mvnsearch.actions.yank,
                    ['<C-n>'] = mvnsearch.actions.next_page,
                    ['<C-p>'] = mvnsearch.actions.prev_page,
                    ['<C-o>'] = mvnsearch.actions.insert_to_build_script,
                    ['<C-s>'] = mvnsearch.actions.new_query
                }
            }
            rows = 30, -- Items per page
        }
    }
}
```

## TODO
- [ ] Maven support
- [ ] Asynchronous requests
