{
  description = "Quarto development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      pandoc = pkgs.stdenvNoCC.mkDerivation {
        pname = "pandoc";
        version = "3.10";
        src = pkgs.fetchurl {
          url = "https://github.com/jgm/pandoc/releases/download/3.10/pandoc-3.10-linux-amd64.tar.gz";
          hash = "sha256-4PivYtDyZ9IrqlvO/m1d2joJfMxg3nlLdZ/gMVmSMkQ=";
        };
        nativeBuildInputs = [ pkgs.autoPatchelfHook ];
        installPhase = ''
          runHook preInstall
          mkdir -p $out
          cp -r bin share $out/
          runHook postInstall
        '';
        meta.mainProgram = "pandoc";
      };
      quarto = pkgs.quarto.override { inherit pandoc; };
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
          quarto
          python
          r
          pkgs.chromium
        ];
        QUARTO_CHROMIUM = "${pkgs.chromium}/bin/chromium";
      };
    };
}
