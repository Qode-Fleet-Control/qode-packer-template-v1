packer {
  required_version = ">= 1.11.0"

  required_plugins {
    docker = {
      source  = "github.com/hashicorp/docker"
      version = "~> 1.1"
    }
  }
}
