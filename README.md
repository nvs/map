# Map

[![License](https://img.shields.io/github/license/nvs/map.svg)](LICENSE)

## Contents

- [Overview](#overview)
- [Installation](#installation)
- [Caveats](#caveats)
- [Commands](#commands)
- [Configuration](#configuration)
- [Coding with Map](#coding-with-map)
- [Environment](#environment)

## Overview

**Map** is a collection of Warcraft III map management tools for [Lua].  It

[Lua]: https://www.lua.org

## Installation

**Map** can be run using [Lua] `>= 5.1` or [LuaJit] `>= 2.0`, so long as the
following dependencies are satisfied:

- [Lua] `>= 5.1` (for `luac`)
- [LuaFileSystem] `>= 1.7.0`
- [Luacheck] `>= 0.23.0`
- [lua-stormlib]
- [compat-5.3] `>= 0.5` (for Lua `< 5.3` or LuaJIT)

To make use of **Map** it is recommended to place it directly within your
project's root directory.  That is, as `project/map`.  This can be achieved
a number of ways, including cloning the repository or including it as Git
submodule.

_Other installation locations are neither tested or supported._

[LuaJIT]: https://luajit.org
[LuaFileSystem]: https://github.com/keplerproject/luafilesystem
[Luacheck]: https://github.com/mpeterv/luacheck
[lua-stormlib]: https://github.com/nvs/lua-stormlib
[compat-5.3]: https://github.com/keplerproject/lua-compat-5.3

## Caveats

1. **TL;DR: Your mileage may vary.**  This library has not been
   extensively tested under any environment other than Linux.  Please
   backup any files before use.
2. Only Lua is supported, now that Jass support has been removed.

## Commands

The following commands are provided by the collection:

- `check`: Check Lua scripts using [Luacheck].  A custom Luacheck standard
  representing the Lua environment in Warcraft III is provided, and used by
  defult, by **Map**.  See the following files:

  - [.luacheckrc](luacheck/luacheckrc)
  - [Warcraft III globals](luacheck/wc3.lua)

  Customization of one's Luacheck experience is supported, and encouraged.
  Simply consult the [Luacheck documentation], and then follow the example
  in the above `.luacheckrc` for how to include the custom Warcraft III
  standard.

[Luacheck documentation]: https://luacheck.readthedocs.io/en/stable

- `build`: Packages the `war3map.lua`.  Depending on settings, may
  optionally build the map as well.  If the map is built, then trigger
  strings will be inlined within objects, and user build files that have
  access to an environment exposed by **Map** will be processed.  These can
  be used to import files, create and modify objects, adjust constants, and
  more.

All commands should be executed from within the project's root directory
(e.g. `map/check`).  Depending on setup, it may be necessary to pass the
command to the Lua binary (e.g. `lua map/check`).

Each command expects a [configuration](#configuration) file as an input
parameter (e.g. `map/check configuration.lua`).

## Configuration

A configuration file is nothing more than a valid Lua file that returns a
`table` with the settings specified below.  The only valid types within the
configuration file are `nil`, `boolean`, `string`, and `table`.

Below is a sample configuration file.  Unless mentioned, a setting is
optional.

``` lua
-- # Settings
return {
    input = {
        -- The path to the map file that will be used as a basis for the
        -- built map.  If absent, the `build` command will only attempt to
        -- package the `war3map.lua`.
        map = 'path/to/map.w3x',

        -- The directory containing all user files that can be used to
        -- access and change the map environment.  It will recursively
        -- traveresed, and all Lua files within will be processed.
        --
        -- Note that when traversing directories, entries within are sorted
        -- using `table.sort ()`.  This should represent alphanumeric
        -- sorting.  This knowledge can be leveraged to ensure deterministic
        -- behavior.
        --
        -- If not specified, then no user files will be processed.
        build = 'path/to/user/files',

        source = {
            -- The directory to add to end of the `package.path`.  This will
            -- then be utilized when searching for modules to include.  If
            -- root module already exists on the `package.path`, this can be
            -- omitted.
            directory = 'path/to/include',

            -- The name of the root module to `require`.  It must be on the
            -- `package.path`.  This is **REQUIRED**.
            require = 'name'
        }
    },

    -- All values in this table are **REQUIRED**.
    output = {
        -- The directory in which to place the generated output files.  This
        -- directory will be created automatically if it does not exist.
        directory = 'path/to/put/files',

        -- The name to use when creating the output map.  The `war3map.lua`
        -- be named identically, with a `.lua` extension added.
        name = 'My Map.w3x'
    },

    options = {
        -- Indicates whether to enable debug mode.  This will cause file
        -- names and line numbers in error messages to reflect the original
        -- locations.  This will require a bit of extra memory.
        --
        -- By default, this option is disabled.  Listed are the accepted
        -- values for debug mode.  Note that 'path', the default mode should
        -- `true` be specified, will display the file path.  Setting the
        -- option to 'name' will only display the module's name.
        debug = false or nil or true or 'path' or 'name'
    }
}
```

With the above in mind, here is an example of the absolute minimum supported
configuration file.  This will build the `war3map.lua`, and nothing else.

```lua
return {
    input = {
        source = {
            require = 'name'
        }
    },

    output = {
        directory = 'tmp',
        name = 'Map.w3x'
    }
}
```

## Coding with Map

A typical [Lua] workflow involves utilizing [`require`] to break up projects
into modules, as well as using it to include externally defined modules.  If
you already do this, then you do not need to adjust your habits beyond the
following stated limitations:

1. Warcraft III's Lua environment does not include `require`.  Nor does it
   have a concept of multiple files.  To overcome this, **Map** will provide
   the needed plumbing when packaging the `war3map.lua` to make `require`
   work as expected.
2. Only modules on the Lua path `package.path` are supported. Modules using
   C loaders on the `package.cpath` are not suppoted, and **Map** will
   complain.
3. Note that `luac` is used to identify uses of `require`, and the analysis
   performed is rather naive.  Any clever uses of `require` will probably
   be missed.  It is recommended to stick to literal `string` values (e.g.
   `require ('name')`).
4. Do not needlessly use `require`.  Any detected usages will cause those
   modules to be packaged into the `war3map.lua`, even if their code is not
   run.
5. All moules are checked using [Luacheck], and warnings will be issued if
   globals not included in the Warcraft III Lua environment are utilized.
   Resolving such issues, if desired, and adjusting the `.luacheckrc`
   accordingly, is left up to the user.

[`require`]: https://www.lua.org/manual/5.3/manual.html#pdf-require

## Environment

User build scripts (found within the directory specified by `input.build`)
are simply a convenience provided to ease reading and writing of map data.
All libraries provided by **Map**, as well as any on the `package.path`, can
be included.  Additionally, a user build script has the convenience of
accessing exposed map data (i.e. the environment) via `...`.

### Settings

The following settings can be modified from within a user build script:

``` lua
local map = ...

-- The directory in which to place the generated output files.
map.settings.output.directory = ''

-- The name used when creating the output files.
map.settings.output.name = ''
```

### Information

All values present within the `war3map.w3i` can be edited.  For details,
please consult the source file for [W3I](file/war3map/w3i.lua) handling.
For example:

``` lua
local map = ...

map.information.map.name = 'A Map'
````

### Objects

Object modifications for all object types (i.e. abilities, destructables,
doodads, units, upgrades, items, and buffs) can be edited.  All object data
has been merged together.  This includes different object types, as well as
those that are considered 'original' and 'custom'.

An object has the following general format:

``` lua
local map = ...

map.objects ['A000'] = {
    type = 'ability', -- Indicates the type of object.  See below.
    base = 'ACev' -- If present, implies a 'custom' object.

    -- Example of a modification that has no levels.
    anam = {
        type = 'string',
        value = 'An Example'
    },

    -- Example of a modification that has levels.
    atp1 = {
        type = 'string',
        values = {
            [1] = 'Based on Evaion!'
        }
    },

    -- Example of a modification that has 'custom' data.
    Eev1 = {
        data = 1,
        type = 'unreal',
        values = {
            [1] = 0
        }
    }
}
```

An object 'type' must be one of the following strings:

- `ability`
- `destructable`
- `doodad`
- `unit`
- `upgrade`
- `item`
- `buff`

A modification 'type' must be one of the following strings:

- `string`
- `integer`
- `real`
- `unreal`

### Constants

All constant file modifications present within the map can be edited.  Note
that only modifications will be exposed.  Default values will not be
available.  For example:

``` lua
local map = ...

print (map.constants.interface.FrameDef.LUMBER) --> `nil`
map.constants.interface.FrameDef.LUMBER = 'Not Lumber'
```

The following files are exposed:

- `war3mapSkin.txt`: `interface`
- `war3mapMisc.txt`: `gameplay`
- `war3mapExtra.txt`: `extra`

### Imports

``` lua
local map = ...

-- This will import the file and keep its existing name.
map.imports ['path/to/file.j'] = true

-- This will import the file and rename it.
map.imports ['path/to/other/file.j'] = 'war3map.j'

-- This will recurse through the files and subdirectories present within the
-- directory and import them into the map, preserving the directory
-- structure.
map.imports ['path/to/directory'] =  true
```
