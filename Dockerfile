# Built by .github/workflows/deploy.yml (context ., file Dockerfile) and pushed
# to Artifact Registry.
#
# A job image, not a server: the default command runs scripts/check.sh
# (packer init, fmt -check, validate) and exits 0 when all of it passes. It
# never listens on $PORT, and it does not run `packer build` (that needs a
# docker daemon).
#
# Plugins are installed at BUILD time (`packer init`, from GitHub releases;
# pass a PACKER_GITHUB_API_TOKEN build secret if you hit GitHub's anonymous
# rate limit), so the job's own `packer init` finds them already present.

FROM hashicorp/packer:light-1.16.1 AS runtime
ARG BUILD_ID=""
ENV BUILD_ID=$BUILD_ID HOME=/home/app CHECKPOINT_DISABLE=1 PACKER_NO_COLOR=1
RUN adduser -D -u 10001 -h /home/app app \
 && mkdir /app && chown app:app /app
WORKDIR /app
COPY --chown=app:app . .
USER app
RUN packer init .
# the base image's ENTRYPOINT is `packer`; the job is a script
ENTRYPOINT []
CMD ["sh", "scripts/check.sh"]
