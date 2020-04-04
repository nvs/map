# Map

## Contents

- [Overview](#overview)
- [Installation](#installation)
- [Caveats](#caveats)
- [Commands](#commands)
- [Configuration](#configuration)
- [Environment](#environment)

## Overview

**Map** is a collection of Warcraft III map management tools for [Lua].

[Lua]: https://www.lua.org

## Installation

The following dependencies must be met to utilize this library:

- [Lua] `>= 5.1` or [LuaJIT] `>= 2.0`
- [LuaFileSystem] `>= 1.7.0`
- [lua-stormlib] `= 0.1.6`
- [compat-5.3] `>= 0.5` (for Lua `< 5.3` or LuaJIT)
- [Wurst]

To make use of **Map** it is recommended to place it directly within your
project's root directory.  That is, as `project/map`.  This can be achieved
a number of ways, including cloning the repository or including it as Git
submodule.

_Other installation locations are neither tested or supported._

[LuaJIT]: https://luajit.org
[LuaFileSystem]: https://github.com/keplerproject/luafilesystem
[lua-stormlib]: https://github.com/nvs/lua-stormlib
[compat-5.3]: https://github.com/keplerproject/lua-compat-5.3
[Wurst]: https://wurstlang.org

## Caveats

1. **TL;DR: Your mileage may vary.**  This library has not been
   extensively tested under any environment other than Linux.  Please
   backup any files before use.

## Commands

The following commands are provided by the collection:

- `check`: Parse JASS scripts and validate their syntax.
- `build`: Builds the map, including but not limited to parsing and
  combining Jass scripts, inlining trigger strings, processing constants
  and objects, and importing files.
- `optimize`: Optimizes the map.  This will build both a non-optimized
  version as well as one that is optimized.  Currently, the only
  optimizations performed are done on the map script via [Wurst].

All commands should be executed from within the project's root directory
(e.g. `map/check`).  Depending on setup, it may be necessary to pass the
command to the Lua binary (e.g. `lua map/check`).

Each command expects a [configuration](#configuration) file as an input
parameter (e.g. `map/check configuration.lua`).

## Configuration

A configuration file is nothing more than a valid Lua file that returns a
`table` with the settings specified below.  The only valid types within the
configuration file are `boolean`, `string`, and `table`.  When listing
files and directories, please keep in mind that their order is respected.
It should be noted that a directory's tree will be walked, looking for
matching files.

Below is a sample configuration file.  Unless mentioned, a setting is
required.

``` lua
-- # Settings
return {

    -- Settings used to build the project's `war3map.j`.
    source = {
        -- This is the directory containing the project's source files.
        -- Typically, this will contain all Jass files to be parsed and
        -- combined.  Additionally, Wurst files should be found within.
        directory = 'path/to/project',

        -- Sometimes it is desired to have Jass files be located outside of
        -- the project's directory.  Include those paths here.  This is
        -- *optional*, and by default is empty.
        --
        -- This support only extends to Jass files, and as such other file
        -- types will not be considered.
        include = {
            'common.j',
            'blizzard.j',
            'path/to/some/other/project'
        }
    }

    -- The path to the map file that will be used as the basis for the
    -- working map.
    input = 'path/to/map.w3x',

    output = {
        -- The directories in which to place the generated output files.
        directories = {
            build = 'tmp',
            optimize = 'tmp/opt'
        },

        -- The name used when creating the output files.
        name = 'My Map.w3x'
    },

    -- A list of Lua files (files with the extension `.lua`) that can be
    -- used to access and change the map environment.  Directories can be
    -- specified as well, and will be recursively traversed.
    --
    -- Note that the ordering specified here is preserved.  However, when
    -- traversing directories, entries within are sorted using
    -- `table.sort ()`.  This should represent alphanumeric sorting.
    build = {
        'create-objects.lua',
        'path/to/some-directory',
        'list-imports.lua'
    },

    -- The command to invoke the Java executable.  This is *optional*, with
    -- the default specified below.
    java = 'java',

    -- Settings to be used with Wurst.  These are *optional*, with the
    -- defaults specified below.
    wurst = {
        -- The directory containing the Wurst installation.  Note that this
        -- value will be OS dependent.
        directory = '/home/user/.wurst',

        -- A list of directories to be placed in an automatically created
        -- `wurst.dependencies` file.  Relative paths will be appended to
        -- project's root directory.
        dependencies = {},

        -- Options to be passed to Wurst for script optimization.
        optimize = {
            '-opt',
            '-inline',
            '-localOptimizations'
        }
    }
}
```

## Environment

User build scripts (listed via `build` in configuration) are simply a
convenience provided to ease reading and writing of map data.  All libraries
provided by **Map**, as well as those that can be included via `require ()`,
are available.  Additionally, a user build script has the option to access
exposed map data via `...`.

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
please consult the source file for [W3I] handling.  For example:

``` lua
local map = ...

map.information.map.name = 'A Map'
````

[W3I]: https://github.com/nvs/map/blob/master/file/war3map/w3i.lua

### Header

All values present within the header of the map can be edited.  For details,
please consult the source file for [W3X] header handling.

``` lua
local map = ...

map.header.name = 'Another Map'
```

[W3X]: https://github.com/nvs/map/blob/master/file/w3x.lua

### Objects

Object modifications for all object types (i.e. abilities, destructables,
doodads, units, quests, items, and buffs) can be edited.  All object data
has been merged together.  This includes different object types, as well as
those that are considered 'original' and 'custom'.

An object has the following general format:

``` lua
local map = ...

map.objects ['A000'] = {
    -- General:
    type = 'ability', -- Indicates the type of object.  See below.
    base = 'ACfb' -- If present, implies a 'custom' object.

    -- Modifications:
    unam = {
        type = 'string',
        value = 'An Example'
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

print (#map.imports)

-- This will import the file and keep its existing name.
map.imports ['path/to/file.j'] = true

-- This will import the file and rename it.
map.imports ['path/to/other/file.j'] = 'war3map.j'

-- This will recurse through the files and subdirectories present within the
-- directory and import them into the map, preserving the directory
-- structure.
map.imports ['path/to/directory'] =  true
```

### Globals

All globals meeting specific criteria will be available within the user
build scripts.  This includes those present within both the `common.j` and
`blizzard.j`, as well as any within user provided scripts.  Do note that any
changes to these values on the Lua side will not be reflected within a built
map.

For example:

``` lua
local map = ...

for name, value in pairs (map.globals) do
    print (name, value)
end
```

The criteria for globals to be considered are as follows:

1. The global must be declared as constant.
2. The global must be one of the following types:
    - `boolean`
    - `string`
    - `real`
    - `integer`
3. The global must be assigned a literal value.

Examples of accepted globals:

``` jass
constant boolean BOOLEAN_A = true
constant boolean BOOLEAN_B = false

constant string STRING_A = ""
constant string STRING_B = "Hello, world!"

constant real REAL_A = 3.1415926
constant real REAL_B = .50
constant real REAL_C = 0.

constant integer INTEGER_A = 1234
constant integer INTEGER_B = 07
constant integer INTEGER_C = 0xAFF
constant integer INTEGER_D = $ABC1
constant integer INTEGER_E = 'A'
constant integer INTEGER_F = 'A000'
```

Examples of rejected globals:

``` jass
boolean BOOLEAN_C = true
constant boolean BOOLEAN_D = BOOLEAN_C
constant boolean BOOLEAN_E = true and false

constant string STRING_C = "Multiple" + " " + "Parts"
constant string STRING_D = STRING_B + " And you too!"

constant real_C = REAL_A * 5.00
constant real_D = globals.bj_PI

integer INTEGER_G = 1
constant integer_H = 5 + 5 + INTEGER_A
```

Both the name of the global as well as its contents are exposed, and an
attempt is made to translate Jass types to their Lua equivalents.  However,
this sometimes breaks down as Lua only has `number`, whereas Jass presents
both `integer` and `real` types.
