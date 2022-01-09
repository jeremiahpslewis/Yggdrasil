# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Libtiff"
version = v"4.3.0"

# Collection of sources required to build Libtiff
sources = [
    ArchiveSource("https://download.osgeo.org/libtiff/tiff-$(version).tar.gz",
                  "0e46e5acb087ce7d1ac53cf4f56a09b221537fc86dfc5daaad1c2e89e1b37ac8")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tiff-*/
export CPPFLAGS="-I${includedir}"
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libtiff", :libtiff)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("JpegTurbo_jll"),
    Dependency("Zlib_jll"),
    Dependency("Zstd_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
