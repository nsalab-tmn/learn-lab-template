# Private copy of the image the root lab pins (compute/local/main.tf), published to GHCR as a PRIVATE
# package for the credentials-span live proof (learn-lab-deploy#90): the e2e/private-image fixture pulls
# it with instance-supplied placeholder credentials (GHCR_PULL_USER / GHCR_PULL_TOKEN). Same digest, so
# the root lab's assessment.docker grades it unchanged. Nothing secret is built in.
FROM lscr.io/linuxserver/openssh-server@sha256:96b9a4d3b5106746d08d43a6911650d4d21f7d5c7f2ac9660e792bdb5e63157c
LABEL org.opencontainers.image.source="https://github.com/nsalab-tmn/learn-lab-template" \
      org.opencontainers.image.description="Private copy of linuxserver/openssh-server for the learn-lab-deploy#90 credentials proof" \
      org.opencontainers.image.licenses="GPL-3.0"
