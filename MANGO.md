# machine.mango

## virtualbox

[Reboot in recovery mode](https://support.apple.com/en-us/HT201314). Once in recovery mode, open Terminal from the Utilities menu and enter the following command:

```shell
spctl kext-consent add VB5E2TV963
```

Reboot in normal mode.

The Mango stacks require [VirtualBox 5.2](https://www.virtualbox.org/wiki/Download_Old_Builds_5_2). Download the [VirtualBox 5.2.30 installer](https://download.virtualbox.org/virtualbox/5.2.30/VirtualBox-5.2.30-130521-OSX.dmg) and its [extension pack](https://download.virtualbox.org/virtualbox/5.2.30/Oracle_VM_VirtualBox_Extension_Pack-5.2.30.vbox-extpack).

## execute playbook

```shell
cd "$HOME/github.com/glevine/machine"

ansible-playbook -K mango.yml
```

## wrap up

```shell
brew doctor
```

Follow suggestions by Homebrew.

Use `git psr2` to check staged code for PSR-2 compliance.

## rome

Use [rome](https://github.com/jwhitcraft/rome) to build Mango. `rome` can also watch for source code changes and recompile files.

```shell
rome build --clean -d $HOME/www/mango/ -f ent -v 9.0.0 $HOME/github.com/sugarcrm/Mango/sugarcrm

rome watch --clean-cache -d $HOME/www/mango/ -f ult -v 9.0.0 $HOME/github.com/sugarcrm/Mango/sugarcrm
```

`rome2stack` wraps `rome` to build Mango on a QA stack.

```shell
# Build the current Mango branch to the php73-mysql57 stack and compile changes.
cd $HOME/github.com/sugarcrm/stacks/php73-mysql57

rome2stack -f ent -v 9.0.0

rome watch --clean-cache -d $HOME/www/mango/ -f ult -v 9.0.0 $HOME/github.com/sugarcrm/Mango/sugarcrm
```

After building Mango on a QA stack, you can reach it at [http://localhost:8080/dev](http://localhost:8080/dev).

Use `localhost:9900` for remote debugging.

Connect to the MySQL server using `mysql -u sugar -psugar -h 127.0.0.1 -P 8306`.

Install the [elasticsearch head plugin](https://chrome.google.com/webstore/detail/elasticsearch-head/ffmkiejjmecolpfloofpjologoblkegm). Use `localhost:8954`.
