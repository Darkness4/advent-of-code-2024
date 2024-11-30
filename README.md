# Advent of code 2024 in Zig

## Run

```shell
zig build <dayX>
# zig build day1
```

## Run with docker

```shell
zig() {
  docker run --rm -v $(pwd):/work -w /work ghcr.io/darkness4/aoc-2024:base zig "$@"
}
zig build <dayX>
```

## Compatibility

Tested on `0.14.0-dev.2367+aa7d13846`.
