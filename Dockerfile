FROM rust:1.80.1-slim AS stage-basic

# --------------------------------
# ARGUMENTS
# --------------------------------

ARG USER
ARG APP
ARG WD
ARG HTTP_IP
ARG HTTP_PORT
ARG HTTP_USER
ARG HTTP_PASSWORD

# --------------------------------
# SET USERS, ACCESS
# --------------------------------

# Create a non-privileged user to run the service.
RUN groupadd --gid 999 ${USER} \
    && useradd --uid 1001 --gid 999 --create-home ${USER}

# Running instance should own the code, as task automation leads to changes.
COPY . ${WD}
RUN chown -R ${USER}:${USER} ${WD}

USER root
WORKDIR ${WD}
COPY . .

FROM stage-basic AS stage1

# --------------------------------
# INSTALL EXTRAS
# --------------------------------

# install curl + xz-unzip
RUN apt-get clean
RUN apt-get update
RUN apt-get install -y curl xz-utils
RUN apt-get clean

# zig (for cargo-zigbuild)
RUN curl -sS https://webi.sh/zig | sh
ENV PATH "~/.local/bin:$PATH"
ENV PATH "~/.local/opt/zig:$PATH"
RUN bash -c "zig version"

# just, zigbuild (for crossplatform compilation in rust!)
RUN cargo install --locked just
RUN cargo install --locked cargo-zigbuild

FROM stage1 AS stage2

# --------------------------------
# PROJECT BUILD
# --------------------------------

RUN just setup
RUN echo "\n\
ARTEFACT_NAME=\"examplerust\"\n\
PROJECT_NAME=\"${APP}\"\n\
HTTP_IP=\"${HTTP_IP}\"\n\
HTTP_PORT=${HTTP_PORT}\n\
HTTP_USER=\"${HTTP_USER}\"\n\
HTTP_PASSWORD=\"${HTTP_PASSWORD}\"\n\
ARCHITECTURE=\"x86_64-unknown-linux-musl\"\n\
" > .env
RUN just build

FROM stage2 AS stage3

# ----------------------------------------------------------------
# BUILD STAGE 1
# ----------------------------------------------------------------

FROM stage3 AS stage-build
