# Map Changelog

## [Unreleased]
### Added
- Introduce ability to set the `package.cpath` for user build files.
- Added setting to disable user build files.
- Added two additional Luacheck standards: one that covers only the modified
  WC3 Lua environment; and another that has all WC3 specific globals.
- Added support for the following files:
    - `war3map.doo`
    - `war3map.w3c`
    - `war3map.w3e`
    - `war3map.w3r`
    - `war3map.w3s`
    - `war3map.wpm`
    - `war3mapUnits.doo`

### Fixed
- Improve trigger string handling of nested brackets.
- Expose `package` table to required modules in script debug mode.
- Errors emitted by `luac` are no longer displayed.
- The `map.output` setting is now used when adding the script to the map.
- Extract now works for W3X.

### Changed
- Configuration of package paths has changed.
- Files exposed to the build environment are now loaded on demand.
- A `--quiet` flag is no longer passed to Luacheck, thus allowing the user
  to configure this option in their `.luacheckrc`.
- Default script debug mode changed to `name`.
- User build files are now processed before checking Lua scripts.
- The option to skip running Luacheck has been extended.
- W3I support has been enchanced:
  - Unknown flags have been identified and added.
  - Some field names have changed.
- The `script` settings table is now optional.

## [0.8.1] - 2019-11-21
### Fixed
- Object handling (that broke in 0.8.0) is restored.

## [0.8.0] - 2019-11-20
### Added
- Support for W3I changes in 1.32.
- Trigger strings have been exposed to the build environment.
- Option to skip running Luacheck on the generated `war3map.lua`.
- Support for directory based W3X archives.  For inputs, this support will
  be automatically handled.  For outputs, an option flag must be set.

### Changed
- Various performance improvements.
- For the W3I table, `type` has been renamed to `format`.
- Update WC3 ids for 1.32.0.
- IMP handling has been enhanced. The byte present before file paths is now
  exposed, and defaults to the value used in 1.32.0 (i.e. `0x1D`).
- W3X import handling has been enhanced, and is aware of WE ignored files.
- The build task now uses the W3I format to determine the proper IMP byte to
  use for imports.
- The configuration file format has changed extensively. See the
  [README](README.md) for details.

### Fixed
- Properly unpack unit tables in W3I file.
- Whitespace is properly handled in trigger strings.
- The first trigger string will not be skipped.

### Removed
- Inlining of strings has been removed.
- Support for W3O files has been removed.

## [0.7.2] - 2019-08-09
### Changed
- Update WC3 ids for 1.31.0 and 1.31.1.

### Fixed
- Allow processing of object modifications that have ids that are not four
  characters in length.

## [0.7.1] - 2019-05-03
### Fixed
- Properly handle `package.path` with `input.source.directory.`

## [0.7.0] - 2019-04-30
### Added
- Lua support.  This introduces new dependencies: `luac` (part of Lua) and
  Luacheck.
- A Luacheck Warcraft III standard has been introduced.

### Changed
- The `check` command now leverages Luacheck.  By default, a luacheckrc
  provided by Map is used.  A user can provide their own as well.
- The `build` command now functions conditionally, according to settings in
  the configuration file.  Luacheck is used here as well.
- The configuration file has changed extensively.  See the
  [README](README.md) for details.  Of particular note is that some settings
  are now optional by default.

### Removed
- Jass support has been removed completely.
- Support for maps built against patch versions earlier than 1.31 has been
  removed.  This is a result of only supporting Lua.

## [0.6.5] - 2019-04-28
### Fixed
- Ensure that a WTS file is always written. This addresses an
  incompatibility introduced with built maps and 1.31 PTR.

## [0.6.4] - 2019-03-27
### Fixed
- Fix Wurst complaining about empty lines present in `wurst.dependencies`.
- Fix Wurst being unable to find packages due to a missing
  `wurst.dependencies` when using the `build` and `optimize` commands.

## [0.6.3] - 2019-03-27
### Added
- Automatically handle the following Wurst related paths:
  - `wurst`
  - `wurst.dependencies`

## [0.6.2] - 2019-03-02
### Added
- Merge Wurst generated objects, if they exist.

## [0.6.1] - 2019-02-13
### Added
- Sort Jass files according to dependencies within globals blocks.

## [0.6.0] - 2019-02-12
### Changed
- Directories listed in `build` now have their entries sorted
  alphanumerically, rather than the LFS default.
- Constant literal globals are now considered from multiple globals blocks
  within a single file.
- An `output.directories` table has been added that allows specifying the
  location to place built maps for the `build` and `optimize` commands.

### Fixed
- Maps lacking a trigger strings file will no longer raise an error.
- Properly identify constant literal strings.

### Removed
- The `output.directory` setting has been removed.

## [0.5.0] - 2018-09-27
### Changed
- The `source` setting has been added.  It includes a way to specify the
  project's `directory`, as well as a means to `include` Jass files that
  exist outside the project.

