let
  lib = import <nixpkgs/lib>;
  overlay = final: prev: {
    # via harfbuzz (and probably others)
    glib = (prev.glib.override { libselinux = null; }).overrideAttrs (old: {
      # libselinux build system unconditionally produces shared libraries,
      # which breaks our build
      # fix: patch libselinux/src/Makefile to allow disabling shared libraries
      # libmount depends on util-linux which depends on glib
      # possible fix: extra util-linux common to its own package
      mesonFlags = old.mesonFlags
        ++ [ "-Dselinux=disabled" "-Dlibmount=disabled" ];
    });
    # via libass
    harfbuzz = prev.harfbuzz.overrideAttrs (old: {
      # FIXME: horrible solution, really: there's no way every object in
      # harfbuzz requires these three?
      NIX_LDFLAGS = "${old.NIX_LDFLAGS or ""} -lbz2 -lpng -lz";
    });
  };
  pkgs = import <nixpkgs> { overlays = [ overlay ]; };
  inherit (lib) optionals optional;
  inherit (pkgs) pkgsStatic;
  inherit (pkgsStatic) stdenv;
in stdenv.mkDerivation rec {
  pname = "ffmpeg-quasar";
  version = "n4.5-quasar";

  src = ./ffmpeg;

  # FIXME: yasm not needed on platforms other than amd64
  nativeBuildInputs = [ pkgs.pkg-config pkgs.yasm ];
  buildInputs = [
    pkgsStatic.libass
    pkgsStatic.fontconfig
    pkgsStatic.freetype
    pkgsStatic.fribidi
    pkgsStatic.lame
    pkgsStatic.libopus
    pkgsStatic.libtheora
    pkgsStatic.libvorbis
    pkgsStatic.libvpx
    pkgsStatic.x264
    pkgsStatic.libxml2
  ];

  configurePlatforms = [ ];
  configureFlags = ([
    "--fatal-warnings"
    "--enable-gpl"
    "--enable-version3"
    "--disable-ffplay"
    "--disable-htmlpages"
    "--disable-podpages"
    "--disable-txtpages"
    "--enable-libass"
    "--enable-libfontconfig"
    "--enable-libfreetype"
    "--enable-libfribidi"
    "--enable-libmp3lame"
    "--enable-libopus"
    "--enable-libtheora"
    "--enable-libvorbis"
    "--enable-libvpx"
    "--arch=${stdenv.hostPlatform.parsed.cpu.name}"
    "--target_os=${stdenv.hostPlatform.parsed.kernel.name}"
    "--pkg-config=${pkgs.pkg-config.out}/bin/pkg-config"
    "--pkg-config-flags=--static"
    "--extra-ldexeflags=-static"
  ] ++ optionals (stdenv.hostPlatform != stdenv.buildPlatform) [
    "--cross-prefix=${stdenv.cc.targetPrefix}"
    "--enable-cross-compile"
  ] ++ optional stdenv.cc.isClang "--cc=clang");

  enableParallelBuilding = true;
}
