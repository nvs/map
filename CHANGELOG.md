# Map Changelog

## [Unreleased]
### Added
- A '--version' option can be passed to commands to get the current map tools
  version number.
- Maps with the `.w3m` extension (RoC) are now supported.
- Limited support for the map header and 'war3map.w3i' file has been added to
  the 'prepare' command.
- The following configuration settings have been added:
    - `environment` _(For environment customization)_
    - `map.name` _(For header and w3i support in 'prepare')_
    - `output.name` _(Used in naming the output map and script)_

### Changed
- The 'check' command now displays parse results to 'stdout' regardless of the
  outcome. Note that other errors continue to write to 'stderr'.
- The 'prepare' command has been reworked, and will no longer be destructive
  by default. The '--force' flag can be used to overwrite an existing file.
- The 'imports' command now works upon a list of Lua files (like the 'objects'
  and 'constants' commands), rather than a single directory.
- The following settings are now used to list files (rather than using
  separate `directory` and `files` settings):
    - `patch`
    - `scripts`
    - `imports`
    - `objects`
    - `constants.gameplay`
    - `constants.interface`
- The following settings have been made optional (see
  [docs/configuration.md]):
    - `flags`
    - `flags.default` (`false`)
    - `map`
    - `map.name`
    - `scripts`
    - `imports`
    - `objects`
    - `constants`
    - `constants.gameplay`
    - `constants.interface`
    - `prefix`
    - `pjass`
    - `optimizer`
    - `optimizer.tweaks`

### Removed
- The following configuration settings have been removed:
    - `name` _(See `output.name` for replacement)_
    - `patch.directory`
    - `patch.files` _(See `patch` for replacement)_
    - `scripts.directory`
    - `scripts.files` _(See `scripts` for replacement)_
    - `objects.directory`
    - `objects.files` _(See `objects` for replacement)_
    - `constants.gameplay.directory`
    - `constants.gameplay.files` _(See `constants.gameplay` for replacement)_
    - `constants.interface.directory`
    - `constants.interface.files` _(See `constants.interface` for
      replacement)_

### Fixed
- Error display messages for missing or improperly typed configuration
  settings will display the full setting path.
- Consistency of commands writing to 'stderr' on errors has improved.

## [0.1.2] - 2017-02-07
### Fixed
- Ensure that commands write to 'stderr' on configuration file errors.
- Commands will properly display parse errors when encountered.
- The exit code was not being properly handled for executed shell commands on
  Lua 5.1 and LuaJIT.

## [0.1.1] - 2017-02-07
### Fixed
- Commands now validate the specified configuration table, and will no longer
  proceed unless validation is successful.

## 0.1.0 - 2017-02-06
### Added
- Initial release.

[Unreleased]: https://github.com/nvs/map/compare/v0.1.2...develop
[0.1.2]: https://github.com/nvs/map/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/nvs/map/compare/v0.1.0...v0.1.1
