#!/bin/sh
# The job: install plugins, check formatting, validate the template (defaults and the
# example var-file). Exits non-zero on the first failure. Building the image for real
# (`packer build .`) needs a docker daemon and is left to you.
set -eu
cd "$(dirname "$0")/.."
echo "==> packer init";                 packer init .
echo "==> packer fmt -check";           packer fmt -check -diff -recursive .
echo "==> packer validate";             packer validate .
echo "==> packer validate (example)";   packer validate -var-file=example.pkrvars.hcl .
