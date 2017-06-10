# Map Changelog

## [Unreleased]
### Fixed
- An empty `settings.prefix` is now handled properly during environment load.
- Windows-centric issues:
    - Argument quoting when passing internally to `cmd.exe` has been improved.
    - Temporarily created paths now make use of the `TEMP` environment
      variable and should be usable.
- Address situation where Lua is built without `unpack` compatibility.

## [0.2.2] - 2017-03-30
### Fixed
- Debugging functionality has been restored.

## [0.2.1] - 2017-02-22
### Fixed
- Commands that failed before initialization a map environment would produce a
  Lua stack traceback.

## [0.2.0] - 2017-02-21
### Added
- A '--version' option can be passed to commands to get the current map tools
  version number.
- Maps with the `.w3m` extension (RoC) are now supported.
- Support for the map header and 'war3map.w3i' file has been added to the
  'prepare' command.
- A standardized map environment now exists for all commands. This map
  environment can be customized by the user using the `environment` setting.
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
  separate `directory` and `files` settings for each category):
    - `patch`
    - `scripts`
    - `imports`
    - `objects`
    - `constants.gameplay`
    - `constants.interface`
- The following settings have been made optional (meaning that they can be
  absent and the map tools should function properly):
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

[Unreleased]: https://github.com/nvs/map/compare/v0.2.2...develop
[0.2.2]: https://github.com/nvs/map/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/nvs/map/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/nvs/map/compare/v0.1.2...v0.2.0
[0.1.2]: https://github.com/nvs/map/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/nvs/map/compare/v0.1.0...v0.1.1
