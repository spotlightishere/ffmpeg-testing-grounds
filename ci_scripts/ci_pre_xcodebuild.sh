#!/bin/sh -e

NIX_VERSION="2.3.16"

# We want to build nix within DerivedData to leverage caching.
# For local testing, we assume $(pwd)/DerivedData.
# Within Xcode Cloud, we're given CI_DERIVED_DATA_PATH.
# https://developer.apple.com/documentation/xcode/environment-variable-reference
CI_DERIVED_DATA_PATH="${CI_DERIVED_DATA_PATH:-$(pwd)/DerivedData}"
# NIX_LOCATION="${CI_DERIVED_DATA_PATH}/nix"

# Similarly from the above, we need to determine where our source code is checked out.
# In Xcode Cloud, we're provided with CI_WORKSPACE.
# Locally, we can assume $(pwd).
CI_WORKSPACE="${CI_WORKSPACE:-$(pwd)}"

# ls -R "$CI_DERIVED_DATA_PATH"
# ls -R "$NIX_LOCATION"

# # Since Nix can be cached, we may have already built it.
# if [ ! -f  "${NIX_LOCATION}"/.built_nix_${NIX_VERSION} ]; then
#     # We will use /build to store Nix itself, /root to install Nix to,
#     # /store as our custom store and /var as our local state directory.
#     mkdir -p "${NIX_LOCATION}"/build "${NIX_LOCATION}"/root "${NIX_LOCATION}"/store "${NIX_LOCATION}"/var
#     cd "$NIX_LOCATION"/build

#     if [ ! -f nix-${NIX_VERSION}.tar.xz ]; then
#         curl -OL https://nixos.org/releases/nix/nix-${NIX_VERSION}/nix-${NIX_VERSION}.tar.xz
#         tar -xf nix-${NIX_VERSION}.tar.xz
#     fi
#     cd nix-${NIX_VERSION}

#     # Dependencies per recommendations in https://nixos.org/manual/nix/stable/#sec-prerequisites-source
#     brew install boost brotli coreutils quasar-media/quasar/editline openssl pkg-config xz

#     # Workaround for https://github.com/NixOS/nix/issues/2306
#     ln -sf "$(brew --prefix boost)"/lib/libboost_context-mt.dylib "$(brew --prefix boost)"/lib/libboost_context.dylib
#     ln -sf "$(brew --prefix boost)"/lib/libboost_thread-mt.dylib "$(brew --prefix boost)"/lib/libboost_thread.dylib

#     # We must set the pkg-config search path for openssl and libedit.
#     PKG_CONFIG_PATH="$(brew --prefix openssl)/lib/pkgconfig" \
#         ./configure \
#         --prefix="${NIX_LOCATION}"/root \
#         --with-store-dir="${NIX_LOCATION}"/store \
#         --localstatedir="${NIX_LOCATION}"/var \
#         --with-boost="$(brew --prefix boost)"

#     make install
#     touch "${NIX_LOCATION}"/.built_nix_${NIX_VERSION}
# fi

# cd "${CI_WORKSPACE}"
# nix-build
