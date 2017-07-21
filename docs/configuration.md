# Configuration

A configuration file is nothing more than a valid Lua file that returns a
`table` with the format specified below. It should be noted that this file
must reside in the project's root directory, and relative paths are specified
with this fact in mind.

The only valid types within the configuration file are `boolean`, `string`,
and `table`.  When listing files, please keep in mind that their order is
respected. All paths are specified using a `string`, and expect the use of
forward slashes (i.e. `/`) when indicating directory separators. And be sure
to include the file extension when specifying files.

## General Settings

### `map` _(`table`)_

- _Optional_

### `map.name` _(`string`)_

- _Optional_

The name of the map. Used by the 'prepare' command to update the map name in
the header of the map archive, as well as the `war3map.w3i` file.

### `map.author` _(`string`)_

- _Optional_

The author of the map. Used by the 'prepare' command to update the map author
within the `war3map.w3i` file.

### `map.description` _(`string`)_

- _Optional_

The map description. Used by the 'prepare' command to update the description
within the `war3map.w3i` file.

### `map.loading` _(`table`)_

- _Optional_

### `map.loading.title` _(`string`)_

- _Optional_

The first (smaller) line on the loading screen. Used by the 'prepare' command
to update the title within the `war3map.w3i` file.

### `map.loading.subtitle` _(`string`)_

- _Optional_

The second (larger) line on the loading screen. Used by the 'prepare' command
to update the subtitle within the `war3map.w3i`.

### `map.loading.text` _(`string`)_

- _Optional_

The description on the loading screen. Used by the 'prepare' command to update
the description within the `war3map.w3i`.

### `flags` _(`table`)_
### `flags.debug` _(`boolean`)_

- _Optional_
- _Default value: `false`_

Enables/disables [debugging](debugging.md). This flag indicates whether to
allow supported statements prefixed with the `debug` keyword to be built into
the map.

### `input` _(`table`)_
### `input.map` _(`string`)_

The path to the file that will be used as the basis for the working map. It
is assumed that this file has either a `.w3m` or `.w3x` extension.

### `output` _(`table`)_
### `output.directory` _(`string`)_

The path to the directory where the project work files will be placed.

### `output.name` _(`string`)_

The name used when creating the output map and script files.

### `environment` _(`table`)_

- _Optional_

The file list containing all Lua files to use during environment loading. Note
that these scripts can access the default environment (see `Map.initialize ()`
for details on the provided `table`). This is exposed in the following manner:

``` lua
local map = ...
```

It is possible, and intended, for users to be able to modify the environment
as they see fit. All this is done before any command is executed.

### `patch` _(`table`)_

The file list containing JASS scripts that are provided by Warcraft III
itself. Typically, these are the `common.j` and `blizzard.j`.

### `scripts` _(`table`)_

- _Optional_

The file list that represents the JASS portion of the project.

### `imports` _(`table`)_

- _Optional_

The file list containing all Lua files to use during importing.

### `objects` _(`table`)_

- _Optional_

The file list containing all Lua files to use during object loading.

### `constants` _(`table`)_

- _Optional_

### `constants.gameplay` _(`table`)_

- _Optional_

The file list containing all Lua files used when loading gameplay related
constants.

### `constants.interface` _(`table`)_

- _Optional_

The file list containing all Lua files used when loading interface related
constants.

## Command Settings

### `prefix` _(`string`)_

- _Optional_

A prefix to put before all commands. On Windows, this should probably be set
to an empty string (`''`). On other systems, the use of Wine will probably be
necessary, and the prefix should be adjusted accordingly.

### `pjass` _(`table`)_

- _Optional_

### `pjass.options` _(`table`)_

- _Optional_

A list of options to provide to pjass.

### `optimizer` _(`table`)_

- _Optional_

### `optimizer.tweaks` _(`string`)_

- _Optional_

The path to the optimizer tweaks file.
