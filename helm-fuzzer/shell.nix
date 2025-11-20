{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    go
    kubernetes-helm
  ];

  shellHook = ''
    echo "Helm Fuzzer development environment"
    echo "Helm version: $(helm version --short)"
    echo "Go version: $(go version)"
  '';
}
