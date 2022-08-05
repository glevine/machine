SHELL := /bin/zsh

.DEFAULT_GOAL := all
.DELETE_ON_ERROR:

MACHINE_HOME := $(HOME)/.machine

.PHONY: all
all: machine clean

.PHONY: deps
deps:
	# Update all software.
	sudo softwareupdate -i -a -R

	# TODO: I think this is redundant because it is done by osx-command-line-tools.
	# Install Apple's command line tools.
	#if ! command -v xcode-select &> /dev/null; then xcode-select --install; fi

	# Accept the Xcode license agreement.
	if command -v xcodebuild &> /dev/null; then sudo xcodebuild -license accept; fi

	# Install mac-dev-playbook.
	git -C $(MACHINE_HOME) submodule update --init --recursive --remote --rebase

.PHONY: ansible
ansible: deps
	# Prevent the Too Many Open Files error.
	sudo launchctl limit maxfiles unlimited

	# Install pip.
	python3 -m pip install --upgrade --user pip

	# Install Ansible.
	python3 -m pip install --upgrade --user ansible

.PHONY: machine
machine: ansible
	# Upgrade all homebrew packages.
	# Ansible can do this but geerlingguy/ansible-collection-mac doesn't expose options like --ignore-pinned and --greedy.
	if command -v brew &> /dev/null; then brew update; brew upgrade --ignore-pinned; fi

	# Install oh-my-zsh.
	if [[ -z "$$ZSH" ]]; then sh -c "$$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; else ZSH="$$ZSH" command zsh -f "$$ZSH/tools/upgrade.sh"; fi

	# Install playbook dependencies.
	cd mac-dev-playbook; $$(python3 -m site --user-base)/bin/ansible-galaxy install -r requirements.yml

	# Execute the playbook.
	cd mac-dev-playbook; $$(python3 -m site --user-base)/bin/ansible-playbook main.yml -i inventory --ask-become-pass

	# Install useful key bindings and fuzzy completion for fzf.
	if command -v brew &> /dev/null; then $$(brew --prefix)/opt/fzf/install; fi

	# TODO: make sure the ssh-agent is running, if you can

.PHONY: clean
clean:
	# Follow suggestions by Homebrew.
	brew doctor || true

	# Replace the current shell with zsh.
	# source: https://github.com/ohmyzsh/ohmyzsh/commit/73f29087f99e2e6630dcc5954db1240e8c885147
	exec zsh -l
	which zsh
	zsh --version

.PHONY: multiverse
multiverse: MULTIVERSE_HOME := $(HOME)/github.com/sugarcrm/multiverse
multiverse: GIT_UPSTREAM := git@github.com:sugarcrm/multiverse.git
multiverse: GIT_ORIGIN := git@github.com:glevine/multiverse.git
multiverse: EMAIL := $$(whoami)@sugarcrm.com
multiverse:
	# Clone multiverse.
	if [[ ! -d $(MULTIVERSE_HOME) ]]; then git clone --recurse-submodules --remote-submodules -o upstream $(GIT_UPSTREAM) $(MULTIVERSE_HOME); fi

	# Install any submodules.
	git -C $(MULTIVERSE_HOME) submodule update --init --recursive --remote --rebase

	# Add fork as origin.
	if ! git -C $(MULTIVERSE_HOME) remote | grep -q "^origin$$"; then git -C $(MULTIVERSE_HOME) remote add origin $(GIT_ORIGIN); fi

	# Install bazelisk.
	if ! command -v bazelisk &>/dev/null; then brew install bazelisk; else brew upgrade bazelisk; fi

	# rules_docker requires python2. python2 is not present on macOS 12. As a workaround until multiverse uses rules_docker-0.24.0, the following installs python2 and prioritizes python3 globally. Once python2 is no longer necessary, unset it with:
	# pyenv global system; pyenv uninstall 3.10.6; pyenv uninstall 2.7.18;
	pyenv install -s 3.10.6
	pyenv install -s 2.7.18
	pyenv global 3.10.6 2.7.18

	# Test bazel installation.
	cd $(MULTIVERSE_HOME); bazel info; make diagnostics

	# Build multiverse.
	cd $(MULTIVERSE_HOME); make go-link-stubs; make go-mod

	# Install scloud.
	if ! command -v scloud &>/dev/null; then wget -q --show-progress -O $(MULTIVERSE_HOME)/bin/scloud https://jenkins.service.sugarcrm.com/job/multiverse/job/monorepo/job/master/1244/artifact/artifacts/bin/scloud-darwin-amd64; chmod +x $(MULTIVERSE_HOME)/bin/scloud; fi

	# scloud can't be updated until https://sugarcrm.atlassian.net/browse/IDM-2719 is fixed.
	# Once fixed, replace the above command with:
	# if ! command -v scloud &>/dev/null; then wget -q --show-progress -O $(MULTIVERSE_HOME)/bin/scloud https://jenkins.service.sugarcrm.com/job/multiverse/job/monorepo/job/master/lastSuccessfulBuild/artifact/artifacts/bin/scloud-darwin-amd64; chmod +x $(MULTIVERSE_HOME)/bin/scloud; else scloud update; fi

	# Show scloud version.
	scloud version

	# Log into kubernetes clusters.
	if [[ $$(kubectl config view | grep -q "contexts: null")$$? -eq 0 ]]; then scloud kubeconfig setup; else; scloud kubeconfig sync --email $(EMAIL); fi

	# Log into quay.io.
	# Note: Generate encrypted Docker CLI password at https://quay.io/user/$$(whoami)?tab=settings.
	if ! grep -q quay.io $(HOME)/.docker/config.json; then IFS= read -rs 'password?quay.io password: ' </dev/tty && printf '%s' "$${password}" | docker login -u="$$(whoami)" --password-stdin quay.io; fi

	# Configure AWS CLI for use with sugararch account.
	# Note: Create access key as described at https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html. Or, copy an access key from ~/.aws/credentials and transfer it to another machine to use an existing access key.
	if ! grep -q $(EMAIL) $(HOME)/.aws/config || ! grep -q $(EMAIL) $(HOME)/.aws/credentials; then aws configure --profile $(EMAIL); fi
