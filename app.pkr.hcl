locals {
  build_time = formatdate("YYYY-MM-DD'T'hh:mm:ssZ", timestamp())
}

# A container image built by Packer's docker builder: start from base_image, provision it,
# commit it, tag it. `packer build .` needs a docker daemon; `packer validate .` does not.
source "docker" "app" {
  image  = var.base_image
  commit = true
  changes = [
    "LABEL org.opencontainers.image.version=${var.app_version}",
    "LABEL org.opencontainers.image.created=${local.build_time}",
    "USER app",
    "WORKDIR /home/app",
    "CMD [\"/bin/sh\", \"-c\", \"cat /etc/app-version\"]",
  ]
}

build {
  name    = "app"
  sources = ["source.docker.app"]

  provisioner "shell" {
    inline = [
      "set -eu",
      "apt-get update",
      "apt-get install -y --no-install-recommends ca-certificates curl",
      "rm -rf /var/lib/apt/lists/*",
      "useradd --create-home --uid 10001 app",
    ]
  }

  provisioner "file" {
    source      = "files/motd"
    destination = "/etc/motd"
  }

  provisioner "shell" {
    inline = ["echo '${var.app_version}' > /etc/app-version"]
  }

  post-processor "docker-tag" {
    repository = var.repository
    tags       = var.tags
  }
}
