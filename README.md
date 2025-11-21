# Advent of code 2024 in Zig

## Run

```shell
zig build <dayX>
# zig build day01
```

## Run with docker

```shell
zig() {
  docker run --ulimit=host --rm -it -v $(pwd):/work -w /work ghcr.io/darkness4/aoc-2024:base "$@"
}
zig build <dayX>
```

## Benchmark results

```shell
benchmark              runs     total time     time/run (avg ± σ)     (min ... max)                p75        p99        p995
-----------------------------------------------------------------------------------------------------------------------------
day01 p1               3446     2.034s         590.335us ± 20.331us  (571.814us ... 742.608us)    591.411us  652.888us  658.568us
day01 p2               7062     2.015s         285.347us ± 9.505us   (279.42us ... 400.88us)      286.954us  331.168us  364.151us

day02 p1               7190     1.984s         275.961us ± 3.193us   (272.296us ... 360.514us)    277.015us  285.551us  287.034us
day02 p2               1603     2.001s         1.248ms ± 14.008us    (1.227ms ... 1.558ms)        1.254ms    1.279ms    1.29ms

day03 p1               25410    1.976s         77.779us ± 2.002us    (76.255us ... 137.36us)      77.497us   86.474us   90us
day03 p2               25341    1.996s         78.783us ± 1.829us    (76.676us ... 138.683us)     78.669us   87.175us   89.57us

day04 p1               1697     1.987s         1.17ms ± 17.774us     (1.161ms ... 1.654ms)        1.171ms    1.213ms    1.232ms
day04 p2               7497     2.007s         267.787us ± 14.013us  (255.455us ... 451.987us)    268.84us   305.65us   328.643us

day05 p1               4907     1.997s         407.009us ± 3.204us   (401.491us ... 475.342us)    408.254us  417.982us  422.461us
day05 p2               2044     1.999s         978.103us ± 4.796us   (967.464us ... 1.034ms)      979.658us  996.028us  999.966us

day06 p1               5        957.145us      191.429us ± 82.654us  (149.534us ... 339.183us)    158.02us   339.183us  339.183us
day06 p1 [MEMORY]                              0B ± 0B               (0B ... 0B)                  0B         0B         0B
day06 p2               5        46.966s        9.393s ± 1.897s       (8.483s ... 12.787s)         8.576s     12.787s    12.787s
day06 p2 [MEMORY]                              2.853MiB ± 0B         (2.853MiB ... 2.853MiB)      2.853MiB   2.853MiB   2.853MiB

day07 p1               2762     2.044s         740.385us ± 17.274us  (727.108us ... 957.736us)    741.566us  801.31us   887.092us
day07 p2               2328     2.009s         863.08us ± 11.855us   (846.355us ... 939.151us)    865.381us  923.711us  930.134us

day08 p1               5261     2.01s          382.215us ± 21.867us  (365.994us ... 676.974us)    381.153us  492.644us  499.177us
day08 p1 [MEMORY]                              16.070KiB ± 0B        (16.070KiB ... 16.070KiB)    16.070KiB  16.070KiB  16.070KiB
day08 p2               717      1.985s         2.769ms ± 14.528us    (2.747ms ... 2.984ms)        2.773ms    2.806ms    2.83ms
day08 p2 [MEMORY]                              538.859KiB ± 0B       (538.859KiB ... 538.859KiB)  538.859KiB 538.859KiB 538.859KiB

day09 p1               12952    10.018s        773.543us ± 23.487us  (761.003us ... 1.41ms)       782.584us  801.701us  811.529us
day09 p2               13       9.382s         721.713ms ± 9.96ms    (714.686ms ... 744.481ms)    723.885ms  744.481ms  744.481ms

day10 p1               752      2.004s         2.665ms ± 9.326us     (2.646ms ... 2.793ms)        2.671ms    2.686ms    2.686ms
day10 p1 [MEMORY]                              1.641KiB ± 0B         (1.641KiB ... 1.641KiB)      1.641KiB   1.641KiB   1.641KiB
day10 p2               2710     2.033s         750.199us ± 21.029us  (734.913us ... 1.16ms)       749.691us  786.421us  889.957us
day10 p2 [MEMORY]                              0B ± 0B               (0B ... 0B)                  0B         0B         0B

day11 p1               209      1.977s         9.46ms ± 175.121us    (9.129ms ... 10.209ms)       9.514ms    10.024ms   10.053ms
day11 p1 [MEMORY]                              0B ± 0B               (0B ... 0B)                  0B         0B         0B
day11 p2               15       1.899s         126.653ms ± 1.677ms   (123.48ms ... 128.962ms)     127.591ms  128.962ms  128.962ms
day11 p2 [MEMORY]                              340.070KiB ± 0B       (340.070KiB ... 340.070KiB)  340.070KiB 340.070KiB 340.070KiB

day12 p1               35       1.994s         56.977ms ± 75.55us    (56.854ms ... 57.16ms)       57.041ms   57.16ms    57.16ms
day12 p2               23       1.968s         85.565ms ± 1.407ms    (83.602ms ... 89.54ms)       85.808ms   89.54ms    89.54ms
*NOTE: Memory tracking has been disabled for day12 due to a bug in zbench.*

day13 p1               7840     1.946s         248.332us ± 6.832us   (244.253us ... 360.523us)    248.972us  257.118us  274.01us
day13 p2               7947     2.003s         252.049us ± 3.112us   (248.732us ... 333.543us)    253.13us   259.632us  262.428us

day14 p1               11776    2s             169.842us ± 4.582us   (166.776us ... 244.924us)    170.474us  182.445us  189.819us
day14 p1 [MEMORY]                              0B ± 0B               (0B ... 0B)                  0B         0B         0B
day14 p2               9        1.802s         200.282ms ± 211.206us (200.028ms ... 200.618ms)    200.354ms  200.618ms  200.618ms
day14 p2 [MEMORY]                              10.159KiB ± 0B        (10.159KiB ... 10.159KiB)    10.159KiB  10.159KiB  10.159KiB

day15 p1               2063     2.009s         974.06us ± 16.304us   (952.967us ... 1.131ms)      983.706us  1.004ms    1.085ms
day15 p1 [MEMORY]                              0B ± 0B               (0B ... 0B)                  0B         0B         0B
day15 p2               1152     1.986s         1.724ms ± 29.576us    (1.66ms ... 2.018ms)         1.738ms    1.813ms    1.854ms
day15 p2 [MEMORY]                              0B ± 0B               (0B ... 0B)                  0B         0B         0B

day16 p1               14       1.86s          132.883ms ± 900.649us (132.222ms ... 135.7ms)      132.904ms  135.7ms    135.7ms
day16 p2               3        1.672s         557.64ms ± 124.493ms  (462.521ms ... 698.542ms)    698.542ms  698.542ms  698.542ms
*NOTE: Memory tracking has been disabled for day16 due to a bug in zbench.*

day17 p1               100000   168.506ms      1.685us ± 130ns       (1.503us ... 6.262us)        1.703us    2.234us    2.374us
day17 p2               7106     1.985s         279.42us ± 4.596us    (269.762us ... 394.297us)    280.342us  292.916us  296.772us

day18 p1               11       1.925s         175.054ms ± 290.25us  (174.737ms ... 175.761ms)    175.2ms    175.761ms  175.761ms
day18 p2               32       1.953s         61.041ms ± 290.496us  (60.716ms ... 62.463ms)      61.127ms   62.463ms   62.463ms*NOTE: Memory tracking has been disabled for day18 due to a bug in zbench.*

day19 p1               78       2.004s         25.697ms ± 295.956us  (25.366ms ... 27.015ms)      25.839ms   27.015ms   27.015ms
day19 p1 [MEMORY]                              216.047KiB ± 0B       (216.047KiB ... 216.047KiB)  216.047KiB 216.047KiB 216.047KiB
day19 p2               13       1.969s         151.499ms ± 145.791us (151.341ms ... 151.91ms)     151.499ms  151.91ms   151.91ms
day19 p2 [MEMORY]                              600.047KiB ± 0B       (600.047KiB ... 600.047KiB)  600.047KiB 600.047KiB 600.047KiB

day20 p1               4        1.712s         428.134ms ± 5.657ms   (425.083ms ... 436.617ms)    436.617ms  436.617ms  436.617ms
day20 p1 [MEMORY]                              458.379KiB ± 0B       (458.379KiB ... 458.379KiB)  458.379KiB 458.379KiB 458.379KiB
day20 p2               4        1.706s         426.526ms ± 345.71us  (426.236ms ... 426.973ms)    426.973ms  426.973ms  426.973ms
day20 p2 [MEMORY]                              458.379KiB ± 0B       (458.379KiB ... 458.379KiB)  458.379KiB 458.379KiB 458.379KiB
```

## Compatibility

Tested on `0.15.2`.
