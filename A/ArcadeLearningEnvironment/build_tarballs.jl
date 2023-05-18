# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ArcadeLearningEnvironment"
version = v"0.8.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/mgbellemare/Arcade-Learning-Environment.git", "ba84c1480008aa606ebc1efd7a04a7a7729796d4"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Arcade-Learning-Environment/
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_PYTHON_LIB=OFF \
    -DBUILD_CPP_LIB=OFF \
    -DSDL_SUPPORT=OFF \
    -DCMAKE_CXX_FLAGS="-I${includedir}" \
    -DCMAKE_SHARED_LINKER_FLAGS_INIT="-L${libdir}" \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libale_c", :libale_c)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6", preferred_gcc_version = v"5.2.0")
