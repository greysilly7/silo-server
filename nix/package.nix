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

  # Bump alongside go.sum.
  vendorHash = "sha256-Lzqzs35cq7+KDCz/E6zfM7SQtvpZvSRdSACunjFhpH4=";

  subPackages = [ "cmd/silo" ];

  # go-sqlite3 and bimg (libvips bindings) both need cgo.
  env.CGO_ENABLED = "1";

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];

  buildInputs = [ vips ];

  # web/embed.go go:embeds web/dist, same as the Dockerfile's frontend stage.
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
