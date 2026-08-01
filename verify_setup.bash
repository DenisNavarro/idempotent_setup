#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

for n in {0..11}; do
    echo + podman build -t setup_"$n"_from_idempotent_setup --target=setup_"$n" .
    podman build -t setup_"$n"_from_idempotent_setup --target=setup_"$n" .
done

# In practice, `target_extra.yaml` allows to check if a new crate compiles inside a container
# without recompiling the other crates.
if [ -f target_extra.yaml ]; then
    echo + podman build -t setup_extra_from_idempotent_setup --target=setup_extra .
    podman build -t setup_extra_from_idempotent_setup --target=setup_extra .
fi

set -x
podman image prune -f
