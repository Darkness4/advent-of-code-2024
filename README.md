# Advent of code 2024 in Zig

## Run

```shell
zig build <dayX>
# zig build day1
```

## Run with docker

```shell
zig() {
  docker run --rm -v $(pwd):/work -w /work ghcr.io/darkness4/aoc-2024:base "$@"
}
zig build <dayX>
```

## Benchmark results

```shell
benchmark              runs     total time     time/run (avg ± σ)     (min ... max)                p75        p99        p995
-----------------------------------------------------------------------------------------------------------------------------
day1 p1                4095     1.092s         266.722us ± 2.652us    (262.828us ... 335.847us)    268.128us  273.709us  275.742us
day1 p2                8191     1.104s         134.854us ± 5.209us    (131.389us ... 211us)        135.066us  160.264us  174.851us

day2 p1                16383    1.995s         121.798us ± 3.111us    (119.255us ... 192.315us)    121.711us  130.688us  135.316us
day2 p2                2047     1.773s         866.162us ± 14.705us   (859.028us ... 1.186ms)      865.129us  901.678us  947.806us

day3 p1                32767    1.648s         50.316us ± 1.344us     (49.023us ... 83.969us)      50.205us   54.474us   56.768us
day3 p2                32767    1.781s         54.372us ± 2.496us     (53.081us ... 110.369us)     54.123us   61.396us   67.628us

day4 p1                2047     1.365s         667.093us ± 6.265us    (649.571us ... 814.102us)    669.689us  684.397us  687.383us
day4 p2                8191     1.196s         146.06us ± 14.356us    (134.886us ... 237.731us)    142.63us   178.068us  179.249us

day5 p1                8191     1.691s         206.502us ± 2.481us    (201.942us ... 283.326us)    206.862us  213.604us  217.783us
day5 p2                1023     1.032s         1.009ms ± 28.27us      (993.072us ... 1.668ms)      1.008ms    1.073ms    1.158ms

day6 p1                5        435.355us      87.071us ± 3.151us     (84.951us ... 92.535us)      86.925us   92.535us   92.535us
day6 p1 [MEMORY]                               0B ± 0B                (0B ... 0B)                  0B         0B         0B
day6 p2                5        17.726s        3.545s ± 52.277ms      (3.496s ... 3.606s)          3.597s     3.606s     3.606s
day6 p2 [MEMORY]                               2.853MiB ± 0B          (2.853MiB ... 2.853MiB)      2.853MiB   2.853MiB   2.853MiB

day7 p1                4095     1.192s         291.219us ± 10.146us   (285.421us ... 538.922us)    291.703us  319.456us  330.798us
day7 p2                4095     1.733s         423.203us ± 6.764us    (416.941us ... 598.695us)    424.154us  444.453us  454.312us

day8 p1                8191     1.585s         193.54us ± 29.725us    (184.489us ... 579.838us)    190.08us   394.257us  409.716us
day8 p1 [MEMORY]                               18.070KiB ± 0B         (18.070KiB ... 18.070KiB)    18.070KiB  18.070KiB  18.070KiB
day8 p2                1023     1.885s         1.843ms ± 99.146us     (1.771ms ... 2.93ms)         1.855ms    2.204ms    2.716ms
day8 p2 [MEMORY]                               75.227KiB ± 0B         (75.227KiB ... 75.227KiB)    75.227KiB  75.227KiB  75.227KiB
```

## Compatibility

Tested on `0.14.0-dev.2367+aa7d13846`.
