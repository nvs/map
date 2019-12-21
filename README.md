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

**Map** is a collection of Warcraft III map management tools for [Lua].

[Lua]: https://www.lua.org

## Installation

**Map** can be run using [Lua] `>= 5.1` or [LuaJit] `>= 2.0`, so long as the
following dependencies are satisfied:

- [Lua] `>= 5.1` (for [luac])
- [LuaFileSystem] `>= 1.7.0`
- [Luacheck] `>= 0.23.0`
- [lua-stormlib] `>= 0.1.2`
- [bit32] `>= 5.3.0` (for Lua 5.1; and Lua 5.3 compiled without
  `LUA_COMPAT_BITLIB`)
- [compat-5.3] `>= 0.5` (for Lua 5.1; Lua 5.2; and LuaJIT)

All dependencies are available through LuaRocks:

```
luarocks install luafilesystem
luarocks install luacheck
luarocks install lua-stormlib
luarocks install bit32
luarocks install compat53
```

To make use of **Map** it is recommended to place it directly within your
project's root directory.  That is, as `project/map`.  This can be achieved
a number of ways, including cloning the repository or including it as Git
submodule.

_Other installation locations are neither tested or supported._

[luac]: https://www.lua.org/manual/5.3/luac.html
[LuaJIT]: https://luajit.org
[LuaFileSystem]: https://github.com/keplerproject/luafilesystem
[Luacheck]: https://github.com/mpeterv/luacheck
[lua-stormlib]: https://github.com/nvs/lua-stormlib
[bit32]: https://github.com/keplerproject/lua-compat-5.2
[compat-5.3]: https://github.com/keplerproject/lua-compat-5.3

## Caveats

1. **TL;DR: Your mileage may vary.**  This library has not been extensively
   tested under any environment other than Linux.  Please backup any files
   before use.
2. Only Lua is supported.  Sorry, no more Jass.
3. There are not many fancy errors.  Using the Lua stack traceback to assist
   in understanding issues is recommended.

## Commands

The following commands are provided by the collection:

- `check`: Check Lua scripts specified by the `script` settings table using
  [Luacheck].  If the `build` settings table is provided, then user build
  files will be processed.  If the `map` settings table is provided, then
  the input map is read and various map information is passed to the build
  environment.  Note that user build files are run before the Lua scripts
  are checked.

  A custom Luacheck standard representing the Lua environment in Warcraft
  III is provided, and used by defult, by **Map**.  See the following files:

  - [.luacheckrc](luacheck/luacheckrc)
  - [Warcraft III identifiers](luacheck/wc3.lua)

  Customization of one's Luacheck experience is supported, and encouraged.
  Simply consult the [Luacheck documentation], and then follow the example
  in the above `.luacheckrc` for how to include the custom Warcraft III
  standard.

[Luacheck documentation]: https://luacheck.readthedocs.io/en/stable

