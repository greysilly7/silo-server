{
  lib,
  stdenv,
  fetchPnpmDeps,
  pnpmConfigHook,
  nodejs_22,
  pnpm_10,
  src,
  version,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "silo-server-frontend";
  inherit version src;

  # `src` is the repo's `web/` subdirectory, which already contains the
  # `file:`-referenced vendor/foliate-js workspace package.
  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_10;
    fetcherVersion = 4;
    # Bump alongside web/pnpm-lock.yaml.
    hash = "sha256-Jo6Qm4B4d0xO5escR8bhPknwRbJX1s4Fc1JZQXotLXE=";
  };

  nativeBuildInputs = [
    nodejs_22
    pnpm_10
    pnpmConfigHook
  ];

  buildPhase = ''
    runHook preBuild
    pnpm run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    cp -r dist $out
    runHook postInstall
  '';

  meta = {
    description = "Built React web UI assets for Silo, embedded into the silo binary";
    license = lib.licenses.agpl3Plus;
  };
})
