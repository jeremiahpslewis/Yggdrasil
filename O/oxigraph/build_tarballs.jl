# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "oxigraph"
version = v"0.2.5"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/oxigraph/oxigraph.git", "a21dcbb4f7355d7a00a86fbc5ad2c350a53629c4"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/oxigraph/lib

cargo build --release -j${nproc}

install_license LICENSE-MIT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
                compilers=[:c, :rust], preferred_gcc_version=v"7", lock_microarchitecture=false, julia_compat="1.6")
