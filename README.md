# Map

A collection of Warcraft 3 map management tools.

## Dependencies

This collection requires either [Lua](https://www.lua.org) 5.1, 5.2, 5.3, or
[LuaJIT](https://luajit.org) 2.0.

To use the `optimize` command, a valid [Wurst](https://wurstlang.org/)
installation is required.  By extension, this also means Java.

Additionally, a valid Warcraft 3 installation is necessary. This allows proper
access to the Warcraft 3 MPQ files (which are not included). You may want to
verify that the registry key `HKEY_CURRENT_USER\Software\Blizzard
Entertainment\Warcraft III\InstallPath` is set to the proper Warcraft 3
directory, or the provided tools may not function properly.

## Installation

To make use of this collection it is recommended to place it directly within
your project's root directory. That is, as `project/map`. This can be achieved
a number of ways, including cloning the repository or including it as a Git
submodule.

_Other installation locations are neither tested or supported._

## Windows Compatibility

_TL;DR: Your mileage may vary._

Some steps have been taken to provide Windows compatibility. However, no
actual testing has been done on a Windows system. As such, it is highly likely
that breakage will occur. Please report such behavior.

## Commands

The following commands are provided by the collection.

- `check` - Parse JASS scripts and validate their syntax.
- `build` - Combine JASS scripts into a single file.
- `prepare` - Prepare a new working map.
- `constants` - Load constant data into the working map.
- `objects` - Load object data into the working map.
- `imports` - Load imports into the working map.
- `optimize` - Create an optimized version of the working map.

All commands should be executed from within the project's root directory (e.g.
`map/check`). Depending on one's setup, it may be necessary to pass the
command to the Lua binary (e.g. `lua map/check`).

Each command expects a [configuration file](docs/configuration.md) as an
input parameter (e.g. `map/check configuration.lua`). Additionally, all
commands that make use of Lua files (i.e. 'constants' and 'objects') will have
access to [JASS globals meeting specific criteria](docs/globals.md).
