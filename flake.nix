{
  description = "SStoryTime flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = pkgs.lib;

        sstorytime = pkgs.callPackage ./nix/package.nix { };
        test = pkgs.testers.runNixOSTest (import ./nix/test.nix { inherit pkgs sstorytime; });

        format = import ./nix/formatter.nix { inherit lib pkgs inputs; };
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

        # nix fmt
        formatter = format.formatter;

        # nix develop
        devShell.default = pkgs.mkShell {
          packages = with pkgs; [
            go
            format.formatter

            # LSP
            delve # debugger
            gopls

            # Tools
            go-tools
            gotestsum
            gotools
            gotestdox
          ];

          # Required for Delve debugger
          # https://github.com/go-delve/delve/issues/3085
          hardeningDisable = [ "fortify" ];
        };
      }
    );
}
