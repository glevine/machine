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

# Make sure that command line tools are installed.
xcode-select --install
```

## install ansible

```shell
sudo easy_install pip

export PATH="$(python -c 'import site; print(site.USER_BASE + "/bin")'):$PATH"

pip install --user ansible
```

## download playbooks

```shell
mkdir -p "$HOME/github.com/glevine"

cd "$HOME/github.com/glevine"

git clone -o upstream https://github.com/glevine/machine.git
```

## execute playbook

```shell
cd "$HOME/github.com/glevine/machine"

ansible-playbook -K me.yml
```

## wrap up

```shell
# Replace the current shell with zsh so you don't have to restart the terminal.
env zsh -l
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

## modern.ie

It is a goal to create a role for modern.ie. Unfortunately, I haven't had any success automating it. Until then, manually run the following commands to install [IE 11 and Edge VMs](https://xdissent.github.io/ievms/). Install VirtualBox before proceeding.

```shell
curl -fsSL https://raw.githubusercontent.com/xdissent/ievms/master/ievms.sh | env IEVMS_VERSIONS="11 EDGE" bash

VBoxManage extpack install $HOME/.ievms/Oracle_VM_VirtualBox_Extension_Pack-*

curl -fsSL https://raw.githubusercontent.com/xdissent/ievms/master/ievms.sh | env IEVMS_VERSIONS="11 EDGE" bash
```

Or just [download the VMs](https://developer.microsoft.com/en-us/microsoft-edge/tools/vms/) from modern.ie.
