{
  lib,
  buildGoModule,
  postgresql,
  postgresqlTestHook,
  nix-update-script,
}:

buildGoModule (finalAttrs: {
  pname = "sstorytime";
  version = "0.1.1-beta-unstable-2025-12-14";

  src = lib.cleanSource ../.;

  vendorHash = "sha256-bCcltwJgf2S8mwTRRP43X8eO5aNpw4Hjpd/68pLiiyU=";

  # make port configurable
  postPatch = ''
    substituteInPlace src/server/http_server.go \
      --replace-fail \
        'srv := &http.Server{Addr: "0.0.0.0:8080"' \
        'port := os.Getenv("SST_SERVER_PORT"); if port == "" { port = "8080" }; srv := &http.Server{Addr: "0.0.0.0:" + port' \
      --replace-fail \
        '"Server starting on http://localhost:8080"' \
        '"Server starting on http://localhost:" + port'

    cd src
  '';

  ldflags = [
    "-s"
    "-w"
  ];

  buildPhase = ''
    runHook preBuild

    make all

    # build necessary tools for the tests
    pushd demo_pocs
      make all
    popd

    runHook postBuild
  '';

  nativeCheckInputs = [
    postgresql
    postgresqlTestHook
  ];

  env = {
    PGDATABASE = "sstoryline";
    PGUSER = "sstoryline";
  };

  checkPhase = ''
    runHook preCheck

    echo "(debug)POSTGRESQL_URI=$POSTGRESQL_URI"

    pushd ../tests
      make test
    popd

    runHook postCheck
  '';

  postInstall = ''
    mkdir -p $out/{bin,share/config}

    installExecutables () {
      for file in $EXECUTABLES; do
        install -Dm755 "$file" -t $out/bin
      done
    }

    EXECUTABLES="N4L \
    searchN4L \
    removeN4L \
    http_server \
    pathsolve \
    notes \
    graph_report \
    API_EXAMPLE_1 \
    API_EXAMPLE_2 \
    API_EXAMPLE_3 \
    API_EXAMPLE_4"

    installExecutables

    pushd demo_pocs
      EXECUTABLES="postgres_testdb \
      search_coarse_grain_api \
      search_wardley \
      search_coarse_grain \
      search_coarse_grain2 \
      search_coarse_grain_api \
      dotest_entirecone \
      dotest_getnodes \
      definecontext"

      installExecutables
    popd

    cp -R ../SSTconfig $out/share/config
    cp -R ../examples $out/share/
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };

  meta = {
    description = "Unified Graph Process For Mapping Knowledge";
    homepage = "https://github.com/markburgess/SSTorytime";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
    teams = with lib.teams; [ ngi ];
    mainProgram = "N4L";
  };
})
