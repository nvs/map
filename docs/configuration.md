# Configuration

A configuration file is nothing more than a valid Lua file that returns a
`table` with the format specified below. It should be noted that this file
must reside in the project's root directory, and relative paths are specified
with this fact in mind.

The only valid types within the configuration file are `boolean`, `string`,
and `table`.  When listing files, please keep in mind that their order is
respected. All paths are specified using a `string`, and expect the use of
forwardslashes (i.e. `/`) when indicating directory separators. And be sure to
include the file extension when specifying files.

## Settings

All settings are required to exist, and behavior is not tested for situations
where they are absent. If it is desired to remove or clear a setting, use an
empty string (`''`) and/or an empty table (`{}`). Flags (i.e. `boolean`
values) must be set to either `true` or `false`.

### General Settings

#### `name` _(`string`)_

The name of the project, and the name used when referencing and working with
numerous files throughout the project.

#### `flags` _(`table`)_
#### `flags.debug` _(`boolean`)_

Enables/disables [debugging] (debugging.md). This flag indicates whether to
allow supported statements prefixed with the `debug` keyword to be built into
the map.

[debugging]: debugging.md

#### `input` _(`table`)_
#### `input.map` _(`string`)_

The path to the file that will be used as the basis for the working map. It
is assumed that this file has either a `.w3m` or `.w3x` extension.

#### `output` _(`table`)_
#### `output.directory` _(`string`)_

The path to the directory where the project work files will be placed.

#### `patch` _(`table`)_
#### `patch.directory` _(`string`)_

The path to the directory that contains the files 'common.j' and 'blizzard.j'.

### `patch.files` _(`table`)_

The file list containing JASS scripts that are provided by Warcraft 3 itself.
Typically, these are the 'common.j' and 'blizzard.j'.

#### `scripts` _(`table`)_
#### `scripts.directory` _(`string`)_

The path to the directory that contains the project's JASS scripts.

#### `scripts.files` _(`table`)_

The file list that represents the JASS portion of the project.

#### `imports` _(`table`)_
#### `imports.directory` _(`string`)_

The path to the directory that contains all files to be imported into the
working map. Note that subdirectory structure is preserved during the import
process.

#### `objects` _(`table`)_
#### `objects.directory` _(`string`)_

The path to the directory containing files used during object loading.

#### `objects.files` _(`table`)_

The file list containing all Lua files to use during object loading.

#### `constants` _(`table`)_
#### `constants.gameplay` _(`table`)_
#### `constants.gameplay.directory` _(`string`)_

The path to the directory containing files used when loading gameplay related
constants.

#### `constants.gameplay.files` _(`table`)_

The file list containing all Lua files used when loading gameplay related
constants.

#### `constants.interface` _(`table`)_
#### `constants.interface.directory` _(`string`)_

The path to the directory containing files used when loading interface related
constants.

#### `constants.interface.files` _(`table`)_

The file list containing all Lua files used when loading interface related
constants.

### Command Settings

#### `prefix` _(`string`)_

A prefix to put before all commands. On Windows, this should probably be set
to an empty string (`''`). On other systems, the use of Wine will probably be
necessary, and the prefix should be adjusted accordingly.

#### `pjass` _(`table`)_
#### `pjass.options` _(`table`)_

A list of options to provide to pjass.

#### `optimizer` _(`table`)_
#### `optimizer.tweaks` _(`string`)_

The path to the optimizer tweaks file.
