# machine

This is a launcher for [glevine/mac-dev-playbook](https://github.com/glevine/mac-dev-playbook). It provides a means for further extending [geerlingguy/mac-dev-playbook](https://github.com/geerlingguy/mac-dev-playbook), automating and documenting the full setup, and repeatedly running the plays to ensure that the machine stays the way I like it.

## pre-requisites

1. Sign into iCloud.
2. Sign into the App Store.
3. Grant full disk access to Terminal.app.
    1. Open `System Settings`.
    2. Click `Privacy & Security`.
    3. Click `Full Disk Access`.
    4. Enable access for `Terminal`.
4. Open a terminal.

## build it

```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/glevine/machine/HEAD/bin/mac)"
```

> **Would you like to make all targets? [y/n]**
>
> Choose `y` to install the machine and additional tools. Choose `n` to only make the machine.

## update it

The following assumes that `$HOME/.machine/bin` is in the PATH.

```shell
mac
```

## wrap up

```shell
# Copy your SSH key to your clipboard.
pbcopy < "$HOME/.ssh/id_ed25519.pub"
```

[Add your SSH key](https://github.com/settings/ssh/new) to Github.

## additional installations

```shell
# install it all
mac all

# install multiverse
mac multiverse

# install sugarconnect
mac sugarconnect

# make multiple targets
mac multiverse sugarconnect
```
