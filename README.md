# machine

## pre-requisites

1. Sign into iCloud.
2. Sign into the App Store and install Xcode.
3. Open a terminal.

```shell
# Update all software.
sudo softwareupdate -i -a -R

# Prevent the Too Many Open Files error.
sudo launchctl limit maxfiles unlimited

# Accept the Xcode license agreement.
sudo xcodebuild -license accept
```

## install ansible

```shell
sudo easy_install pip

export PATH="$(python -c 'import site; print(site.USER_BASE + "/bin")'):$PATH"

pip install --user ansible
```

## download playbooks

```shell
git clone -o upstream https://github.com/glevine/machine.git "$HOME/github.com/glevine/machine"
```

## execute playbook

```shell
cd "$HOME/github.com/glevine/machine"

ansible-playbook -K me.yml
```

## wrap up

```shell
# Replace the current shell so you don't have to restart the terminal.
env bash -l
```

```shell
# Copy your SSH key to your clipboard.
pbcopy <"$HOME/.ssh/id_rsa.pub"
```

[Add your SSH key](https://github.com/settings/ssh/new) to Github.

```shell
brew doctor
```

Follow suggestions by Homebrew.

## more machines

[sugar](SUGAR.md)
