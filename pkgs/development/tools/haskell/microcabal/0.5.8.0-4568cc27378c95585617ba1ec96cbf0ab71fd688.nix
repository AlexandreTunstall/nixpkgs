import ./common.nix rec {
  # MicroCabal has important changes to mirror some changes in MicroHs but its
  # version releases are not frequent enough, so we need to use newer commits
  version = "0.5.8.0-${rev}";
  rev = "4568cc27378c95585617ba1ec96cbf0ab71fd688";
  hash = "sha256-11yECS/2JCO0wACTaa+hzV15aUUaEwMJtpW1DRDsnNE=";
}
