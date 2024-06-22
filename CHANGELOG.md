# Changelog

All notable changes to this project will be documented in this file.

## [0.2.1] - 2024-06-22

### Bug Fixes

- Move terminal size check
- Use `process.Child`
- Add `core.allocator`
- Improve terminal size check

### Documentation

- Add coverage badge
- Update usage

### Miscellaneous tasks

- Ignore .zig-cache

### Operations

- Enable tests
- Generate test coverage
- Set zig version on coverage
- Add build summary
- Bump zig to 0.13.0
- Fix kcov integration
- Add codecov settings

### Refactor

- Drop `debug.print()`

### Testing

- Move `main`
- Fix stderr length
- Link libc
- Add `columns`
- Add `crypto`

### Build

- Set unit tests name
- Set test attributes
- Fix root source file

## [0.2.0] - 2024-06-18

### Bug Fixes

- Reformat help message
- Normalize frames
- Fix `core` memory leak
- Move `tb_init()`
- Check terminal size
- Update allowed terminal size
- Sections use `BoundedArrayAligned`

### Documentation

- Add example command

### Features

- Add `color` option
- Add `crypto` mode
- Add `time` option
- Add `Color.green`
- Use bold characters
- Add `columns` mode
- Add `pulse` option
- Add `Color.blue`
- Add `Color.yellow`
- Handle terminal resize

### Operations

- Fix release condition
- Set `cd` zig version

### Refactor

- `stateChange()` -> `setActive()`
- Add `FRAME`
- Drop redundant `core` variables

### Testing

- Add basic test
- Add string test
- Add array test
- Add nth value test
- Expand string test
- Add handler test
- Update handler test
- Add sections test
- Update array tests

## [0.1.0] - 2024-05-23

### Documentation

- Add README.md
- Add status badge
- Add help message

### Features

- Add `printCell()`
- Implement `rand`
- Implement key event
- Add `Core`
- Exit on all events
- Add `decimal` mode
- Improve help message

### Miscellaneous tasks

- Update gitignore
- Add LICENSE
- Add CHANGELOG

### Operations

- Add `ci` workflow
- Set zig version
- Add `cd` workflow
- Update build command
- Update `cd` workflow

### Performance

- Move rendering call

### Build

- Add `termbox2`
- Set `.paths`
- Drop termbox bindings
- Link `libc`


