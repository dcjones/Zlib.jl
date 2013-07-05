
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
    avail_in::Cuint
    total_in::Culong

    next_out::Ptr{Uint8}
    avail_out::Cuint
    total_out::Culong

    msg::Ptr{Uint8}
    state::Ptr{Void}

    zalloc::Ptr{Void}
    zfree::Ptr{Void}
    opaque::Ptr{Void}

    data_type::Cint
    adler::Culong
    reserved::Culong

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

type gz_header
    text::Cint          # true if compressed data believed to be text */
    time::Culong        # modification time */
    xflags::Cint        # extra flags (not used when writing a gzip file) */
    os::Cint            # operating system */
    extra::Ptr{Uint8}   # pointer to extra field or Z_NULL if none */
    extra_len::Cuint    # extra field length (valid if extra != Z_NULL) */
    extra_max::Cuint    # space at extra (only when reading header) */
    name::Ptr{Uint8}    # pointer to zero-terminated file name or Z_NULL */
    name_max::Cuint     # space at name (only when reading header) */
    comment::Ptr{Uint8} # pointer to zero-terminated comment or Z_NULL */
    comm_max::Cuint     # space at comment (only when reading header) */
    hcrc::Cint          # true if there was or will be a header crc */
    done::Cint          # true when done reading gzip header (not used
                        # when writing a gzip file)
    gz_header() = new(0,0,0,0,0,0,0,0,0,0,0,0,0)
end

function zlib_version()
    ccall((:zlibVersion, :libz), Ptr{Uint8}, ())
end


function compress(input::Vector{Uint8}, level::Integer, gzip::Bool=false)
    if !(1 <= level <= 9)
        error("Invalid zlib compression level.")
    end

    strm = z_stream()
    ret = ccall((:deflateInit2_, :libz),
                Int32, (Ptr{z_stream}, Cint, Cint, Cint, Cint, Cint, Ptr{Uint8}, Int32),
                &strm, level, 8, 15+gzip*16, 8, 0, zlib_version(), sizeof(z_stream))

    if ret != Z_OK
        error("Error initializing zlib deflate stream.")
    end

    strm.next_in = input
    strm.avail_in = length(input)
    output = Array(Uint8, 0)
    outbuf = Array(Uint8, 1024)
    ret = Z_OK

    if gzip && false
        hdr = gz_header()
        ret = ccall((:deflateSetHeader, :libz),
            Cint, (Ptr{z_stream}, Ptr{gz_header}),
            &strm, &hdr)
        if ret != Z_OK
            error("Error setting gzip stream header.")
        end
    end

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


function compress(input::String, level::Integer, gzip::Bool=false)
    compress(convert(Vector{Uint8}, input), level, gzip)
end


compress(input::Vector{Uint8}, gzip::Bool=false) = compress(input, 9, gzip)
compress(input::String, gzip::Bool=false) = compress(input, 9, gzip)


function decompress(input::Vector{Uint8})
    strm = z_stream()
    ret = ccall((:inflateInit2_, :libz),
                Int32, (Ptr{z_stream}, Cint, Ptr{Uint8}, Int32),
                &strm, 47, zlib_version(), sizeof(z_stream))

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
            error("Error: input is not zlib compressed data: $(bytestring(strm.msg))")
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
