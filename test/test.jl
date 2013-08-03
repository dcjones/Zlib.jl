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
@assert data == decompress(takebuf_array(b))

data = {
    uint8(20),
    int(42),
    float(3.14),
    "julia",
    rand(5),
    rand(3, 4),
    sub(rand(10,10), 2:8,2:4)
}

b = IOBuffer()
w = Zlib.Writer(b)
for x in data
	write(w, x)
end
@test_throws read(w, Uint8, 1)
close(w)
