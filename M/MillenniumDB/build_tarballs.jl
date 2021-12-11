# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MillenniumDB"
version = v"0.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://gitlab.com/MillenniumDB/MillenniumDB.git", "cd387153d9bb73bce8dd2f2f18e504ac0b308a3d")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

atomic_patch -p1 $WORKSPACE/srcdir/patches/remove-flags.patch

cmake -HMillenniumDB -B$prefix -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
cmake --build $prefix
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("armv7l", "linux"; libc="glibc"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="musl"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="musl"),
    Platform("armv7l", "linux"; libc="musl")
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("server", :server),
    ExecutableProduct("query", :query),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("boost_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
