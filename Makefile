SHELL := /bin/bash

.DEFAULT_GOAL := all
.DELETE_ON_ERROR:

MACHINE_HOME := $(HOME)/.machine

.PHONY: all
all: build clean

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

.PHONY: build
build: ansible
	# Upgrade all homebrew packages.
	# Ansible can do this but geerlingguy/ansible-collection-mac doesn't expose options like --ignore-pinned and --greedy.
	if command -v brew &> /dev/null; then brew update; brew upgrade --ignore-pinned; fi

	# Install oh-my-zsh.
	if ! command -v omz &> /dev/null; then sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; else omz update --unattended; fi

	# Install playbook dependencies.
	cd mac-dev-playbook; $(python3 -m site --user-site)/ansible-galaxy install -r requirements.yml

	# Execute the playbook.
	cd mac-dev-playbook; $(python3 -m site --user-site)/ansible-playbook main.yml -i inventory --ask-become-pass

	# Install useful key bindings and fuzzy completion for fzf.
	if command -v brew &> /dev/null; then $(brew --prefix)/opt/fzf/install; fi

	# TODO: make sure the ssh-agent is running, if you can

.PHONY: clean
clean:
	# Follow suggestions by Homebrew.
	brew doctor
