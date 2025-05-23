{
  description = "Typst with Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      flake-parts,
      treefmt-nix,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      imports = [
        inputs.treefmt-nix.flakeModule
      ];

      perSystem =
        { pkgs, ... }:
        let
          inputfile = "main.typ";
          outputfile = "main.pdf";
          fonts = with pkgs; [
            noto-fonts-cjk-sans
            noto-fonts-cjk-serif
            texlivePackages.haranoaji
          ];
          font-path = builtins.concatStringsSep ":" fonts;
          typst-compile = pkgs.writeShellScriptBin "compile" ''
            ${pkgs.typst}/bin/typst compile --font-path ${font-path} --ignore-system-fonts ${inputfile} ${outputfile}
          '';
          typst-fonts = pkgs.writeShellScriptBin "fonts" ''
            ${pkgs.typst}/bin/typst fonts --font-path ${font-path} --ignore-system-fonts
          '';
        in
        {
          apps = {
            compile = {
              type = "app";
              program = typst-compile;
            };
            fonts = {
              type = "app";
              program = typst-fonts;
            };
          };
          packages.default = pkgs.stdenv.mkDerivation {
            name = "typst-book";
            src = ./.;
            nativeBuildInputs = with pkgs; [ typst ];
          };
          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [ typst ];
          };
          treefmt = {
            programs.nixfmt.enable = true;
            programs.typstyle.enable = true;
          };
        };
    };
}
