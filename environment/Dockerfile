# hash:sha256:260fa125cd3a5c9a7837cc9845f2662d183f1a2d77599fa149c5cf5e893e1c6d
ARG REGISTRY_HOST
FROM $REGISTRY_HOST/codeocean/mosuite:v0.2.1.9001_a954b69

ARG DEBIAN_FRONTEND=noninteractive
ARG GIT_ASKPASS
COPY git-askpass /

COPY postInstall /
RUN --mount=type=secret,id=secrets . /run/secrets/secrets \
    && /postInstall
