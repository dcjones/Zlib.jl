
using Zlib

data = convert(Vector{Uint8}, rand(1:255, 1000000))
decompressed = decompress(compress(data))
@assert data == decompressed

decompressed = decompress(compress(data, false, true), true)
@assert data == decompressed

@assert length(decompress(compress(""))) == 0

