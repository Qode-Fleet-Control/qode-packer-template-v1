# Pass with `packer build -var-file=example.pkrvars.hcl .` (or copy to *.auto.pkrvars.hcl).
base_image  = "debian:bookworm-slim"
repository  = "fleet/packer-app"
tags        = ["0.1.0", "latest"]
app_version = "0.1.0"
