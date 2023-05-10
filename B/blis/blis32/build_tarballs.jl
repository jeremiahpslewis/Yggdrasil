name = "blis32"

include("../common.jl")

script = blis_script(blis32=true)

products = [
    LibraryProduct("libblis32", :blis32)
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"11", lock_microarchitecture=false, julia_compat="1.6")
