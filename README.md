# `xtxf`
[![CI](https://github.com/charlesrocket/xtxf/actions/workflows/ci.yml/badge.svg?branch=trunk)](https://github.com/charlesrocket/xtxf/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/charlesrocket/xtxf/branch/trunk/graph/badge.svg)](https://codecov.io/gh/charlesrocket/xtxf)

## Compilation

```sh
zig build
```

## Usage

```
          ██             ████
         ░██            ░██░
██   ██ ██████ ██   ██ ██████
 ██ ██░   ██░  ░██ ██   ░██
 ░███     ██     ███░    ██
 ██░██   ░██    ██ ██   ░██
██   ██   ██   ██  ░██   ██

Usage: xtxf [OPTIONS]

Example: xtxf -p -c=red -s=crypto

Options:
  -c, --color     Set color [default, red, green, blue, yellow, magenta]
  -s, --style     Set style [default, columns, crypto, grid, blocks]
  -t, --time      Set duration [loop, short]
  -p, --pulse     Pulse blocks
  -d, --decimal   Decimal mode
  -v, --version   Print version
  -h, --help      Print this message
```
