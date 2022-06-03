# machine

This is a launcher for [glevine/mac-dev-playbook](https://github.com/glevine/mac-dev-playbook). It provides a means for further extending [geerlingguy/mac-dev-playbook](https://github.com/geerlingguy/mac-dev-playbook), automating and documenting the full setup, and repeatedly running the plays to ensure that the machine stays the way I like it.

## pre-requisites

1. Sign into iCloud.
2. Sign into the App Store.
3. Open a terminal.

## build it

```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/glevine/machine/HEAD/bin/machine)"
```

## update it

The following assumes that `$HOME/.machine/bin` is in the PATH.

```shell
mac
```

## wrap up

```shell
# Copy your SSH key to your clipboard.
pbcopy <"$HOME/.ssh/id_rsa.pub"
```

[Add your SSH key](https://github.com/settings/ssh/new) to Github.