- `build`: Packages the `war3map.lua`.  Performs all actions specified in
  the `check` command.  Additionally, if the `map` settings table is
  provided, then a new map will be built.  Changes to information exposed
  within the build environment will be reflected within the built map.

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
    -- User build files will be processed if this table is present.
    build = {
        -- Values to be used as the `package.path` and `package.cpath`
        -- within user build files.  If absent, defaults to the paths used
        -- by Map.
        package = {
            path = table.concat ({
                'lib/?.lua',
                'lib/?/init.lua'
            }, ';'),

            cpath = table.concat ({
                'lib/?.so'
            }, ';')
        },

        -- The directory containing all user files that can be used to
        -- access and change the map environment.  It will be recursively
        -- traversed, and all Lua files within will be processed.
        --
        -- Note that when traversing directories, entries within are sorted
        -- using `table.sort ()`.  This should represent alphanumeric
        -- sorting.  This knowledge can be leveraged to ensure deterministic
        -- behavior.
        --
        -- If the build table is specified, this setting is required.
        directory = 'path/to/user/build/files'
    },

    -- An output map will be produced if this table is present.  In
    -- addition, various map information will be exposed to the user build
    -- environment.  If absent, the `build` command will only attempt to
    -- package the `war3map.lua`.
    map = {
        -- Path to the map file or directory that will be used as a basis
        -- for the built map.
        --
        -- If the map table is specified, this setting is required.
        input = 'path/to/input.w3x',

        -- The path to use when creating the output map.  Take care when
        -- specifying the path, as any file or directory at this specified
        -- location will be removed.
        --
        -- If the map table is specified, this setting is required.
        output = 'path/to/output.w3x',

        options = {
            -- Indicates that the output W3X archive should be directory
            -- based instead of MPQ based.  By default, this option is
            -- disabled.
            directory = false or nil or true
        }
    },

    -- This table is required.
    script = {
        -- Value to be used as the `package.path` when generating the
        -- script.  If absent, defaults to the `package.path` used for Map.
        package = {
            path = table.concat ({
                'lib/?.lua',
                'lib/?/init.lua'
            }, ';')
        },

        -- The path of the root file used to generate the script.
        --
        -- This setting is required.
        input = 'path/to/input.lua',

        -- The path to use when creating the output script.
        --
        -- This setting is required.
        output = 'path/to/output.lua',

        options = {
            -- Indicates whether to enable debug mode.  This will cause file
            -- names and line numbers in error messages to reflect the
            -- original locations.
            --
            -- By default, this option is disabled.  Listed are the accepted
            -- values for debug mode.  Note that 'name', the default mode
            -- should `true` be specified, will display the module's name.
            -- Setting the option to 'path' will display the file path.
            debug = false or nil or true or 'path' or 'name',

            -- Indicates whether to run Luacheck on the generated
            -- `war3map.lua`.  Enabling this option can speed up the build
            -- process, at the cost of what amounts to a sanity check.  By
            -- default, this option is disabled.
            skip_check = false or nil or true
        }
    }
}
```

With the above in mind, here is an example of the absolute minimum supported
configuration file.  This can be used to both check and build the
`war3map.lua`, and nothing else.

```lua
return {
    script = {
        input = 'path/to/input.lua',
        output = 'path/to/output.lua'
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
2. Only modules on the specified Lua path are supported.  By default, this
   is the `package.path` used by **Map**.  However, this can be adjusted
   using the proper setting.  Modules using C loaders are not supported.
3. Note that [luac] is used to identify uses of `require`, and the analysis
   performed is rather naive.  Any clever uses of `require` will probably
   be missed (i.e. anything that is not a literal `string` value).
4. Do not needlessly use `require`.  Any detected usages will cause those
   modules to be packaged into the `war3map.lua`, even if their code is not
   run.
5. All moules are checked using [Luacheck], and warnings will be issued if
   globals not included in the Warcraft III Lua environment are utilized.
   Resolving such issues, if desired, and adjusting the `.luacheckrc`
   accordingly, is left up to the user.

[`require`]: https://www.lua.org/manual/5.3/manual.html#pdf-require

## Environment

By specifying a `build` settings table, user build files will be processed.
If a `map` settings table is provided, then various map files can be loaded
on demand within the build environment.  The following map files are
supported via the specified keys:

- `information`: `war3map.w3i`
- `imports`: `war3map.imp`
- `objects`:
  - `war3map.w3a`
  - `war3map.w3b`
  - `war3map.w3d`
  - `war3map.w3h`
  - `war3map.w3q`
  - `war3map.w3t`
  - `war3map.w3u`
- `constants`:
  - `war3mapExtra.txt`
  - `war3mapMisc.txt`
  - `war3mapSkin.txt`
- `strings`: `war3map.wts`
- `regions`: `war3map.w3r`
- `cameras`: `war3map.w3c`
- `doodads`: `war3map.doo`
- `units`: `war3mapUnits.doo`
- `sounds`: `war3map.w3s`
- `terrain`: `war3map.w3e`
- `pathing`: `war3map.wpm`

Of particular note is that the presence of one of these keys in the build
environment will cause Map to process the data for that key, and then build
the associated files inot the map.  This process has higher precendence than
files being listed in the imports table, and any files produced in this
manner have priority.  To prevent this processing, set the value for a key
to `nil`.  For example:

```lua
local map = ...

-- Automatically loads `war3map.wts`, if found.
local strings = map.strings

-- Doing this clears the specified key from the build environment, thus
-- preventing Map from processing it and writing a new file.  Instead, the
-- status of the file will be pulled from the imports table.
map.strings = nil
```

### Settings

The entire settings table is provided as-is in a read-only fashion.

``` lua
local map = ...

print (map.settings.script.input) -- 'path/to/input.lua'
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
            [1] = 'Based on Evasion!'
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

When referencing imports, only `string` and `number` keys are supported,
with `string` ones being for individual files, and `number` ones for entire
directories.  Other key types are ignored.

``` lua
local map = ...

-- The file with this name will be copied from the input archive to the
-- output archive.  By default, all existing imports in the input archive
-- are listed in this fashion.
map.imports ['file.txt'] = true

-- Import the file specified by the provide path to the output archive using
-- the given name.
map.imports ['A/B/stuff.txt'] = 'path/to/imports/other.txt'

-- Clear an already specified import.
map.imports ['file.txt'] = nil

-- Import a directory's contents, preserving its structure.  Note that
-- `number` keys are iterated in ascending order, and do not need to be
-- contiguous.
map.imports [1] = 'path/to/directory'
map.imports [2] = 'path/to/another/directory'
```

### Strings

``` lua
local map = ...

print (map.strings [1]) --> `Force 1`
map.strings [2] = 'Just another Warcraft III map'
```

### Regions

```lua
local map = ...

print (map.regions [1].name) --> `Region 000`
map.regions [1].name = 'New Name'
```

### Cameras

```lua
local map = ...

print (map.cameras [1].name) --> `Camera ABC`
map.cameras [1].name = 'Camera XYZ'
```

### Doodads

```lua
local map = ...

print (map.doodads [1].type) --> `LTlt`
map.doodads [1].life = 50
```

### Units/Items

```lua
local map = ...

print (map.units [1].type) --> `hfoo`
map.units [1].player = 3
```

### Sounds

```lua
local map = ...

print (map.sounds [1].effect) --> `SpellsEAX`
map.sounds [1].volume = 10
```

### Terrain

```lua
local map = ...

map.terrain.tileset = 'A'

for _, row in ipairs (map.terrain.tiles) do
    for _, tile in ipairs (row) do
        print (tile.ground.texture) --> `0`
    end
end
```

### Pathing

```lua
local map = ...

for _, row in ipairs (map.pathing.cells) do
    for _, cell in ipairs (row) do
        print (cell.buildable) --> `false`
    end
end
```
