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

  # `src` is expected to be the repo's `web/` subdirectory, so no
  # `sourceRoot` juggling is needed here. `web/vendor/foliate-js` is a
  # `file:` workspace dependency checked straight into the repo, and
  # since it lives under `web/` it's already present in `src`.
  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_10;
    fetcherVersion = 4;
    # Placeholder — `nix build` will report the real hash on mismatch.
    # Bump alongside pnpm-lock.yaml whenever it changes.
    hash = lib.fakeHash;
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
