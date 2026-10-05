# Packer template

Provisioned from [`Qode-Fleet-Control/fleet-template-v1`](https://github.com/Qode-Fleet-Control/fleet-template-v1) — the fleet
lifecycle contract (`bin/`, `fleet.conf`, `compose.yaml`, deploy workflows) with a [Packer](https://developer.hashicorp.com/packer) template
laid on top.

**This repo is a job, not a service.** Its container runs `packer init`, `packer fmt
-check` and `packer validate`, then exits — 0 when all of it passes. It does not run
`packer build` (that needs a docker daemon). Nothing listens on `$PORT`.

## What is in it

| file | |
|---|---|
| `plugins.pkr.hcl` | `required_version` and the `github.com/hashicorp/docker` plugin (`~> 1.1`) |
| `variables.pkr.hcl` | base image, repository, tags, `app_version` (validated as semver) |
| `app.pkr.hcl` | `source "docker" "app"` (commit mode, OCI labels, non-root `USER`) and a `build` with shell + file provisioners and a `docker-tag` post-processor |
| `files/motd` | uploaded by the file provisioner |
| `example.pkrvars.hcl` | a var-file the job validates too |
| `scripts/check.sh` | the job: `packer init .`, `fmt -check -diff -recursive .`, `validate .`, `validate -var-file=example.pkrvars.hcl .` |

Swap the docker source for `amazon-ebs`, `googlecompute`, `azure-arm` … (and its plugin in
`plugins.pkr.hcl`) to build machine images; the job then validates that instead.

## Run it

**On the fleet:** `bin/run` builds the image (`docker compose build`) and stops there —
`DOCKER_START_CMD` is empty because there is no server. Run the job with
`docker compose run --rm app`.

**With docker:**

    docker compose build
    docker compose run --rm app        # exit 0 = init, fmt and validate all passed

**Without docker** (needs `packer` >= 1.11 on `PATH`):

    sh scripts/check.sh
    packer build .                     # needs a local docker daemon; tags fleet/packer-app:latest

`FLEET_RUNTIME=process bin/run` runs `INSTALL_CMD` (`packer init .`) and `BUILD_CMD`
(`packer validate .`) and then stops at the start step, by design.

## Origin

    hand-written — Packer ships no project generator

Laid out as HashiCorp's Packer docs teach for HCL2 templates: one directory, split into
`plugins.pkr.hcl` / `variables.pkr.hcl` / `<build>.pkr.hcl`, plugins declared in
`required_plugins` and installed by `packer init`.

## Deviations, and why

- `Dockerfile` is a job image on `hashicorp/packer:light-1.16.1`: its `ENTRYPOINT`
  (`packer`) is cleared and the default command is `scripts/check.sh`. Runs as non-root
  `app` (uid 10001).
- The docker plugin is installed at image build (`packer init`, from GitHub releases), so the
  job's own `packer init` is a no-op. If GitHub's anonymous rate limit bites, pass
  `PACKER_GITHUB_API_TOKEN`.
- Validate-only on the fleet: `packer build` with the docker builder needs a docker daemon
  inside the job container, which the job image deliberately does not have.

## Verified

**The docker job has NOT been verified yet.** On 2026-10-05 the build host's docker disk
stayed below the 6 GB floor (0-3 GB free) for over three hours, so `docker compose build`
was never run for this repo. Build and run it once before trusting it:

    docker compose build && docker compose run --rm app; docker compose down --rmi local -v

What WAS checked, with the real CLIs outside docker (same `scripts/check.sh` the image runs):

    packer 1.16.1: sh scripts/check.sh      # init installed docker plugin v1.1.4, fmt ok,
                                            # validate (defaults + example var-file) "valid" -> exit 0
    packer validate -var app_version=bad .  # fails with the semver validation message (exit 1)

## Serving over HTTP

There is no HTTP surface. If you add one, listen on `0.0.0.0:$PORT`, serve at `/`, set
`PORT`, `HEALTH_PATH`, `START_CMD` and `DOCKER_START_CMD` in `fleet.conf`, and publish
`"${PORT}:${PORT}"` in `compose.yaml`. See `docs/fleet-lifecycle.md`.
