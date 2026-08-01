#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

source opam_utils.bash
fn=pin_in_env_if_opam_package_is_not_pinned_to

$fn gmp-make-pkgconfig rocq-core 9.0.0
$fn gmp-make-pkgconfig rocq-prover 9.0.0
$fn gmp-make-pkgconfig vscoq-language-server 2.2.6
