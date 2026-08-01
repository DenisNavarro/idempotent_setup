
Idempotent setup
================

[`setup.bash`][] is an idempotent script which installs dependencies on a Debian-like OS.

`setup.bash` synchronizes dotfiles and installs APT packages, Rust, Rust crates, `conda-forge`
recipes, PyPI packages and various tools related to formal proofs (Lean, Rocq and Frama-C).

`setup.bash` calls subscripts only when they exist so that you can cherry pick the subscripts to
download. The file dependencies are listed at the beginning of `setup.bash`.

The target YAML files allow to easily install, uninstall or update Rust crates, `conda-forge`
recipes and PyPI packages.

[`verify_setup.bash`][] executes `setup.bash` in various Debian images to verify its idempotency.

[`setup.bash`]: ./setup.bash
[`verify_setup.bash`]: ./verify_setup.bash
