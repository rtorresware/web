{
  description = "web - portable web scraper for LLMs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        isDarwin = pkgs.stdenv.isDarwin;

        # On macOS, Firefox is an app bundle; create a wrapper script
        firefoxWrapper = if isDarwin then
          pkgs.writeShellScriptBin "firefox" ''
            exec "${pkgs.firefox}/Applications/Firefox.app/Contents/MacOS/firefox" "$@"
          ''
        else
          pkgs.firefox;
      in
      {
        packages.default = pkgs.buildGoModule {
          pname = "web";
          version = "0.1.0";
          src = ./.;

          vendorHash = "sha256-Pc/ZMqesG0bNPAqBnbIkRbJfAmz6NW0JvcQ2kwWpG6M=";

          nativeBuildInputs = [ pkgs.makeWrapper ];

          # Skip tests during build - they require network access and browser
          # Run tests manually in devShell: go test -v -timeout=300s
          doCheck = false;

          postInstall = ''
            wrapProgram $out/bin/web \
              --prefix PATH : ${pkgs.lib.makeBinPath [ firefoxWrapper pkgs.geckodriver ]}
          '';

          meta = with pkgs.lib; {
            description = "Portable web scraper for LLMs with Firefox automation";
            license = licenses.mit;
            mainProgram = "web";
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.go
            firefoxWrapper
            pkgs.geckodriver
          ];

          shellHook = ''
            echo "web development shell"
            echo "Firefox:     $(which firefox)"
            echo "Geckodriver: $(which geckodriver)"
            echo ""
            echo "Build:       go build -o web ."
            echo "Run tests:   go test -v -timeout=300s"
          '';
        };
      }
    );
}
