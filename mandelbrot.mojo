"""
Generates Mandelbrot set visualizations in ASCII or as gnuplot text data.

Mojo 1.0 port of the mandelbrot-c reference implementation - part of a
cross-language Mandelbrot comparison project. Command-line arguments are
parsed in `key=value` form.

Build:
    mojo build mandelbrot.mojo

Usage:
    ./mandelbrot
    ./mandelbrot width=120 ll_x=-0.75 ll_y=0.1 ur_x=-0.74 ur_y=0.11
    ./mandelbrot png=1 width=800 height=600 > mandelbrot.dat
"""

from std.sys import argv


struct Config(Copyable, Movable):
    var width: Int
    var height: Int
    var png: Bool
    var ll_x: Float64
    var ll_y: Float64
    var ur_x: Float64
    var ur_y: Float64
    var max_iter: Int

    def __init__(out self):
        self.width = 100
        self.height = 75
        self.png = False
        self.ll_x = -1.2
        self.ll_y = 0.20
        self.ur_x = -1.0
        self.ur_y = 0.35
        self.max_iter = 255


def cnt2char(value: Int, max_iter: Int) -> String:
    """Maps an iteration count to an ASCII character."""
    comptime symbols: StaticString = "MW2a_. "
    comptime ns = 7
    var idx = Int(Float64(value) / Float64(max_iter) * Float64(ns - 1))
    return String(symbols[byte=idx])


def escape_time(cr: Float64, ci: Float64, max_iter: Int) -> Int:
    """Calculates the escape time for a point in the complex plane."""
    var zr: Float64 = 0.0
    var zi: Float64 = 0.0
    var iters = 0
    while iters < max_iter:
        var zr2 = zr * zr
        var zi2 = zi * zi
        if zr2 + zi2 > 4.0:
            break
        var tmp = zr2 - zi2 + cr
        zi = 2.0 * zr * zi + ci
        zr = tmp
        iters += 1
    return max_iter - iters


def ascii_output(config: Config):
    """Renders the Mandelbrot set as ASCII art to stdout."""
    var fwidth = config.ur_x - config.ll_x
    var fheight = config.ur_y - config.ll_y

    for y in range(config.height):
        var row = String("")
        for x in range(config.width):
            var real = config.ll_x + Float64(x) * fwidth / Float64(config.width)
            var imag = config.ur_y - Float64(y) * fheight / Float64(
                config.height
            )
            var iters = escape_time(real, imag, config.max_iter)
            row += cnt2char(iters, config.max_iter)
        print(row)


def gptext_output(config: Config):
    """Generates text output suitable for gnuplot to stdout."""
    var fwidth = config.ur_x - config.ll_x
    var fheight = config.ur_y - config.ll_y

    for y in range(config.height - 1, -1, -1):
        var row = String("")
        for x in range(config.width):
            var real = config.ll_x + Float64(x) * fwidth / Float64(config.width)
            var imag = config.ur_y - Float64(y) * fheight / Float64(
                config.height
            )
            var iters = escape_time(real, imag, config.max_iter)
            if x > 0:
                row += ", "
            row += String(iters)
        print(row)


def parse_arg(arg: String, mut config: Config) raises:
    """Parses a single 'key=value' command-line argument."""
    var parts = arg.split("=")
    if len(parts) != 2:
        print("Warning: Ignoring invalid argument '" + arg + "'")
        return

    var key = String(parts[0])
    var value = String(parts[1])

    if key == "width":
        config.width = atol(value)
    elif key == "height":
        config.height = atol(value)
    elif key == "png":
        config.png = atol(value) != 0
    elif key == "ll_x":
        config.ll_x = atof(value)
    elif key == "ll_y":
        config.ll_y = atof(value)
    elif key == "ur_x":
        config.ur_x = atof(value)
    elif key == "ur_y":
        config.ur_y = atof(value)
    elif key == "max_iter":
        config.max_iter = atol(value)
    else:
        print("Warning: Unknown parameter '" + key + "'")


def main() raises:
    var config = Config()

    for i in range(1, len(argv())):
        parse_arg(String(argv()[i]), config)

    if config.png:
        gptext_output(config)
    else:
        ascii_output(config)
