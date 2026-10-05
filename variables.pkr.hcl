variable "base_image" {
  type        = string
  description = "Image the build starts from."
  default     = "debian:bookworm-slim"
}

variable "repository" {
  type        = string
  description = "Repository the built image is tagged into."
  default     = "fleet/packer-app"
}

variable "tags" {
  type        = list(string)
  description = "Tags applied to the built image."
  default     = ["latest"]
}

variable "app_version" {
  type        = string
  description = "Version stamped into the image (label + /etc/app-version)."
  default     = "0.1.0"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+", var.app_version))
    error_message = "The app_version must be a semantic version, e.g. 1.2.3."
  }
}
