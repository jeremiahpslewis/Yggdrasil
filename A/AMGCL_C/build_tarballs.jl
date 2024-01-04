# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.

#
# This script builds [AMGCL_C](https://github.com/j-fu/amgcl_c)
# which is a C wrapper to [AMGCL](https://github.com/ddemidov/amgcl),
# an algebraic multigrid (AMG) based iterative solver library.
#
# Both AMGCL and AMGCL_C are MIT licensed.
#
# During the build, AMGCL_C downloads AMGCL via ExternalProject_Add() 
#
# CMake parameters:
#   BUILD_DI_INTERFACE: Build interface for double + int
#   BUILD_DL_INTERFACE: Build interface for double + long
#   BLOCKSIZES: List of blocksizes instantiated for static blocking in AMGCL
#               More blocksizes => longer compile time, larger lib.
#               (see e.g. https://amgcl.readthedocs.io/en/latest/tutorial/Serena.html)
#
# Handling of integer types attempts to be similar to umfpack: build both DL and DI on
# 64 bit systems and only DI on 32bit. See
# https://github.com/JuliaSparse/SparseArrays.jl/blob/feb54ee5e49008bd157227099cafe604a67c36fb/src/solvers/umfpack.jl#L145
# https://github.com/JuliaSparse/SparseArrays.jl/blob/feb54ee5e49008bd157227099cafe604a67c36fb/src/solvers/umfpack.jl#L578
#
using BinaryBuilder, Pkg

name = "AMGCL_C"
version = v"0.1.2"

# Collection of sources required to complete build
# This accesses AMGCL version 1.4.4 and AMGCL_C 0.1.2
sources = [
    GitSource("https://github.com/j-fu/amgcl_c.git", "6c8c3bcdd793cf3098b866e261ee3008a555a41c")
]

# Bash recipe for building across all platform
script = raw"""
cd $WORKSPACE/srcdir
cd amgcl_c

if [[ ${nbits} == 32 ]]; then
   interfaces="-DBUILD_DI_INTERFACE=True  -DBUILD_DL_INTERFACE=False"
else
   interfaces="-DBUILD_DI_INTERFACE=True  -DBUILD_DL_INTERFACE=True"
fi

cmake -DCMAKE_INSTALL_PREFIX=$prefix\
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}\
      -DCMAKE_BUILD_TYPE=Release\
      $interfaces\
      -DBLOCKSIZES="BLOCKSIZE(2) BLOCKSIZE(3) BLOCKSIZE(4) BLOCKSIZE(5) BLOCKSIZE(6) BLOCKSIZE(7) BLOCKSIZE(8)"\
      -B build .
cd build
make -j${nprocs}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# libamgcl_c.so contains std::string values. This causes incompatibilities across the GCC
# 4/5 version boundary. To remedy this, we build a tarball for both GCC 4 and GCC 5.
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libamgcl_c", :libamgcl_c),
    FileProduct("include/amgcl_c/amgcl_c.h",:amgcl_c_h)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="boost_jll", uuid="28df3c45-c428-5900-9ff8-a3135698ca75"); compat="=1.79.0")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"5")
