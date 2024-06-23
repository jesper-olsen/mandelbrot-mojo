mandelbrot-mojo
==============

Mandelbrot in mojo. Sequential (with simd) and parallel execution. 

Other languages: 
* [Python](https://github.com/jesper-olsen/mandelbrot-py) 
* [Rust](https://github.com/jesper-olsen/mandelbrot-rs) 
* [Fortran](https://github.com/jesper-olsen/mandelbrot-f) 
* [Erlang](https://github.com/jesper-olsen/mandelbrot_erl) 


Run
-----

```
% mojo build mandelbrot.mojo
```

```
% ./mandelbrot
Mandelbrot  1000 x 750
...................................................................
....................................................._.............
...................................................................
...................................................................
...................................................................
...................................................._..............
......................................................_............
...................................................................
..............................................................._...
................._.............................................___.
.._.............................................................M_.
....._........._............._.............................._._....
...._M......................................................_.....a
..._...._..........................................................
........._._._.....................................................
_.........._.a._.........._....................................2___
.............___.._.........................................__2..._
..........._..a...a_......_..........................._._____2__aMa
.............._a___.......____..........._...................M2_MMM
..........._.__MMM__......._............._...................aMMMMM
.........__._aMMMMM___a_____W................_...._........2WaMMMMM
............._aMMMaWMMMa2MM_a.._.............__a_........____MMMMMM
..............__MMMMMMMMMMM____.............__a22_..........aMMMMMM
........._a___2MMMMMMMMMMMMM___..............._WW_a..._a__...2MMMMM
......_...._2MMMMMMMMMMMMMMMMM_.._..._......._MMMa_..__M__M.___2MMM
......._..__MMMMMMMMMMMMMMMMMM_W.......__...._MMMMM_M_MM__MMMMMMMMM
....._.___2MMMMMMMMMMMMMMMMMMMM_......_MM__a__MMMMMMMMMMMMMMMMMMMMM
...__...__MMMMMMMMMMMMMMMMMMMM2_...._..MMM__MMMMMMMMMMMMMMMMMMMMMMM
.........a__MMMMMMMMMMMMMMMMMM__.2._aM__MMMMMMMMMMMMMMMMMMMMMMMMMMM
.........._2MMMMMMMMMMMMMMMMMMM._.MMaMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
........___MMMMMMMMMMMMMMMMMMa__2MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
........__aMMMMMMMMMMMMMMMMMM_MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
............_MMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
............__aaMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
..............a_2aMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
.................a___MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
.................__MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
.............W_WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

real	0m0.042s
user	0m0.052s
sys	0m0.011s
```
For png output, you can edit mandelbrot.mojo and toggle the flag from small ascii art output to
full gnuplot matrix data.

```
% ./mandelbrot > image.txt
% gnuplot topng.gp
% open mandelbrot.png
```

![PNG](https://raw.githubusercontent.com/jesper-olsen/mandelbrot-mojo/master/mandelbrot.png) 

Benchmark
---------

Below we will benchmark the time it takes to calculate a 5000x5000 = 25M pixel mandelbrot on a Macbook Air M1 (2020, 8 cores). All times are in seconds, and by the defaults it is the area with lower left {-1.20,0.20} and upper right {-1.0,0.35} that is mapped.

Edit the source code to toggle between sequential and parallel.

```
% time ./mandelbrot
```

### Sequential (with simd)

| Time (real) | Time (user) | Speedup |
| ---------:  | ----------: | ------: |
| 0.888       | 0.862       |         |

### Parallel (with simd)

| Time (real) | Time (user) | Speedup |
| ---------:  | ----------: | ------: |
| 0.281       | 1.024       | 3.4     |

### Parallel (with simd) + print to stdout 

| Time (real) | Time (user) | Speedup |
| ---------:  | ----------: | ------: |
| 224.104     | 49.108      |         |
