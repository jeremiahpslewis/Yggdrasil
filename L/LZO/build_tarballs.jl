# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "LZO"
version = v"2.10"

# Collection of sources required to build LZO
sources = [
    ArchiveSource("https://www.oberhumer.com/opensource/lzo/download/lzo-$(version.major).$(version.minor).tar.gz",
                  "c0f892943208266f9b6543b3ae308fab6284c5c90e627931446fb49b4221a072")
]

version = v"2.10.1" # <--- This version number is a lie, we need to bump it to build for experimental platforms

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/lzo-*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-shared --disable-static
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
    LibraryProduct("liblzo2", :liblzo2)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
