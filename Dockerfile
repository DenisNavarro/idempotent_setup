FROM docker.io/library/debian:bookworm-slim AS base
WORKDIR /work
COPY common.bash /work/
RUN sed -i 's/sudo //g' common.bash

#######################################
# Check setup.bash without subscripts #
#######################################

# Without subscripts, `setup.bash` must print nothing to stdout and stderr.

FROM base AS setup_0
COPY setup.bash /work/
RUN set -eux; bash -c 'out="$(bash setup.bash 2>&1)" && [ -z "$out" ]'

##########
# Caches #
##########

FROM base AS jaq
COPY target_state.yaml /work/
RUN set -eux; \
    bash -c 'source common.bash && ensure_jaq_is_available'; \
    bash -c 'out="$(bash -c "source common.bash && ensure_jaq_is_available" 2>&1)" && [ -z "$out" ]'; \
    bash -c 'source common.bash && clean_cargo_cache'; \
    cat current_state.yaml

FROM jaq AS pixi
RUN set -eux; \
    bash -c 'source common.bash && ensure_pixi_is_available'; \
    bash -c 'out="$(bash -c "source common.bash && ensure_pixi_is_available" 2>&1)" && [ -z "$out" ]'; \
    bash -c 'source common.bash && clean_cargo_cache'; \
    cat current_state.yaml

FROM pixi AS opam
COPY opam_utils.bash pixi.toml pixi.lock /work/
RUN set -eux; \
    bash -c 'source opam_utils.bash && ensure_opam_packages_are_available'; \
    bash -c 'out="$(bash -c "source opam_utils.bash && ensure_opam_packages_are_available" 2>&1)" && [ -z "$out" ]'; \
    bash -c 'source common.bash && clean_pixi_cache'; \
    cat current_state.yaml

########################################
# Check setup.bash and its idempotency #
########################################

# The second call to `setup.bash` must print nothing to stdout and stderr.

# Each image starts from `base`, `jaq`, `pixi` or `opam`.
# `FROM jaq AS setup_X` and `FROM pixi AS setup_X` could be replaced with:
#   FROM base AS setup_X
#   COPY target_state.yaml /work/
# and `FROM opam AS setup_X` could be replaced with:
#   FROM base AS setup_X
#   COPY target_state.yaml opam_utils.bash pixi.toml pixi.lock /work/
# but this would increase build time.

FROM base AS setup_1
COPY ensure_hardlinks_are_up_to_date.bash setup.bash /work/
COPY hardlinks /work/hardlinks
RUN set -eux; \
    bash setup.bash; \
    bash -c 'out="$(bash setup.bash 2>&1)" && [ -z "$out" ]'

FROM base AS setup_2
COPY ensure_some_apt_packages_are_installed.bash setup.bash /work/
RUN set -eux; \
    bash setup.bash; \
    bash -c 'out="$(bash setup.bash 2>&1)" && [ -z "$out" ]'

FROM jaq AS setup_3
COPY target_fish_fresh.yaml setup.bash sync.bash /work/
RUN set -eux; \
    bash setup.bash; \
    bash -c 'out="$(bash setup.bash 2>&1)" && [ -z "$out" ]'; \
    bash -c 'source common.bash && clean_cargo_cache'; \
    cat current_state.yaml; \
    cat current_fish_fresh.yaml

FROM pixi AS setup_4
COPY setup.bash sync.bash sync_state.bash /work/
RUN set -eux; \
    bash setup.bash; \
    bash -c 'out="$(bash setup.bash 2>&1)" && [ -z "$out" ]'; \
    bash -c 'source common.bash && clean_cargo_cache && clean_pixi_cache'; \
    cat current_state.yaml

FROM pixi AS setup_5
COPY target_pixi_uv.yaml setup.bash sync.bash pixi.toml pixi.lock /work/
RUN set -eux; \
    bash setup.bash; \
    bash -c 'out="$(bash setup.bash 2>&1)" && [ -z "$out" ]'; \
    bash -c 'source common.bash && clean_pixi_cache'; \
    cat current_state.yaml; \
    cat current_pixi_uv.yaml

FROM pixi AS setup_6
COPY target_cargo_install_1.yaml setup.bash sync.bash pixi.toml pixi.lock /work/
RUN set -eux; \
    bash setup.bash; \
    bash -c 'out="$(bash setup.bash 2>&1)" && [ -z "$out" ]'; \
    bash -c 'source common.bash && clean_cargo_cache'; \
    cat current_state.yaml; \
    cat current_cargo_install_1.yaml

FROM jaq AS setup_7
COPY target_cargo_install_2.yaml setup.bash sync.bash /work/
RUN set -eux; \
    bash setup.bash; \
    bash -c 'out="$(bash setup.bash 2>&1)" && [ -z "$out" ]'; \
    bash -c 'source common.bash && clean_cargo_cache'; \
    cat current_state.yaml; \
    cat current_cargo_install_2.yaml

FROM pixi AS setup_8
COPY target_cargo_install_3.yaml setup.bash sync.bash pixi.toml pixi.lock /work/
RUN set -eux; \
    bash setup.bash; \
    bash -c 'out="$(bash setup.bash 2>&1)" && [ -z "$out" ]'; \
    bash -c 'source common.bash && clean_cargo_cache'; \
    cat current_state.yaml; \
    cat current_cargo_install_3.yaml

FROM base AS setup_9
COPY ensure_lean_is_installed.bash setup.bash /work/
RUN set -eux; \
    bash setup.bash; \
    bash -c 'out="$(bash setup.bash 2>&1)" && [ -z "$out" ]'; \
    bash -c 'PATH="$PATH:$HOME/.elan/bin" elan --version'; \
    bash -c 'PATH="$PATH:$HOME/.elan/bin" elan toolchain list'; \
    bash -c 'PATH="$PATH:$HOME/.elan/bin" lake --version'

FROM opam AS setup_10
COPY ensure_rocq_is_installed.bash setup.bash /work/
RUN set -eux; \
    bash setup.bash; \
    bash -c 'out="$(bash setup.bash 2>&1)" && [ -z "$out" ]'; \
    cat current_state.yaml; \
    bash -c 'PATH="$HOME/.pixi/bin:$PATH" opam pin list'

FROM opam AS setup_11
COPY ensure_framac_is_installed.bash setup.bash /work/
RUN set -eux; \
    bash setup.bash; \
    bash -c 'out="$(bash setup.bash 2>&1)" && [ -z "$out" ]'; \
    cat current_state.yaml; \
    bash -c 'PATH="$HOME/.pixi/bin:$PATH" opam pin list'

FROM pixi AS setup_extra
COPY target_extra.yaml setup.bash sync.bash pixi.toml pixi.lock /work/
RUN set -eux; \
    bash setup.bash; \
    bash -c 'out="$(bash setup.bash 2>&1)" && [ -z "$out" ]'; \
    bash -c 'source common.bash && clean_cargo_cache'; \
    cat current_state.yaml; \
    cat current_extra.yaml
