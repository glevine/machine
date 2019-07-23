# machine.sugar

## execute playbook

```shell
cd "$HOME/github.com/glevine/machine"

ansible-playbook -K sugar.yml
```

## wrap up

```shell
brew doctor
```

Follow suggestions by Homebrew.

Install [Microsoft Office](https://portal.office.com/account#installs).

## more machines

[mango](MANGO.md)

[multiverse](MULTIVERSE.md)

## modern.ie

It is a goal to create a role for modern.ie. Unfortunately, I haven't had any success automating it. Until then, manually run the following commands to install [IE 11 and Edge VMs](https://xdissent.github.io/ievms/). Install VirtualBox before proceeding.

```shell
curl -fsSL https://raw.githubusercontent.com/xdissent/ievms/master/ievms.sh | env IEVMS_VERSIONS="11 EDGE" bash

VBoxManage extpack install $HOME/.ievms/Oracle_VM_VirtualBox_Extension_Pack-*

curl -fsSL https://raw.githubusercontent.com/xdissent/ievms/master/ievms.sh | env IEVMS_VERSIONS="11 EDGE" bash
```

Or just [download the VMs](https://developer.microsoft.com/en-us/microsoft-edge/tools/vms/) from modern.ie.
