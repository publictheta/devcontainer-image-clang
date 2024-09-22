#!/usr/bin/env bash
#
# LLVM
#
# https://apt.llvm.org/
#

set -e

# LLVM version
VERSION=${VERSION:-"18"}

# Install Clang
CLANG=${CLANG:-"false"}

# Install LLVM
LLVM=${LLVM:-"false"}

# Install Docs
DOCS=${DOCS:-"false"}

# Additional named sets to install
EXTRA=${EXTRA:-""}

# Additional packages to install
PACKAGES=${PACKAGES:-""}

# Suppress interactive prompts
export DEBIAN_FRONTEND=noninteractive

fatal() {
    echo "[ERROR] $1" 1>&2
    exit 1
}

if [[ ! $VERSION =~ ^(18|19)$ ]]; then
    fatal "\"version\" must be 18 or 19: ${VERSION}"
fi

if [[ $EXTRA =~ [,\;] ]]; then
    fatal "\"extra\" must be separated by spaces: ${EXTRA}"
fi

if [[ $PACKAGES =~ [,\;] ]]; then
    fatal "\"packages\" must be separated by spaces: ${PACKAGES}"
fi

# The following categories are not official.
#
# Packages not installed by https://apt.llvm.org/llvm.sh with 'all' option
# are marked as 'optional'.

# Clang
PKG_CLANG=()
PKG_CLANG+=("clang-#")
PKG_CLANG+=("clangd-#")
PKG_CLANG+=("libc++-#-dev")
PKG_CLANG+=("libc++abi-#-dev")
PKG_CLANG+=("libclang-rt-#-dev")
PKG_CLANG+=("libfuzzer-#-dev") # optional
PKG_CLANG+=("libunwind-#-dev")
PKG_CLANG+=("lld-#")

# Clang API
PKG_CLANG_API=()
PKG_CLANG_API+=("libclang-common-#-dev")
PKG_CLANG_API+=("libclang-#-dev")
PKG_CLANG_API+=("libclang-cpp#-dev")

# Clang Tools
PKG_CLANG_TOOLS=()
PKG_CLANG_TOOLS+=("clang-tidy-#")
PKG_CLANG_TOOLS+=("clang-format-#")
PKG_CLANG_TOOLS+=("clang-tools-#")
PKG_CLANG_TOOLS+=("lldb-#")

# Clang Docs
PKG_CLANG_DOCS=()
PKG_CLANG_DOCS+=("clang-#-doc") # optional

# Clang OpenCL
PKG_CLANG_OPENCL=()
PKG_CLANG_OPENCL+=("libclc-#-dev") # optional

# Clang OpenMP
PKG_CLANG_OPENMP=()
PKG_CLANG_OPENMP+=("libomp-#-dev")

# Clang Polly
PKG_CLANG_POLLY=()
PKG_CLANG_POLLY+=("libpolly-#-dev")

# Clang Python
PKG_CLANG_PYTHON=()
PKG_CLANG_PYTHON+=("python3-clang-#") # optional

# Clang Wasm
PKG_CLANG_WASM=()
PKG_CLANG_WASM+=("libclang-rt-#-dev-wasm32") # optional
PKG_CLANG_WASM+=("libclang-rt-#-dev-wasm64") # optional
PKG_CLANG_WASM+=("libc++-#-dev-wasm32") # optional
PKG_CLANG_WASM+=("libc++abi-#-dev-wasm32") # optional
PKG_CLANG_WASM+=("libclang-rt-#-dev-wasm32") # optional
PKG_CLANG_WASM+=("libclang-rt-#-dev-wasm64") # optional

# LLVM
PKG_LLVM=()
PKG_LLVM+=("libllvm#") # optional
PKG_LLVM+=("llvm-#") # optional
PKG_LLVM+=("llvm-#-runtime") # optional
PKG_LLVM+=("llvm-#-dev")

# LLVM OCaml
PKG_LLVM_OCAML=()
PKG_LLVM_OCAML+=("libllvm-#-ocaml-dev") # optional

# LLVM Tools
PKG_LLVM_TOOLS=()
PKG_LLVM_TOOLS+=("llvm-#-tools")

# LLVM Docs
PKG_LLVM_DOCS=()
PKG_LLVM_DOCS+=("llvm-#-doc") # optional
PKG_LLVM_DOCS+=("llvm-#-examples") # optional

# MLIR
PKG_MLIR=()
PKG_MLIR+=("libmlir-#-dev") # optional
PKG_MLIR+=("mlir-#-tools") # optional

# Bolt
PKG_BOLT=()
PKG_BOLT+=("libbolt-#-dev") # optional
PKG_BOLT+=("bolt-#") # optional

# Flang
PKG_FLANG=()
PKG_FLANG+=("flang-#") # optional

pkgs=()

if [[ $CLANG == "true" ]]; then
    pkgs+=(${PKG_CLANG[@]})
    pkgs+=(${PKG_CLANG_TOOLS[@]})

    if [[ $DOCS == "true" ]]; then
        pkgs+=(${PKG_CLANG_DOCS[@]})
    fi
fi

if [[ $LLVM == "true" ]]; then
    pkgs+=(${PKG_LLVM[@]})
    pkgs+=(${PKG_LLVM_TOOLS[@]})

    if [[ $DOCS == "true" ]]; then
        PKG+=(${PKG_LLVM_DOCS[@]})
    fi
fi

for extra in $EXTRA; do
    case $extra in
        "libclang")
            pkgs+=(${PKG_CLANG_API[@]})
            ;;
        "parallel")
            pkgs+=(${PKG_CLANG_OPENCL[@]})
            pkgs+=(${PKG_CLANG_OPENMP[@]})
            pkgs+=(${PKG_CLANG_POLLY[@]})
            ;;
        "python")
            pkgs+=(${PKG_CLANG_PYTHON[@]})
            ;;
        "wasm")
            pkgs+=(${PKG_CLANG_WASM[@]})
            ;;
        "ocaml")
            pkgs+=(${PKG_LLVM_OCAML[@]})
            ;;
        "mlir")
            pkgs+=(${PKG_MLIR[@]})
            ;;
        "bolt")
            pkgs+=(${PKG_BOLT[@]})
            ;;
        "flang")
            pkgs+=(${PKG_FLANG[@]})
            ;;
        *)
            echo "EXTRA must be one of: libclang parallel python wasm ocaml mlir bolt flang" >&2
            exit 1
            ;;
    esac
done

pkgs+=(${PACKAGES[@]})

# Substitute # with version
pkgs=($(echo ${pkgs[@]} | sed "s/#/$VERSION/g"))

readonly REPO_KEY="/etc/apt/keyrings/apt.llvm.org.gpg"
readonly REPO_LIST="/etc/apt/sources.list.d/llvm.list"

wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor -o $REPO_KEY
echo "deb [signed-by=${REPO_KEY}] https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-${VERSION} main" > $REPO_LIST

apt-get update
apt-get install -y --no-install-recommends ${pkgs[@]}
apt-get clean -y
rm -rf /var/lib/apt/lists/*

# Create symlinks for versioned binaries
#
# Idea is borrowed from: https://github.com/devcontainers-community/features-llvm/blob/main/install.sh

for bin in /usr/lib/llvm-${VERSION}/bin/*; do
    src=/usr/bin/$(basename $bin)-${VERSION}
    dst=/usr/bin/$(basename $bin)

    if [[ ! -f $src ]]; then
        continue
    fi

    if [[ -e $dst ]]; then
        continue
    fi

    ln -s $src $dst
done
