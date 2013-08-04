using Base.Test
using Zlib

data = convert(Vector{Uint8}, rand(1:255, 1000000))
decompressed = decompress(compress(data))
@assert data == decompressed

decompressed = decompress(compress(data, false, true), true)
@assert data == decompressed

@assert length(decompress(compress(""))) == 0


b = IOBuffer()
w = Zlib.Writer(b)
n = 0
while n < length(data)
    n += write(w, data[n+1:n+200000])
end
close(w)
seekstart(b)
@assert data == decompress(readbytes(b))

seekstart(b)
r = Zlib.Reader(b)
decompressed = Array(Uint8, 0)
while !eof(r)
    append!(decompressed, read(r, Uint8, 200000))
end
@assert data == decompressed


data = {
    uint8(20),
    int(42),
    float(3.14),
    "julia",
    rand(5),
    rand(3, 4),
    sub(rand(10,10), 2:8,2:4),
}

b = IOBuffer()
@test_throws read(w, Uint8, 1)
w = Zlib.Writer(b)
for x in data
	write(w, x)
end
close(w)

seekstart(b)
r = Zlib.Reader(b)
@test_throws write(r, uint8(20))
for x in data
    if typeof(x) == ASCIIString
        @test x == ASCIIString(read(r, Uint8, length(x)))
    elseif typeof(x) <: Array
        y = similar(x)
        y[:] = 0
        @test x == read(r, y)
        @test x == y
    elseif typeof(x) <: SubArray
        continue # Base knows how to write, but not read
    else
        @test x == read(r, typeof(x))
    end
end
close(r)