### Removed
- The `scripts` setting has been removed.

## [0.4.0] - 2018-07-30
### Changed
- Configuration settings that take a list of files now support directories
  as well.  The entire directory tree will be walked.
- Wurst is now used to check and build the `war3map.j`.

### Removed
- PJass is no longer supported.
- The `patch` setting has been removed.

### Fixed
- `Path.extension ()` properly finds the last dot in a path.

## [0.3.1] - 2018-07-23
### Fixed
- Ensure that only sections are written in `*.ini` files.
- Objects definitions can now be passed via reference.

## [0.3.0] - 2018-07-22
### Changed
- Environment functionality has been enhanced and has changed drastically.
- Performance when building a map has improved.
- The `build` command now encompases the functionality of the removed
  commands (e.g. processing constants and objects and importing files).
- The `build` command will now inline trigger strings in Jass scripts,
  object definitions, and constants.
- A PJass check is now performed on the optimized script.
- Configuration settings have changed.

### Removed
- The following commands have been removed:
  - `prepare`
  - `objects`
  - `constants`
  - `imports`
- MPQEditor is no longer supported or included.
- The Grim Extension Pack is no longer supported or included.
- Functionality regarding the `debug` keyword is no longer supported.

## [0.2.4] - 2018-04-11
### Added
- Luacheck is now used to perform linting and code analysis.

### Changed
- Wurst supported has been added for optimizing scripts.

### Removed
- Support for Vexorian's Optimizer has been removed.

## [0.2.3] - 2017-06-09
### Changed
- When querying a command's version, the individual command is no longer
  mentioned (e.g. `map 0.2.3`).

### Fixed
- An empty `settings.prefix` is now handled properly during environment load.
- Windows-centric issues:
    - Can now handle the use of either forward or back slashes when
      specifying the command (e.g. `lua map/imports`).
    - Argument quoting when passing internally to `cmd.exe` has been
      improved.
    - Temporarily created paths now make use of the `TEMP` environment
      variable and should be usable.
- Address situation where Lua is built without `unpack` compatibility.

## [0.2.2] - 2017-03-30
### Fixed
- Debugging functionality has been restored.

## [0.2.1] - 2017-02-22
### Fixed
- Commands that failed before initialization of a map environment would
  produce a Lua stack traceback.

## [0.2.0] - 2017-02-21
### Added
- A '--version' option can be passed to commands to get the current map tools
  version number.
- Maps with the `.w3m` extension (RoC) are now supported.
- Support for the map header and 'war3map.w3i' file has been added to the
  'prepare' command.
- A standardized map environment now exists for all commands. This map
  environment can be customized by the user using the `environment` setting.

### Changed
- The 'check' command now displays parse results to 'stdout' regardless of
  the outcome. Note that other errors continue to write to 'stderr'.
- The 'prepare' command has been reworked, and will no longer be destructive
  by default. The '--force' flag can be used to overwrite an existing file.
- The 'imports' command now works upon a list of Lua files (like the
  'objects' and 'constants' commands), rather than a single directory.
- The configuration file format has changed extensively. See the
  [README](README.md) for details.

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

## [0.1.0] - 2017-02-06
### Added
- Initial release.

[Unreleased]: https://github.com/nvs/map/compare/v0.8.1...master
[0.8.1]: https://github.com/nvs/map/compare/v0.8.0...v0.8.1
[0.8.0]: https://github.com/nvs/map/compare/v0.7.2...v0.8.0
[0.7.2]: https://github.com/nvs/map/compare/v0.7.1...v0.7.2
[0.7.1]: https://github.com/nvs/map/compare/v0.7.0...v0.7.1
[0.7.0]: https://github.com/nvs/map/compare/v0.6.5...v0.7.0
[0.6.5]: https://github.com/nvs/map/compare/v0.6.4...v0.6.5
[0.6.4]: https://github.com/nvs/map/compare/v0.6.3...v0.6.4
[0.6.3]: https://github.com/nvs/map/compare/v0.6.2...v0.6.3
[0.6.2]: https://github.com/nvs/map/compare/v0.6.1...v0.6.2
[0.6.1]: https://github.com/nvs/map/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/nvs/map/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/nvs/map/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/nvs/map/compare/v0.3.1...v0.4.0
[0.3.1]: https://github.com/nvs/map/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/nvs/map/compare/v0.2.4...v0.3.0
[0.2.4]: https://github.com/nvs/map/compare/v0.2.3...v0.2.4
[0.2.3]: https://github.com/nvs/map/compare/v0.2.2...v0.2.3
[0.2.2]: https://github.com/nvs/map/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/nvs/map/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/nvs/map/compare/v0.1.2...v0.2.0
[0.1.2]: https://github.com/nvs/map/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/nvs/map/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/nvs/map/releases/tag/v0.1.0
