<div align="center">

# asdf-sourcery ![Build](https://github.com/younke/asdf-sourcery/workflows/Build/badge.svg) ![Lint](https://github.com/younke/asdf-sourcery/workflows/Lint/badge.svg)

[Sourcery](https://github.com/krzysztofzablocki/Sourcery) plugin for the [asdf version manager](https://asdf-vm.com).

</div>

# Contents

- [Dependencies](#dependencies)
- [Install](#install)
- [Why?](#why)
- [Contributing](#contributing)
- [License](#license)

# Dependencies

- `bash`, `curl`, `unzip`: generic POSIX utilities.

# Install

Plugin:

```shell
asdf plugin add sourcery
# or
asdf plugin add sourcery https://github.com/younke/asdf-sourcery.git
```

sourcery:

```shell
# Show all installable versions
asdf list-all sourcery

# Install specific version
asdf install sourcery latest

# Set a version globally (on your ~/.tool-versions file)
asdf global sourcery latest

# Now sourcery commands are available
sourcery --help
```

:warning: Refer to [Sourcery docs](https://github.com/krzysztofzablocki/Sourcery) on how to use templates.

Use `$ asdf where sourcery` to locate install path. You can find bundled templates in `Templates` folder.


Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to
install & manage versions.

# Contributing

Contributions of any kind welcome! See the [contributing guide](contributing.md).

[Thanks goes to these contributors](https://github.com/younke/asdf-sourcery/graphs/contributors)!

# License

See [LICENSE](LICENSE) © [Vasily Ptitsyn](https://github.com/younke/)
