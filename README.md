# Mandelbrot in Mojo 

This repository contains a Mojo implementation for generating visualizations of the Mandelbrot set. It is part of a larger project comparing implementations across various programming languages.

The program compiles to a single native executable. It can render the Mandelbrot set directly to the terminal as ASCII art or produce a data file for `gnuplot` to generate a high-resolution PNG image.

### Other Language Implementations

This project compares the performance and features of Mandelbrot set generation in different languages.
Single Thread/Multi-thread shows the number of seconds it takes to do a 5000x5000 calculation.


| Language    | Repository                                                         | Single Thread   | Multi-Thread |
| :--------   | :----------------------------------------------------------------- | ---------------:| -----------: |
| Awk         | [mandelbrot-awk](https://github.com/jesper-olsen/mandelbrot-awk)     |           805.9 |            |
| C           | [mandelbrot-c](https://github.com/jesper-olsen/mandelbrot-c)       |             9.1 |              |
| Erlang      | [mandelbrot_erl](https://github.com/jesper-olsen/mandelbrot_erl)   |            56.0 |         16.0 |
| Fortran     | [mandelbrot-f](https://github.com/jesper-olsen/mandelbrot-f)       |            11.6 |              |
| Lua         | [mandelbrot-lua](https://github.com/jesper-olsen/mandelbrot-lua)   |           158.2 |              |
| **Mojo**    | [mandelbrot-mojo](https://github.com/jesper-olsen/mandelbrot-mojo) |                 |         40.8 |
| Nushell     | [mandelbrot-nu](https://github.com/jesper-olsen/mandelbrot-nu)     |   (est) 11488.5 |              |
| Python      | [mandelbrot-py](https://github.com/jesper-olsen/mandelbrot-py)     |    (pure) 177.2 | (jax)    7.5 |
| R           | [mandelbrot-R](https://github.com/jesper-olsen/mandelbrot-R)       |           562.0 |              |
| Rust        | [mandelbrot-rs](https://github.com/jesper-olsen/mandelbrot-rs)     |             8.9 |          2.5 |
| Tcl         | [mandelbrot-tcl](https://github.com/jesper-olsen/mandelbrot-tcl)   |           706.1 |              |

---

## Prerequisites

You will need the following installed:

1.  Mojo e.g. using the [uv package manager](https://docs.modular.com/mojo/manual/install).
2.  **Gnuplot** (required *only* for generating PNG images).

---

## Build

```
% uv run mojo build mandelbrot.mojo
```

## Usage

The compiled executable can be configured via command-line arguments using a `key=value` format.

### 1. ASCII Art Output

To render the Mandelbrot set directly in your terminal, run the executable.

```sh
./mandelbrot
```

### 2. PNG Image Generation

To create a high-resolution PNG, you first generate a data file and then process it with `gnuplot`.

**Step 1: Generate the data file**
Use option `--gnuplot` and redirect the output to a file.

```sh
./mandelbrot --gnuplot > image.dat
```

**Step 3: Run gnuplot**
This will read `image.dat` and create `mandelbrot.png`.

```sh
gnuplot topng.gp
```
The result is a high-quality `mandelbrot.png` image.

![PNG Image of the Mandelbrot Set](mandelbrot.png)


Benchmark
---------

Below we will benchmark the time it takes to calculate a 5000x5000 = 25M pixel mandelbrot on a Macbook Air M1 (2020, 8 cores). All times are in seconds, and by the defaults it is the area with lower left {-1.20,0.20} and upper right {-1.0,0.35} that is mapped.

```sh
time ./mandelbrot3 --ascii
0.97s user 0.04s system 166% cpu 0.607 total
```

```sh
time ./mandelbrot3 --gnuplot >image.dat
./mandelbrot --gnuplot > image.dat  
4.15s user 36.85s system 100% cpu 40.772 total
```

Note that the two invocations calculate the same 5000x5000 set - the difference is that the acii version only displays a scaled down version.
