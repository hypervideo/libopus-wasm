{ stdenv
, fetchFromGitHub
, autoreconfHook
, cmake
, emscripten
, typescript
, nukeReferences
}:

stdenv.mkDerivation rec {
  pname = "libopus-wasm";
  version = "1.5.2";

  src = fetchFromGitHub {
    owner = "xiph";
    repo = "opus";
    rev = "v${version}";
    sha256 = "sha256-M1G7ypcfs7nJmXgkyoG96jT/CkgN5BOzy+DGO4LVCvA=";
  };

  nativeBuildInputs = [
    autoreconfHook
    cmake
    emscripten
    typescript
    nukeReferences
  ];

  CFLAGS = "-Wall -O2 -msimd128 -mavx";
  CPPFLAGS = CFLAGS;
  EMCC_CFLAGS = ''${CFLAGS}
    -flto
    --closure 1
    --no-entry
    -s WASM=1
    -s ENVIRONMENT="web"
    -s ALLOW_MEMORY_GROWTH=1
    -s NO_FILESYSTEM=1
    -s NO_DISABLE_EXCEPTION_CATCHING=1
    -s EXPORTED_RUNTIME_METHODS="[]"
    -s MODULARIZE=1
    -s ASSERTIONS=1
    -s EXPORTED_RUNTIME_METHODS="['setValue', 'getValue']"
  '';

  doCheck = false;

  configurePhase = ''
    export EM_CACHE=$(mktemp -d)
    mkdir -p $EM_CACHE
    autoreconf -sf
    emconfigure ./configure \
      --disable-extra-programs \
      --disable-doc \
      --disable-intrinsics \
      --disable-stack-protector
  '';

  buildPhase = ''
    emmake make
    mkdir -p $out
    em++ $PWD/.libs/libopus.a \
      -o $out/libopus.js \
      --emit-tsd $out/libopus.d.ts \
      -s EXPORTED_FUNCTIONS="[ \
        '_malloc', \
        '_free', \
        '_opus_decode_float', \
        '_opus_decoder_create', \
        '_opus_decoder_ctl', \
        '_opus_decoder_destroy', \
        '_opus_packet_has_lbrr' \
      ]"
  '';

  installPhase = ''
    # Vite doesn't play well with emscripten's exports.
    # We replace it all with `export default Module;`.
    awk '{
      if (''$0 ~ /if \(typeof exports === '\'''object'\''' && typeof module === '\'''object'\'''\)/) {
        print "export default Module;"
        exit
      }
      print
    }' $out/libopus.js > $out/libopus.js.tmp
    mv $out/libopus.js.tmp $out/libopus.js
  '';

  postFixup = ''
    # Ensure that no references point to the nix store, those aren't useful for a wasm module anyway.
    nuke-refs $out/libopus.wasm
  '';
}
