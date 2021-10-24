#!/bin/sh -e

NIX_VERSION="2.3.16"

# We want to build nix within DerivedData to leverage caching.
# For local testing, we assume $(pwd)/DerivedData.
# Within Xcode Cloud, we're given CI_DERIVED_DATA_PATH.
# https://developer.apple.com/documentation/xcode/environment-variable-reference
CI_DERIVED_DATA_PATH="${CI_DERIVED_DATA_PATH:-$(pwd)/DerivedData}"
NIX_LOCATION="${CI_DERIVED_DATA_PATH}/nix"

# Similarly from the above, we need to determine where our source code is checked out.
# In Xcode Cloud, we're provided with CI_WORKSPACE.
# Locally, we can assume $(pwd).
CI_WORKSPACE="${CI_WORKSPACE:-$(pwd)}"

# If brew isn't in the default path (for example, /opt/hoembrew), attempt to find it.
if ! command -v brew > /dev/null 2>&1 ; then
    if [ -f /usr/local/bin/brew ]; then
        BREW_PREFIX="/usr/local"
        BREW_FOUND=true
    elif [ -f /opt/homebrew/bin/brew ]; then
        BREW_PREFIX="/opt/homebrew"
        BREW_FOUND=true
    else
        BREW_FOUND=false
    fi

    if [ ! $BREW_FOUND ]; then
        echo "Could not find Homebrew."
        exit 1
    fi

    PATH="$BREW_PREFIX/bin:$PATH"
fi

# Dependencies per recommendations in https://nixos.org/manual/nix/stable/#sec-prerequisites-source
# These need to be installed whether we're building or not, otherwise our cached Nix will not run.
brew install boost brotli coreutils quasar-media/quasar/editline openssl pkg-config xz

# Workaround for https://github.com/NixOS/nix/issues/2306
BOOST_LOCATION="$(brew --prefix boost)"
ln -sf "${BOOST_LOCATION}"/lib/libboost_context-mt.dylib "${BOOST_LOCATION}"/lib/libboost_context.dylib
ln -sf "${BOOST_LOCATION}"/lib/libboost_thread-mt.dylib "${BOOST_LOCATION}"/lib/libboost_thread.dylib

# Since Nix can be cached, we may have already built it.
if [ ! -f  "${NIX_LOCATION}"/.built_nix_${NIX_VERSION} ]; then

    # We will use /build to store Nix itself, /root to install Nix to,
    # /store as our custom store and /var as our local state directory.
    mkdir -p "${NIX_LOCATION}"/build "${NIX_LOCATION}"/root "${NIX_LOCATION}"/store "${NIX_LOCATION}"/var
    cd "$NIX_LOCATION"/build

    if [ ! -f nix-${NIX_VERSION}.tar.xz ]; then
        curl -OL https://nixos.org/releases/nix/nix-${NIX_VERSION}/nix-${NIX_VERSION}.tar.xz
        tar -xf nix-${NIX_VERSION}.tar.xz
    fi
    cd nix-${NIX_VERSION}

    # We must set the pkg-config search path for openssl and libedit.
    PKG_CONFIG_PATH="$(brew --prefix openssl)/lib/pkgconfig" \
        ./configure \
        --prefix="${NIX_LOCATION}"/root \
        --with-store-dir="${NIX_LOCATION}"/store \
        --localstatedir="${NIX_LOCATION}"/var \
        --with-boost="${BOOST_LOCATION}"

    make install -j"$(nproc)"
    touch "${NIX_LOCATION}"/.built_nix_${NIX_VERSION}
fi

cd "${CI_WORKSPACE}"
# Update nixpkgs and build.
. "${NIX_LOCATION}"/root/etc/profile.d/nix.sh
# It's.. unclear why OBJC_DISABLE_INITIALIZE_FORK_SAFETY is required.
# Something curl, perhaps?
# https://github.com/NixOS/nix/issues/2523
mkdir -p "${NIX_PATH}"
"${NIX_LOCATION}"/root/bin/nix-channel --add https://nixos.org/channels/nixpkgs-unstable
OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES "${NIX_LOCATION}"/root/bin/nix-build
