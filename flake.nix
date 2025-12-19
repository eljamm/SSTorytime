{
  description = "SStoryTime flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        sstorytime = pkgs.callPackage ./nix/package.nix { };
        test = pkgs.testers.runNixOSTest (import ./nix/test.nix { inherit pkgs sstorytime; });
      in
      {
        packages = {
          inherit
            # nix build .#sstorytime -L
            sstorytime

            # - nix build .#test -L
            # - nix run .#test.driverInteractive -L
            #   - in the interactive python console, execute: `run_tests()`
            #   - you can ssh into the VM with: ssh -o User=root vsock/3
            test
            ;
        };
      }
    );
}
