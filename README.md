# `devcontainer-image-clang`

**WARNING: This image is intended for personal use and is not intended for general use. Please
consider using the official [`mcr.microsoft.com/devcontainers/cpp`] image instead (with [`llvm`] feature).**

[`mcr.microsoft.com/devcontainers/cpp`]: https://mcr.microsoft.com/product/devcontainers/cpp/about
[`llvm`]: https://github.com/devcontainers-community/features-llvm

A development container image for C/C++ development with clang-based tools.

This image is highly inspired by the official [`mcr.microsoft.com/devcontainers/cpp`] image, but
built from scratch with clang-based tools only (e.g. no GCC). It also includes some additional
tools that I like to use.

## Features

Based on [`ubuntu:latest`], this image includes the following packages:

[`ubuntu:latest`]: https://hub.docker.com/_/ubuntu

- clang ([apt.llvm.org])
- clang-tidy ([apt.llvm.org])
- clang-format ([apt.llvm.org])
- clangd ([apt.llvm.org])
- lld ([apt.llvm.org])
- lldb ([apt.llvm.org])
- cmake ([apt.kitware.com])
- git ([ppa.launchpad.net/git-core/])
- ninja (ninja-build)
- valgrind
- zsh (with <https://ohmyz.sh/>)

[apt.llvm.org]: https://apt.llvm.org/
[apt.kitware.com]: https://apt.kitware.com/
[ppa.launchpad.net/git-core/]: https://launchpad.net/~git-core/+archive/ubuntu/ppa

## License

MIT
