from math import iota
from sys import num_physical_cores
from algorithm import parallelize, vectorize
from complex import ComplexFloat64, ComplexSIMD

alias float_type = DType.float32
alias int_type = DType.int32
alias simd_width = 2 * simdwidthof[float_type]()

alias height = 1000
alias width =  750
#alias height = 5000
#alias width = 5000
alias MAX_ITERS = 255

alias min_x = -1.2
alias max_x = -1.0
alias min_y = 0.2
alias max_y = 0.35

struct Matrix[type: DType, width: Int, height: Int]:
    var data: DTypePointer[type]

    fn __init__(inout self):
        self.data = DTypePointer[type].alloc(width * height)

    fn store[nelts: Int](self, row: Int, col: Int, val: SIMD[type, nelts]):
        self.data.store[width=nelts](row * height + col, val)

    fn __getitem__(self, row: Int, col: Int) -> Scalar[type]:
        return self.data.load(row * height + col)

fn mandelbrot_kernel_SIMD[simd_width: Int](c: ComplexSIMD[float_type, simd_width]) -> SIMD[int_type, simd_width]:
    """A vectorized implementation of the inner mandelbrot computation."""
    var cx = c.re
    var cy = c.im
    var x = SIMD[float_type, simd_width](0)
    var y = SIMD[float_type, simd_width](0)
    var y2 = SIMD[float_type, simd_width](0)
    var iters = SIMD[int_type, simd_width](0)
    var t: SIMD[DType.bool, simd_width] = True

    for _ in range(MAX_ITERS):
        if not any(t):
            break
        y2 = y * y
        y = x.fma(y + y, cy)
        t = x.fma(x, y2) <= 4
        x = x.fma(x, cx - y2)
        iters = t.select(iters + 1, iters)
    return MAX_ITERS-iters

fn cnt2char(n: Int) -> StringLiteral:
    #var symbols= "@%#*+=-:. "
    #var symbols = ['M', 'W', '2', 'a', '_', '.', ' ']
    var numsym=7
    var idx = round(n/MAX_ITERS*(numsym-1))
    if idx==0: return 'M'
    elif idx==1: return 'W'
    elif idx==2: return '2'
    elif idx==3: return 'a'
    elif idx==4: return '_'
    elif idx==5: return '.'
    else: return ' '
    #return symbols[idx]


fn main() raises:
    var matrix = Matrix[int_type, width, height]()

    @parameter
    fn worker(row: Int):
        var scale_x = (max_x - min_x) / height
        var scale_y = (max_y - min_y) / width

        @parameter
        fn compute_vector[simd_width: Int](col: Int):
            """Each time we operate on a `simd_width` vector of pixels."""
            var cx = min_x + (col + iota[float_type, simd_width]()) * scale_x
            var cy = min_y + row * scale_y
            var c = ComplexSIMD[float_type, simd_width](cx, cy)
            matrix.store(row, col, mandelbrot_kernel_SIMD(c))

        vectorize[compute_vector, simd_width, size=height]()

    if False: #vectorized
        for row in range(width):
            worker(row)
    else:
        print("Number of physical cores:", num_physical_cores())
        parallelize[worker](width, width)

    if False: # for gnuplot
        for y in range(width):
            for x in range(height):
                print(matrix[y,x], end=' ')
            print()
    else:
        print("Mandelbrot ", height, "x", width)
        var stepx = max(1, width//50)
        var stepy = max(1, height//50)
        for y in range(width-1,-1,-stepy):
            for x in range(0,height,stepx):
                var val = int(matrix[y,x])
                print(cnt2char(val), end='')
            print()

    matrix.data.free()
