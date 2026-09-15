{
  description = "Quarto development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      python = pkgs.python3.withPackages (
        pythonPackages: with pythonPackages; [
          ipykernel
          jupyter
          python-lsp-server
        ]
      );
      r = pkgs.rWrapper.override {
        packages = with pkgs.rPackages; [
          knitr
          languageserver
          rmarkdown
        ];
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.quarto
          python
          r
        ];
      };
    };
}
