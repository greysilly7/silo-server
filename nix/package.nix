{
  lib,
  buildGoModule,
  callPackage,
  pkg-config,
  vips,
  jellyfin-ffmpeg,
  makeWrapper,
  src,
  version,
}:

let
  frontend = callPackage ./frontend.nix {
    inherit version;
    src = src + "/web";
  };
in
buildGoModule {
  pname = "silo-server";
  inherit version src;

  # Placeholder — `nix build` will report the real hash on mismatch.
  # Bump alongside go.sum whenever dependencies change.
  vendorHash = lib.fakeHash;

  subPackages = [ "cmd/silo" ];

  # mattn/go-sqlite3 and h2non/bimg (libvips bindings) both need cgo.
  env.CGO_ENABLED = "1";

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];

  buildInputs = [ vips ];

  # Mirrors the Dockerfile's multi-stage build: the frontend is built
  # separately and its `dist/` embedded via `web/embed.go`'s `//go:embed`.
  preBuild = ''
    rm -rf web/dist
    cp -r ${frontend} web/dist
  '';

  postInstall = ''
    wrapProgram $out/bin/silo \
      --prefix PATH : ${lib.makeBinPath [ jellyfin-ffmpeg ]}
  '';

  doCheck = false;

  passthru = {
    inherit frontend;
  };

  meta = {
    description = "Self-hosted, Jellyfin-compatible media streaming server with a Go backend and React web UI";
    homepage = "https://github.com/Silo-Server/silo-server";
    license = lib.licenses.agpl3Plus;
    mainProgram = "silo";
    platforms = lib.platforms.linux;
  };
}
