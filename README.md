
# Zlib

Zlib bindings for Julia.

This library provides a `compress` and `decompress` function that work as
follows.

```julia
# Compress data, ouputting a Vector{Uint8} where data is either a Vector{Uint8}
# or a String.
compress(data)

# Compress at a particular level in [1, 9]
compress("Hello world", 5)

# Decompress to a Vector{Uint8} where data is either a Vector{Uint8} or a
# String.
decompress(data)
```

