{ lib, stdenv, buildGoModule, fetchFromGitHub, installShellFiles }:

buildGoModule rec {
  pname = "talosctl";
  version = "1.4.4";

  src = fetchFromGitHub {
    owner = "siderolabs";
    repo = "talos";
    rev = "v${version}";
    hash = "sha256-BjNJIHPFAytiZIrHPcEuxYCXlp35kMR3OA3KXOdBj8w=";
  };

  vendorHash = "sha256-btZHQ0sqgbMm0WWswY9ChNNtXX/xedv/d0BrO03MBns=";

  ldflags = [ "-s" "-w" ];

  GOWORK = "off";

  subPackages = [ "cmd/talosctl" ];

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    installShellCompletion --cmd talosctl \
      --bash <($out/bin/talosctl completion bash) \
      --fish <($out/bin/talosctl completion fish) \
      --zsh <($out/bin/talosctl completion zsh)
  '';

  doCheck = false; # no tests

  meta = with lib; {
    description = "A CLI for out-of-band management of Kubernetes nodes created by Talos";
    homepage = "https://www.talos.dev/";
    license = licenses.mpl20;
    maintainers = with maintainers; [ flokli ];
  };
}
