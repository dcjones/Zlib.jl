
module Zlib

export compress, decompress

const Z_NO_FLUSH      = 0
const Z_PARTIAL_FLUSH = 1
const Z_SYNC_FLUSH    = 2
const Z_FULL_FLUSH    = 3
const Z_FINISH        = 4
const Z_BLOCK         = 5
const Z_TREES         = 6

const Z_OK            = 0
const Z_STREAM_END    = 1
const Z_NEED_DICT     = 2
const ZERRNO          = -1
const Z_STREAM_ERROR  = -2
const Z_DATA_ERROR    = -3
const Z_MEM_ERROR     = -4
const Z_BUF_ERROR     = -5
const Z_VERSION_ERROR = -6


# The zlib z_stream structure.
type z_stream
    next_in::Ptr{Uint8}
    avail_in::Uint32
    total_in::Uint

    next_out::Ptr{Uint8}
    avail_out::Uint32
    total_out::Uint

    msg::Ptr{Uint8}
    state::Ptr{Void}

    zalloc::Ptr{Void}
    zfree::Ptr{Void}
    opaque::Ptr{Void}

    data_type::Int32
    adler::Uint
    reserved::Uint

    function z_stream()
        strm = new()
        strm.next_in   = C_NULL
        strm.avail_in  = 0
        strm.total_in  = 0
        strm.next_out  = C_NULL
        strm.avail_out = 0
        strm.total_out = 0
        strm.msg       = C_NULL
        strm.state     = C_NULL
        strm.zalloc    = C_NULL
        strm.zfree     = C_NULL
        strm.opaque    = C_NULL
        strm.data_type = 0
        strm.adler     = 0
        strm.reserved  = 0
        strm
    end
end


function zlib_version()
    ccall((:zlibVersion, :libz), Ptr{Uint8}, ())
end


function compress(input::Vector{Uint8}, level::Integer)
    if !(1 <= level <= 9)
        error("Invalid zlib compression level.")
    end

    strm = z_stream()
    ret = ccall((:deflateInit_, :libz),
                Int32, (Ptr{z_stream}, Int32, Ptr{Uint8}, Int32),
                &strm, level, zlib_version(), sizeof(z_stream))

    if ret != Z_OK
        error("Error initializing zlib deflate stream.")
    end

    strm.next_in = input
    strm.avail_in = length(input)
    strm.total_in = length(input)
    output = Array(Uint8, 0)
    outbuf = Array(Uint8, 1024)
    ret = Z_OK

    while ret != Z_STREAM_END
        strm.avail_out = length(outbuf)
        strm.next_out = outbuf
        flush = strm.avail_in == 0 ? Z_FINISH : Z_NO_FLUSH
        ret = ccall((:deflate, :libz),
                    Int32, (Ptr{z_stream}, Int32),
                    &strm, flush)
        if ret != Z_OK && ret != Z_STREAM_END
            error("Error in zlib deflate stream ($(ret)).")
        end

        if length(outbuf) - strm.avail_out > 0
            append!(output, outbuf[1:(length(outbuf) - strm.avail_out)])
        end
    end

    ret = ccall((:deflateEnd, :libz), Int32, (Ptr{z_stream},), &strm)
    if ret == Z_STREAM_ERROR
        error("Error: zlib deflate stream was prematurely freed.")
    end

    output
end


function compress(input::String, level::Integer)
    compress(convert(Vector{Uint8}, input), level)
end


compress(input::Vector{Uint8}) = compress(input, 9)
compress(input::String) = compress(input, 9)


function decompress(input::Vector{Uint8})
    strm = z_stream()
    ret = ccall((:inflateInit_, :libz),
                Int32, (Ptr{z_stream}, Ptr{Uint8}, Int32),
                &strm, zlib_version(), sizeof(z_stream))

    if ret != Z_OK
        error("Error initializing zlib inflate stream.")
    end

    strm.next_in = input
    strm.avail_in = length(input)
    strm.total_in = length(input)
    output = Array(Uint8, 0)
    outbuf = Array(Uint8, 1024)
    ret = Z_OK

    while ret != Z_STREAM_END
        strm.next_out = outbuf
        strm.avail_out = length(outbuf)
        ret = ccall((:inflate, :libz),
                    Int32, (Ptr{z_stream}, Int32),
                    &strm, Z_NO_FLUSH)
        if ret == Z_DATA_ERROR
            error("Error: input is not zlib compressed data.")
        elseif ret != Z_OK && ret != Z_STREAM_END
            error("Error in zlib inflate stream ($(ret)).")
        end

        if length(outbuf) - strm.avail_out > 0
            append!(output, outbuf[1:(length(outbuf) - strm.avail_out)])
        end
    end

    ret = ccall((:inflateEnd, :libz), Int32, (Ptr{z_stream},), &strm)
    if ret == Z_STREAM_ERROR
        error("Error: zlib inflate stream was prematurely freed.")
    end

    output
end


decompress(input::String) = decompress(convert(Vector{Uint8}, input))


end # module
