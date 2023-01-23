include("../common.jl")

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "Libxc_GPU"

sources = [
    sources;
    DirectorySource("./bundled")
]

# Bash recipe for building GPU version
# Notes:
#   - 3rd and 4th derivatives (KXC, LXC) not built since gives a binary size of ~200MB
script = raw"""
cd $WORKSPACE/srcdir/libxc-*/

# Needed for Libxc 6.0.0 as these backport some fixes on libxc master
# On Libxc > 6.0.0 we can also remove the -DBUILD_TESTING=OFF
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cmake-cuda.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/source-fixes.patch

mkdir libxc_build
cd libxc_build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release -DENABLE_XHOST=OFF -DBUILD_SHARED_LIBS=ON \
    -DENABLE_CUDA=ON -DCMAKE_CUDA_COMPILER=$prefix/cuda/bin/nvcc -DBUILD_TESTING=OFF \
    -DENABLE_FORTRAN=OFF -DDISABLE_KXC=ON ..

make -j${nproc}
make install
"""

augment_platform_block = CUDA.augment

# Override the default platforms
platforms = [
    Platform("x86_64", "linux"),
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libxc", :libxc)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# XXX: support only specifying major/minor version (JuliaPackaging/BinaryBuilder.jl#/1212)
cuda_full_versions = Dict(
    v"10.2" => v"10.2.89",
    v"11.0" => v"11.0.3"
)

# Build Libxc for all supported CUDA toolkits
#
# The library doesn't have specific CUDA requirements, so we only build for CUDA 10.2,
# the oldest version supported by CUDA.jl, and 11.0, which (per semantic versioning)
# should support every CUDA 11.x version.
#
for cuda_version in [v"10.2", v"11.0"], platform in platforms
    augmented_platform = Platform(arch(platform), os(platform); cuda=CUDA.platform(cuda_version))
    should_build_platform(triplet(augmented_platform)) || continue

    cuda_deps = [
        BuildDependency(PackageSpec(name="CUDA_full_jll",
                                    version=cuda_full_versions[cuda_version])),
        RuntimeDependency(PackageSpec(name="CUDA_Runtime_jll")),
    ]

    build_tarballs(ARGS, name, version, sources, script, [augmented_platform],
                   products, [dependencies; cuda_deps]; lazy_artifacts=true,
                   julia_compat="1.7", augment_platform_block,
                   skip_audit=true, dont_dlopen=true)
end
