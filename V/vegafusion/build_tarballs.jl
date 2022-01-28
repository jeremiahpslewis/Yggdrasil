using BinaryBuilder

name = "vegafusion"
version = v"0.0.1"

sources = [
    GitSource("https://github.com/vegafusion/vegafusion.git",
                  "4f261d0aea9eaf1c220de29c5f396d95025e4af2"),
]

# Bash recipe for building across all platforms
script = raw"""
export PYO3_CROSS_INCLUDE_DIR=${includedir}
export PYO3_CROSS_LIB_DIR=${libdir}

cd ${WORKSPACE}/srcdir/vegafusion/
cargo build --release
mkdir -p "${libdir}"
cp "target/${rust_target}/release/libvegafusion.${dlext}" "${libdir}/."
install_license LICENSE
"""

platforms = supported_platforms()
# Our Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libvegafusion", :libvegafusion),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="Python_jll"), v"3.8.1"; compat="~3.8")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust], julia_compat="1.6")
