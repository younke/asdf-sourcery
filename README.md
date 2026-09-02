<div align="center">

# asdf-sourcery 

[![Build](https://github.com/younke/asdf-sourcery/actions/workflows/build.yml/badge.svg)](https://github.com/younke/asdf-sourcery/actions/workflows/build.yml) [![Lint](https://github.com/younke/asdf-sourcery/actions/workflows/lint.yml/badge.svg)](https://github.com/younke/asdf-sourcery/actions/workflows/lint.yml) [![Mise](https://github.com/younke/asdf-sourcery/actions/workflows/test-mise.yml/badge.svg)](https://github.com/younke/asdf-sourcery/actions/workflows/test-mise.yml)

[sourcery](https://krzysztofzablocki.github.io/Sourcery/) plugin for the [asdf](https://asdf-vm.com) and [mise](https://mise.jdx.dev) version managers.

</div>

# Contents

- [Dependencies](#dependencies)
- [Install](#install)
- [Contributing](#contributing)
- [License](#license)

# Dependencies

- `bash`, `curl`, `git`, `tar` (with `xz` support), `unzip`, and
  [POSIX utilities](https://pubs.opengroup.org/onlinepubs/9699919799/idx/utilities.html).
- On Linux: a x86_64 host and a Swift 5.10 runtime on the library path. Upstream
  publishes a single dynamically linked Linux binary, built on Ubuntu 22.04, so
  the Swift runtime libraries have to be installed separately — see
  [swift.org/install](https://www.swift.org/install/linux/). Older releases have
  no Linux binary at all.
- Set `GITHUB_API_TOKEN` (or `GITHUB_TOKEN`) to avoid hitting the anonymous
  GitHub API rate limit when resolving Linux downloads.

# Install

## asdf

Requires [asdf](https://github.com/asdf-vm/asdf) 0.16 or newer.

Plugin:

```shell
asdf plugin add sourcery
# or
asdf plugin add sourcery https://github.com/younke/asdf-sourcery.git
```

sourcery:

```shell
# Show all installable versions
asdf list all sourcery

# Install specific version
asdf install sourcery latest

# Set a version globally (on your ~/.tool-versions file)
asdf set -u sourcery latest

# Now sourcery commands are available
sourcery --help
```

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to
install & manage versions.

## mise

[mise](https://mise.jdx.dev) runs this plugin through its asdf backend:

```shell
# Install and use the latest version
mise use -g asdf:https://github.com/younke/asdf-sourcery@latest

# Or run it without installing it globally
mise exec asdf:https://github.com/younke/asdf-sourcery@latest -- sourcery --version
```

# Contributing

Contributions of any kind welcome! See the [contributing guide](contributing.md).

[Thanks goes to these contributors](https://github.com/younke/asdf-sourcery/graphs/contributors)!

# License

See [LICENSE](LICENSE) © [Vasily Ptitsyn](https://github.com/younke/)
