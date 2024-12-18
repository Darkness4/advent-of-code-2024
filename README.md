# Advent of code 2024 in Zig

## Run

```shell
zig build <dayX>
# zig build day01
```

## Run with docker

```shell
zig() {
  docker run --ulimit=host --rm -v $(pwd):/work -w /work ghcr.io/darkness4/aoc-2024:base "$@"
}
zig build <dayX>
```

## Benchmark results

```shell
benchmark              runs     total time     time/run (avg ± σ)     (min ... max)                p75        p99        p995
-----------------------------------------------------------------------------------------------------------------------------
day01 p1                4095     1.092s         266.722us ± 2.652us    (262.828us ... 335.847us)    268.128us  273.709us  275.742us
day01 p2                8191     1.104s         134.854us ± 5.209us    (131.389us ... 211us)        135.066us  160.264us  174.851us

day02 p1                16383    1.995s         121.798us ± 3.111us    (119.255us ... 192.315us)    121.711us  130.688us  135.316us
day02 p2                2047     1.773s         866.162us ± 14.705us   (859.028us ... 1.186ms)      865.129us  901.678us  947.806us

day03 p1                32767    1.648s         50.316us ± 1.344us     (49.023us ... 83.969us)      50.205us   54.474us   56.768us
day03 p2                32767    1.781s         54.372us ± 2.496us     (53.081us ... 110.369us)     54.123us   61.396us   67.628us

day04 p1                2047     1.359s         664.178us ± 26.898us   (642.377us ... 1.121ms)      663.056us  776.09us   833.7us
day04 p2                8191     1.183s         144.548us ± 10.66us    (139.675us ... 312.973us)    143.112us  194.288us  237.32us

day05 p1                8191     1.609s         196.468us ± 8.94us     (187.084us ... 316.42us)     197.173us  238.342us  273.278us
day05 p2                1023     989.563ms      967.315us ± 11.878us   (946.173us ... 1.053ms)      968.656us  1.003ms    1.014ms

day06 p1                5        464.22us       92.844us ± 8.091us     (88.157us ... 107.213us)     90.692us   107.213us  107.213us
day06 p1 [MEMORY]                               0B ± 0B                (0B ... 0B)                  0B         0B         0B
day06 p2                5        17.277s        3.455s ± 27.297ms      (3.43s ... 3.485s)           3.484s     3.485s     3.485s
day06 p2 [MEMORY]                               2.853MiB ± 0B          (2.853MiB ... 2.853MiB)      2.853MiB   2.853MiB   2.853MiB

day07 p1                4095     1.221s         298.185us ± 6.122us    (290.16us ... 399.226us)     299.317us  321.539us  331.178us
day07 p2                4095     1.73s          422.558us ± 12.669us   (413.874us ... 631.617us)    422.941us  480.7us    515.216us

day08 p1                8191     1.585s         193.54us ± 29.725us    (184.489us ... 579.838us)    190.08us   394.257us  409.716us
day08 p1 [MEMORY]                               18.070KiB ± 0B         (18.070KiB ... 18.070KiB)    18.070KiB  18.070KiB  18.070KiB
day08 p2                1023     1.885s         1.843ms ± 99.146us     (1.771ms ... 2.93ms)         1.855ms    2.204ms    2.716ms
day08 p2 [MEMORY]                               75.227KiB ± 0B         (75.227KiB ... 75.227KiB)    75.227KiB  75.227KiB  75.227KiB

day09 p1                8191     5.993s         731.774us ± 10.771us   (719.884us ... 1.119ms)      732.929us  750.512us  762.314us
day09 p2                7        5.829s         832.723ms ± 3.468ms    (828.11ms ... 837.255ms)     835.11ms   837.255ms  837.255ms

day10 p1               1023     1.212s         1.185ms ± 29.057us     (1.15ms ... 1.72ms)          1.187ms    1.285ms    1.315ms
day10 p1 [MEMORY]                              1.641KiB ± 0B          (1.641KiB ... 1.641KiB)      1.641KiB   1.641KiB   1.641KiB
day10 p2               4095     1.91s          466.665us ± 17.689us   (447.758us ... 820.103us)    468.338us  521.558us  559.971us
day10 p2 [MEMORY]                              0B ± 0B                (0B ... 0B)                  0B         0B         0B

day11 p1               255      1.54s          6.039ms ± 159.548us    (5.921ms ... 8.073ms)        6.058ms    6.446ms    6.844ms
day11 p1 [MEMORY]                              0B ± 0B                (0B ... 0B)                  0B         0B         0B
day11 p2               31       1.909s         61.588ms ± 167.229us   (61.266ms ... 61.978ms)      61.688ms   61.978ms   61.978ms
day11 p2 [MEMORY]                              340.070KiB ± 0B        (340.070KiB ... 340.070KiB)  340.070KiB 340.070KiB 340.070KiB

day12 p1               63       1.668s         26.478ms ± 386.572us   (25.946ms ... 28.173ms)      26.718ms   28.173ms   28.173ms
day12 p1 [MEMORY]                              824.570KiB ± 0B        (824.570KiB ... 824.570KiB)  824.570KiB 824.570KiB 824.570KiB
day12 p2               31       1.417s         45.74ms ± 775.506us    (44.858ms ... 48.666ms)      45.967ms   48.666ms   48.666ms
day12 p2 [MEMORY]                              824.570KiB ± 0B        (824.570KiB ... 824.570KiB)  824.570KiB 824.570KiB 824.570KiB

day13 p1               16383    1.794s         109.517us ± 2.891us    (107.403us ... 167.156us)    109.026us  121.53us   124.966us
day13 p2               16383    1.824s         111.385us ± 4.556us    (108.846us ... 170.072us)    111.05us   134.956us  149.473us

day14 p1               16383    1.374s         83.894us ± 4.239us     (81.555us ... 133.833us)     83.187us   108.315us  109.237us
day14 p1 [MEMORY]                              0B ± 0B                (0B ... 0B)                  0B         0B         0B
day14 p2               7        1.395s         199.377ms ± 1.477ms    (198.108ms ... 201.938ms)    200.719ms  201.938ms  201.938ms
day14 p2 [MEMORY]                              10.159KiB ± 0B         (10.159KiB ... 10.159KiB)    10.159KiB  10.159KiB  10.159KiB

day15 p1               2047     1.343s         656.28us ± 107.246us   (506.64us ... 1.523ms)       745.273us  864.959us  878.986us
day15 p1 [MEMORY]                              0B ± 0B                (0B ... 0B)                  0B         0B         0B
day15 p2               1023     1.521s         1.487ms ± 240.066us    (1.148ms ... 2.513ms)        1.683ms    1.989ms    2.009ms
day15 p2 [MEMORY]                              0B ± 0B                (0B ... 0B)                  0B         0B         0B

day16 p1               31       1.72s          55.489ms ± 824.908us   (54.535ms ... 57.502ms)      56.176ms   57.502ms   57.502ms
day16 p1 [MEMORY]                              1.588MiB ± 0B          (1.588MiB ... 1.588MiB)      1.588MiB   1.588MiB   1.588MiB
day16 p2               3        1.028s         342.921ms ± 2.97ms     (339.649ms ... 345.45ms)     345.45ms   345.45ms   345.45ms
day16 p2 [MEMORY]                              1.640MiB ± 0B          (1.640MiB ... 1.640MiB)      1.640MiB   1.640MiB   1.640MiB

day17 p1               65535    60.376ms       921ns ± 68ns           (871ns ... 3.878us)          932ns      972ns      982ns
day17 p2               8191     1.526s         186.355us ± 3.343us    (174.501us ... 228.243us)    187.876us  193.476us  194.559us
```

## Compatibility

Tested on `0.14.0-dev.2367+aa7d13846`.
