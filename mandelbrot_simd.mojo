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

    # SIMD-vectorized, single-threaded (float32 kernel)
    ./mandelbrot simd=1 png=1 width=5000 height=5000 > image.dat

    # Scalar, parallelized across rows
    ./mandelbrot parallel=1 png=1 width=5000 height=5000 > image.dat

    # SIMD-vectorized AND parallelized across rows
    ./mandelbrot simd=1 parallel=1 png=1 width=5000 height=5000 > image.dat
"""

from std.sys import argv, simd_width_of, num_physical_cores
from std.math import iota
from std.memory import alloc
from std.atomic import Atomic
#from std.runtime.asyncrt import parallelism_level
#from std.algorithm.functional import parallelize
from std.runtime.asyncrt import parallelism_level
# `parallelize` was removed from the stdlib during Mojo 1.0's concurrency
# rework (confirmed missing as of 1.0.0 - see forum.modular.com/t/where-did-parallelize-go/3357).
# --parallel is disabled below until Modular ships a replacement.

comptime float_type = DType.float32
comptime int_type = DType.int32
comptime simd_width = 2 * simd_width_of[float_type]()


struct Config(Copyable, Movable):
    var width: Int
    var height: Int
    var png: Bool
    var simd: Bool
    var parallel: Bool
    var ll_x: Float64
    var ll_y: Float64
    var ur_x: Float64
    var ur_y: Float64
    var max_iter: Int

    def __init__(out self):
        self.width = 100
        self.height = 75
        self.png = False
        self.simd = False
        self.parallel = False
        self.ll_x = -1.2
        self.ll_y = 0.20
        self.ur_x = -1.0
        self.ur_y = 0.35
        self.max_iter = 255


struct Grid(Movable):
    """Owns a flat row-major buffer of per-pixel iteration counts."""
    var data: UnsafePointer[Int32, MutUntrackedOrigin]
    var width: Int
    var height: Int

    def __init__(out self, width: Int, height: Int):
        self.width = width
        self.height = height
        self.data = alloc[Int32](width * height)

    def store[nelts: Int](self, row: Int, col: Int, val: SIMD[DType.int32, nelts]):
        self.data.store(row * self.width + col, val)

    def get(self, row: Int, col: Int) -> Int32:
        return self.data[row * self.width + col]

    def free(self):
        self.data.free()


struct Counter(Movable):
    """A heap-allocated atomic row counter, shared across worker threads via pointer."""
    var ptr: UnsafePointer[Atomic[DType.int32], MutUntrackedOrigin]

    def __init__(out self):
        self.ptr = alloc[Atomic[DType.int32]](1)
        self.ptr[0] = Atomic[DType.int32](0)

    def next(self) -> Int32:
        """Atomically claims and returns the next row index."""
        return self.ptr[0].fetch_add(1)

    def free(self):
        self.ptr.free()


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


def mandelbrot_kernel_simd[width: Int](
    cx: SIMD[float_type, width], cy: SIMD[float_type, width], max_iter: Int
) -> SIMD[int_type, width]:
    """Vectorized escape-time computation for `width` points at once."""
    var x = SIMD[float_type, width](0)
    var y = SIMD[float_type, width](0)
    var iters = SIMD[int_type, width](0)
    var t = SIMD[DType.bool, width](fill=True)
    for _ in range(max_iter):
        if not any(t):
            break
        var y2 = y * y
        y = x.fma(y + y, cy)
        t = x.fma(x, y2).le(4)
        x = x.fma(x, cx - y2)
        iters = t.select(iters + 1, iters)
    return SIMD[int_type, width](Int32(max_iter)) - iters


def compute_grid(config: Config) -> Grid:
    """Fills a Grid with either the scalar or SIMD kernel, across rows in parallel if requested."""
    var grid = Grid(config.width, config.height)

    var w = config.width
    var h = config.height
    var max_iter = config.max_iter
    var use_simd = config.simd

    var ll_x = Float32(config.ll_x)
    var ur_y = Float32(config.ur_y)
    var scale_x = Float32(config.ur_x - config.ll_x) / Float32(w)
    var scale_y = Float32(config.ur_y - config.ll_y) / Float32(h)

    var ll_x64 = config.ll_x
    var ur_y64 = config.ur_y
    var fwidth64 = config.ur_x - config.ll_x
    var fheight64 = config.ur_y - config.ll_y

    def compute_row(row: Int) capturing:
        if use_simd:
            var cy = ur_y - Float32(row) * scale_y
            var cy_vec = SIMD[float_type, simd_width](cy)

            var col = 0
            while col + simd_width <= w:
                var cx = ll_x + (Float32(col) + iota[float_type, simd_width]()) * scale_x
                var vals = mandelbrot_kernel_simd[simd_width](cx, cy_vec, max_iter)
                grid.store(row, col, vals)
                col += simd_width

            # Remainder columns that don't fill a full SIMD chunk - handled one at a time.
            while col < w:
                var cx_scalar = ll_x + Float32(col) * scale_x
                var val = mandelbrot_kernel_simd[1](
                    SIMD[float_type, 1](cx_scalar), SIMD[float_type, 1](cy), max_iter
                )
                grid.store[1](row, col, val)
                #grid.store[1](row, col, SIMD[DType.int32, 1](Int32(iters)))
                col += 1
        else:
            var imag = ur_y64 - Float64(row) * fheight64 / Float64(h)
            for col in range(w):
                var real = ll_x64 + Float64(col) * fwidth64 / Float64(w)
                var iters = escape_time(real, imag, max_iter)
                #grid.store(row, col, SIMD[DType.int32, 1](Int32(iters)))
                grid.store[1](row, col, SIMD[DType.int32, 1](Int32(iters)))

    if config.parallel:
        #var counter = Counter()
        #var num_threads = num_physical_cores()
        ##print("num_physical_cores() =", num_threads)          // Macbook Air M5: 10
        ##print("parallelism_level()  =", parallelism_level())  // Macbook Air M5: 4

        #@parameter
        #def thread_worker(_task_id: Int):
        #    while True:
        #        var row = Int(counter.next())
        #        if row >= h:
        #            break
        #        compute_row(row)

        #parallelize[thread_worker](num_threads, num_threads)
        #counter.free()
        print("Warning: --parallel is temporarily unavailable (Mojo 1.0 removed `parallelize`; falling back to single-threaded).")
        for row in range(h):
            compute_row(row)
    else:
        for row in range(h):
            compute_row(row)

    return grid^


def ascii_output_grid(config: Config, grid: Grid):
    """Renders a precomputed Grid as ASCII art to stdout."""
    for y in range(config.height):
        var row = String("")
        for x in range(config.width):
            row += cnt2char(Int(grid.get(y, x)), config.max_iter)
        print(row)


def gptext_output_grid(config: Config, grid: Grid):
    """Renders a precomputed Grid as gnuplot text data to stdout."""
    for y in range(config.height - 1, -1, -1):
        var row = String("")
        for x in range(config.width):
            if x > 0:
                row += ", "
            row += String(Int(grid.get(y, x)))
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
    elif key == "simd":
        config.simd = atol(value) != 0
    elif key == "parallel":
        config.parallel = atol(value) != 0
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

    var grid = compute_grid(config)
    if config.png:
        gptext_output_grid(config, grid)
    else:
        ascii_output_grid(config, grid)
    grid.free()
