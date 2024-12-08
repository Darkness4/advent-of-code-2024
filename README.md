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

day4 p1                2047     1.359s         664.178us ± 26.898us   (642.377us ... 1.121ms)      663.056us  776.09us   833.7us
day4 p2                8191     1.183s         144.548us ± 10.66us    (139.675us ... 312.973us)    143.112us  194.288us  237.32us

day5 p1                8191     1.674s         204.379us ± 9.73us     (198.907us ... 343.531us)    204.527us  244.083us  283.757us
day5 p2                2047     1.981s         967.909us ± 39.164us   (941.984us ... 1.717ms)      966.121us  1.145ms    1.199ms

day6 p1                5        464.22us       92.844us ± 8.091us     (88.157us ... 107.213us)     90.692us   107.213us  107.213us
day6 p1 [MEMORY]                               0B ± 0B                (0B ... 0B)                  0B         0B         0B
day6 p2                5        17.277s        3.455s ± 27.297ms      (3.43s ... 3.485s)           3.484s     3.485s     3.485s
day6 p2 [MEMORY]                               2.853MiB ± 0B          (2.853MiB ... 2.853MiB)      2.853MiB   2.853MiB   2.853MiB

day7 p1                4095     1.221s         298.185us ± 6.122us    (290.16us ... 399.226us)     299.317us  321.539us  331.178us
day7 p2                4095     1.73s          422.558us ± 12.669us   (413.874us ... 631.617us)    422.941us  480.7us    515.216us

day8 p1                8191     1.585s         193.54us ± 29.725us    (184.489us ... 579.838us)    190.08us   394.257us  409.716us
day8 p1 [MEMORY]                               18.070KiB ± 0B         (18.070KiB ... 18.070KiB)    18.070KiB  18.070KiB  18.070KiB
day8 p2                1023     1.885s         1.843ms ± 99.146us     (1.771ms ... 2.93ms)         1.855ms    2.204ms    2.716ms
day8 p2 [MEMORY]                               75.227KiB ± 0B         (75.227KiB ... 75.227KiB)    75.227KiB  75.227KiB  75.227KiB
```

## Compatibility

Tested on `0.14.0-dev.2367+aa7d13846`.
