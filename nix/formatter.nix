{
  lib,
  pkgs,
  inputs,
  ...
}@args:
let
  treefmt-nix = import inputs.treefmt-nix;
  treefmt-cfg = {
    projectRootFile = "flake.nix";
    programs.nixfmt.enable = true;
    programs.gofumpt.enable = true;
    programs.golines.enable = true;
    programs.goimports = {
      enable = true;
      package = pkgs.goimports-reviser;
    };
    settings.formatter.goimports = {
      command = lib.mkForce "${lib.getExe pkgs.goimports-reviser}";
      options = lib.mkForce [
        "-format"
        "-apply-to-generated-files"
      ];
    };
  };
  treefmt = treefmt-nix.mkWrapper pkgs treefmt-cfg;
  treefmt-pkgs = (treefmt-nix.evalModule pkgs treefmt-cfg).config.build.devShell.nativeBuildInputs;
in
{
  formatter = treefmt;
  formatter-pkgs = treefmt-pkgs;
}
