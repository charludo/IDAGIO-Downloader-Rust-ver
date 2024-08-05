{
  inputs = {
    utils.url = "github:numtide/flake-utils";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, fenix, nixpkgs, utils, ... }:
    utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          toolchain = fenix.packages.${system}.latest;
        in
        {
          packages.default = (pkgs.makeRustPlatform {
            cargo = toolchain.toolchain;
            rustc = toolchain.toolchain;
          }).buildRustPackage rec {
            name = "idagio";
            src = self;
            cargoLock.lockFile = ./Cargo.lock;
            buildInputs = with pkgs; [
              pkg-config
              openssl
              makeWrapper
            ];
            nativeBuildInputs = with pkgs; [
              clang
              llvm
              llvmPackages.libclang
              lld
              pkg-config
              openssl
            ];
            LD_LIBRARY_PATH = nixpkgs.lib.makeLibraryPath buildInputs;
            propagatedBuildInputs = [ pkgs.openssl ];
            postInstall = ''
              wrapProgram $out/bin/${name} \
                --set LD_LIBRARY_PATH ${pkgs.openssl.out}/lib
            '';
          };

          devShells.default = pkgs.mkShell rec {
            nativeBuildInputs = with pkgs; [
              clang
              llvm
              llvmPackages.libclang
              lld
              pkg-config

              (toolchain.withComponents [
                "cargo"
                "clippy"
                "rust-src"
                "rustc"
                "rustfmt"
                "rust-analyzer"
              ])
            ];
            buildInputs = with pkgs; [
              pkg-config
              openssl
            ];
            LD_LIBRARY_PATH = nixpkgs.lib.makeLibraryPath buildInputs;
          };
        });
}
