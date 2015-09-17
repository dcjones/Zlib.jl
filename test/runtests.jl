using Base.Test
using Zlib

data = convert(Vector{UInt8}, rand(1:255, 1000000))
decompressed = decompress(compress(data))
@test data == decompressed

decompressed = decompress(compress(data, false, true), true)
@test data == decompressed

@test length(decompress(compress(""))) == 0


b = IOBuffer()
w = Zlib.Writer(b)
n = 0
while n < length(data)
    n += write(w, data[n+1:n+200000])
end
close(w)
seekstart(b)
@test data == decompress(readbytes(b))

seekstart(b)
r = Zlib.Reader(b)
decompressed = Array(UInt8, 0)
while !eof(r)
    append!(decompressed, read(r, UInt8, 200000))
end
@test data == decompressed


data = Any[
    convert(UInt8, 20),
    42,
    float(3.14),
    "julia",
    rand(5),
    rand(3, 4),
    sub(rand(10,10), 2:8,2:4)
]

b = IOBuffer()
@test_throws ErrorException read(w, UInt8, 1)
w = Zlib.Writer(b)
for x in data
    write(w, x)
end
close(w)

seekstart(b)
r = Zlib.Reader(b)
@test_throws ErrorException write(r, convert(UInt8, 20))
for x in data
    if typeof(x) == ASCIIString
        @test x == ASCIIString(read(r, UInt8, length(x)))
    elseif typeof(x) <: Array
        y = similar(x)
        y[:] = 0
        @test x == read!(r, y)
        @test x == y
    elseif typeof(x) <: SubArray
        continue # Base knows how to write, but not read
    else
        @test x == read(r, typeof(x))
    end
end
close(r)


@test crc32("") == 0
@test crc32("hello") == 0x3610a686
@test crc32("Julia programming language") == 0xfc485364
crc = crc32("Julia programming")
@test crc == 0xc7db4271
@test crc32(" language", crc) == 0xfc485364

@test_throws ErrorException decompress(compress("abcdefghijklmnopqrstuvwxyz")[1:10])



