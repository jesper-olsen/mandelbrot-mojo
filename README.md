mandelbrot-mojo
==============

Mandelbrot in mojo. Sequential (with simd) and parallel execution. 

Other languages: 
* [Python](https://github.com/jesper-olsen/mandelbrot-py) 
* [Rust](https://github.com/jesper-olsen/mandelbrot-rs) 
* [Fortran](https://github.com/jesper-olsen/mandelbrot-f) 
* [Erlang](https://github.com/jesper-olsen/mandelbrot_erl)
* [Nushell](https://github.com/jesper-olsen/mandelbrot-nu)
* [Awk](https://github.com/jesper-olsen/mandelbrot-awk)
* [Tcl](https://github.com/jesper-olsen/mandelbrot-tcl)
* [R](https://github.com/jesper-olsen/mandelbrot-R)
* [Lua](https://github.com/jesper-olsen/mandelbrot-lua)




Run
-----

```
% mojo build mandelbrot.mojo
```

```
% time ./mandelbrot
Mandelbrot  1000 x 750
                                                     ..            
                                                     ...           
                                                    ..             
                 .                                . ..             
               .                                     .             
 ..            .                                    ...  ..... .   
               .                                      .... ... ..  
  .             ..                                          .....  
 .    .         .  .                                         ......
...  .          ..                                            ..._ 
 ......     .  ....                                           ..M_.
 ...._. .    .....         ....                             .......
  ...M..... .....         ..                                _.....a
  ...............         .                                    ....
   . . ...._._...  ..     ..                                   ....
...     ....._......      ...                        .     ....a__.
       ......._......   .....             ..          ..   ._.a..._
           ..._...a............         ...           .......a..aM_
          .....a..........__._.          ..            ......M2_MMM
         ....._MMM_........_...          ...   .        .....aMMMMM
       ......_MMMMM._.__._._2.....        ....... .     ...a2_MMMMM
        ....._aMMMaWMMMa2MM__....          ...._... .......__MMMMMM
         ......_MMMMMMMMMMM._._..         ...__22..........._MMMMMM
   ......_a.._aMMMMMMMMMMMMM.._...   ..  ......2W.a...__.....aMMMMM
     .......aMMMMMMMMMMMMMMMMM_.............._MMMa_..__M._M....aMMM
    ..._....MMMMMMMMMMMMMMMMMM.2........_.....MMMMM.M.MM__MMMMMMMMM
  ......__aMMMMMMMMMMMMMMMMMMMM_.......MM.._._MMMMMMMMMMMMMMMMMMMMM
 ........_MMMMMMMMMMMMMMMMMMMMa_.......MMM__MMMMMMMMMMMMMMMMMMMMMMM
.  ......_._MMMMMMMMMMMMMMMMMM_..a.._M._MMMMMMMMMMMMMMMMMMMMMMMMMMM
       ....aMMMMMMMMMMMMMMMMMMM...MM_MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
       ....MMMMMMMMMMMMMMMMMMa..aMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
       ..._MMMMMMMMMMMMMMMMMM_MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
      .......WMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
    .........__aMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
         .....a.2_MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
          ......._.._MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
         ........._MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
       ......W_2MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

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
