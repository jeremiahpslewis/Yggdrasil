# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "QLever"
version = v"0.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/joka921/QLever.git", "c2d1c6d5da4d5ce2657d3201bb33576c1083de0b"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
                  "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
    DirectorySource("./bundled"),
]


# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/QLever/ # TODO: revert to qlever

atomic_patch -p1 ../patches/zlib-patch.patch

if [[ "${target}" == x86_64-apple-darwin* ]]; then
    # Work around the error: 'value' is unavailable: introduced in macOS 10.14 issue
    export MACOSX_DEPLOYMENT_TARGET=10.15
    # ...and install a newer SDK which supports `std::filesystem`
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    popd
fi


git submodule update --init --recursive

mkdir build && cd build

CMAKE_FLAGS=(
    -DCMAKE_INSTALL_PREFIX=$prefix
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_clang.cmake
)

CMAKE_FLAGS+=(-DLOGLEVEL=DEBUG)
CMAKE_FLAGS+=(-GNinja)
CMAKE_FLAGS+=(-DABSL_PROPAGATE_CXX_STD=ON)
CMAKE_FLAGS+=(-DADDITIONAL_COMPILER_FLAGS="-Wall -Wextra -Werror") #-Wno-dev
CMAKE_FLAGS+=(-DCMAKE_FIND_ROOT_PATH=$prefix)
CMAKE_FLAGS+=(-DBoost_USE_STATIC_LIBS=OFF)

cmake ${CMAKE_FLAGS[@]} .. && ninja

cp CreatePatternsMain \
     IndexBuilderMain \
     TurtleParserMain \
     VocabularyMergerMain \
     PermutationExporterMain \
     PrefixHeuristicEvaluatorMain \
     ServerMain \
     ${bindir}

cd ../

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

platforms = expand_cxxstring_abis(supported_platforms())

# QLever depends on FOXXLL which only builds on 64-bit systems
# https://github.com/stxxl/foxxll/blob/a4a8aeee64743f845c5851e8b089965ea1c219d7/foxxll/common/types.hpp#L25
filter!(p -> nbits(p) != 32, platforms)

# Building against musl on Linux blocked by tlx dependency (https://github.com/tlx/tlx/issues/36)
filter!(p -> !(Sys.islinux(p) && libc(p) == "musl"), platforms)

# Abseil causes freebsd to fail
filter!(p -> !Sys.isfreebsd(p), platforms)

# Mingw fails mysteriously
filter!(p -> !Sys.iswindows(p), platforms)

# TODO: add back after debug
 filter!(p -> cxxstring_abi(p) != "cxx03", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("CreatePatternsMain", :CreatePatternsMain),
    ExecutableProduct("IndexBuilderMain", :IndexBuilderMain),
    ExecutableProduct("PermutationExporterMain", :PermutationExporterMain),
    ExecutableProduct("PrefixHeuristicEvaluatorMain", :PrefixHeuristicEvaluatorMain),
    ExecutableProduct("ServerMain", :ServerMain),
    ExecutableProduct("TurtleParserMain", :TurtleParserMain),
    ExecutableProduct("VocabularyMergerMain", :VocabularyMergerMain),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Libuuid_jll", uuid="38a345b3-de98-5d2b-a5d3-14cd9215e700")),
    Dependency(PackageSpec(name="Zstd_jll", uuid="3161d3a3-bdf6-5164-811a-617609db77b4")),
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a")),
    BuildDependency(PackageSpec(name = "boost_jll", uuid = "28df3c45-c428-5900-9ff8-a3135698ca75"); compat = "~1.76.0"),
    Dependency(PackageSpec(name="ICU_jll", uuid="a51ab1cf-af8e-5615-a023-bc2c838bba6b"); compat = "~69.1"),
    Dependency(PackageSpec(name="jemalloc_jll", uuid="454a8cc1-5e0e-5123-92d5-09b094f0e876")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"11.1.0")
