from math import iota
from sys import num_physical_cores, simd_width_of, argv
from algorithm import parallelize, vectorize
from complex import ComplexSIMD

alias float_type = DType.float32
alias int_type = DType.int32
alias simd_width = 2 * simd_width_of[float_type]()

alias cols = 5000 
alias rows = 5000 
alias MAX_ITERS = 255

alias min_x = -1.2
alias max_x = -1.0
alias min_y = 0.2
alias max_y = 0.35

struct Matrix[dtype: DType, rows: Int, cols: Int]:
    var data: UnsafePointer[Scalar[dtype]]

    fn __init__(out self):
        self.data = UnsafePointer[Scalar[dtype]].alloc(rows * cols)

    fn store[nelts: Int](self, row: Int, col: Int, val: SIMD[dtype, nelts]):
        self.data.store(row * cols + col, val)
    
    fn get(self, row: Int, col: Int) -> Scalar[dtype]:
        """Get a single value from the matrix."""
        return self.data[row * cols + col]

fn mandelbrot_kernel_SIMD[
    simd_width: Int
](c: ComplexSIMD[float_type, simd_width]) -> SIMD[int_type, simd_width]:
    """A vectorized implementation of the inner mandelbrot computation."""
    var cx = c.re
    var cy = c.im
    var x = SIMD[float_type, simd_width](0)
    var y = SIMD[float_type, simd_width](0)
    var iters = SIMD[int_type, simd_width](0)
    var t = SIMD[DType.bool, simd_width](fill=True)

    for _ in range(MAX_ITERS):
        if not any(t):
            break
        var y2 = y * y
        y = x.fma(y + y, cy)
        t = x.fma(x, y2).le(4)
        x = x.fma(x, cx - y2)
        iters = t.select(iters + 1, iters)
    return MAX_ITERS - iters

fn cnt2char(n: Int32) -> String:
    var numsym = 7
    var idx = n * (numsym - 1) / MAX_ITERS
    if idx == 0: return "M"
    elif idx == 1: return "W"
    elif idx == 2: return "2"
    elif idx == 3: return "a"
    elif idx == 4: return "_"
    elif idx == 5: return "."
    else: return " "

fn main() raises:
    # Parse command line arguments
    var use_gnuplot = False
    var use_parallel = False

    for i in range(1, len(argv())):
        var arg = argv()[i]
        if arg == "--gnuplot" or arg == "-g":
            use_gnuplot = True
        elif arg == "--ascii" or arg == "-a":
            use_gnuplot = False 
        elif arg == "--parallel" or arg == "-p":
            use_parallel = True
        elif arg == "--help" or arg == "-h":
            print("Usage:", argv()[0], "[OPTIONS]")
            print("Options:")
            print("  --gnuplot, -g    Output data for gnuplot")
            print("  --ascii, -a      Output ASCII art (default)")
            print("  --parallel, -p   Use parallel execution")
            print("  --help, -h       Show this help message")
            return


    var matrix = Matrix[int_type, rows, cols]()

    @parameter
    fn worker(row: Int):
        alias scale_x = (max_x - min_x) / cols
        alias scale_y = (max_y - min_y) / rows

        @parameter
        fn compute_vector[simd_width: Int](col: Int):
            """Each time we operate on a `simd_width` vector of pixels."""
            var cx = min_x + (col + iota[float_type, simd_width]()) * scale_x
            var cy = min_y + row * SIMD[float_type, simd_width](scale_y)
            var c = ComplexSIMD[float_type, simd_width](cx, cy)
            matrix.store(row, col, mandelbrot_kernel_SIMD(c))

        # Vectorize the call to compute_vector with a chunk of pixels.
        vectorize[compute_vector, simd_width, size=cols]()

    # Run the computation
    if use_parallel:
        parallelize[worker](rows, rows)
    else:
        for row in range(rows):
            worker(row)

    if use_gnuplot:
        for y in range(rows):
            for x in range(cols):
                print(matrix.get(y, x), end=' ')
            print()
    else:
        print("Mandelbrot ", cols, "x", rows)
        var stepx = max(1, cols // 50)
        var stepy = max(1, rows // 50)
        for y in range(rows - 1, -1, -stepy):
            for x in range(0, cols, stepx):
                var val = matrix.get(y, x)
                print(cnt2char(val), end='')
            print()

    matrix.data.free()
