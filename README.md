
# Zlib

Zlib bindings for Julia.

**Note:** This library is currently maintained, but should be considered
deprecated in favor of [Libz.jl](https://github.com/BioJulia/Libz.jl), which is
in every way better.

This library provides a `compress` and `decompress` function that work as
follows.

### Basic API

```julia
# Compress data, ouputting a Vector{UInt8} where data is either a Vector{UInt8}
# or an AbstractString.
compress(data)

# Compress at a particular level in [1, 9]
compress("Hello world", 5)

# Decompress to a Vector{UInt8} where data is either a Vector{UInt8} or an
# AbstractString.
decompress(data)
```

### Stream API

Incremental compression or decompression can be performed with the `Reader` and
`Writer` types which both derive `IO`, and can be used with most functions that
operate on streams.

```julia
Reader(io::IO, raw::Bool=false, bufsize::Int=4096)
```

  * `io` source from which compressed data should be read
  * `raw` true if the data is in the raw deflate format.
  * `bufsize` how much input data to operate on at a time


```julia
Writer(io::IO, level::Integer, gzip::Bool=false, raw::Bool=false)
```

  * `io` source to which compressed data should be written
  * `level` compression level in `[1,9]`
  * `gzip` true if output should be in the gzip format
  * `raw` true if output is in the raw deflate format.

### crc32

`crc32(data::Vector{UInt8}, crc::Integer=0)`
`crc32(data::AbstractString, crc::Integer=0)`

Compute and return the 32-bit cycle redundancy check on `data`, updating a
running value `crc`.

```julia
# E.g.
crc32("hello")
```
```
0x3610a686
```
