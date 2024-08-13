SHELL := /bin/zsh

.DEFAULT_GOAL := default
.DELETE_ON_ERROR:

MACHINE_HOME := $(HOME)/.machine
GITHUB_USERNAME := glevine

.PHONY: default
default: machine clean

.PHONY: all
all: machine mango multiverse clean

.PHONY: deps
deps:
	# Update all software.
	sudo softwareupdate -i -a -R

	# TODO: I think this is redundant because it is done by osx-command-line-tools.
	# Install Apple's command line tools.
	#if ! command -v xcode-select &> /dev/null; then xcode-select --install; fi

	# Accept the Xcode license agreement.
	if command -v xcodebuild &> /dev/null; then sudo xcodebuild -license accept; fi

	# Install homebrew.
	# Ansible can do this but pipx is needed to install Ansible and pipx is installed through homebrew. Let's just install Ansible with homebrew.
	if ! command -v brew &> /dev/null; then sh -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; else brew update; fi

	# Install mac-dev-playbook.
	git -C $(MACHINE_HOME) submodule update --init --recursive --remote --rebase

.PHONY: ansible
ansible: deps
	# Prevent the Too Many Open Files error.
	sudo launchctl limit maxfiles unlimited

	# Install Ansible.
	if ! command -v ansible &> /dev/null; then brew install ansible; else brew upgrade ansible; fi

.PHONY: machine
machine: ansible
	# Upgrade all homebrew packages.
	# Ansible can do this but geerlingguy/ansible-collection-mac doesn't expose options like --greedy.
	if command -v brew &> /dev/null; then brew update; brew upgrade; fi

	# Install oh-my-zsh.
	if [[ -z "$$ZSH" ]]; then sh -c "$$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; else ZSH="$$ZSH" command zsh -f "$$ZSH/tools/upgrade.sh"; fi

	# Install playbook dependencies.
	cd mac-dev-playbook; ansible-galaxy install -r requirements.yml

	# Execute the playbook.
	cd mac-dev-playbook; ansible-playbook main.yml -i inventory --ask-become-pass

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

.PHONY: mango
mango: MANGO_HOME := $(HOME)/github.com/sugarcrm/Mango
mango:
	# Clone mango.
	if [[ ! -d $(MANGO_HOME) ]]; then git clone --recurse-submodules --remote-submodules -o upstream git@github.com:sugarcrm/Mango.git $(MANGO_HOME); fi

	# Install any submodules.
	git -C $(MANGO_HOME) submodule update --init --recursive --remote --rebase

	# Add fork as origin.
	if ! git -C $(MANGO_HOME) remote | grep -q "^origin$$"; then git -C $(MANGO_HOME) remote add origin git@github.com:$(GITHUB_USERNAME)/Mango.git; fi

.PHONY: multiverse
multiverse: MULTIVERSE_HOME := $(HOME)/github.com/sugarcrm/multiverse
multiverse: EMAIL := $$(whoami)@sugarcrm.com
multiverse: MULTIVERSE_TOOLS_BIN := $(MULTIVERSE_HOME)/tools/bin
multiverse: TERRAFORM_HOME := $(HOME)/github.com/sugarcrm/ops-terraform-nosilo
multiverse:
	# Clone multiverse.
	if [[ ! -d $(MULTIVERSE_HOME) ]]; then git clone --recurse-submodules --remote-submodules -o upstream git@github.com:sugarcrm/multiverse.git $(MULTIVERSE_HOME); fi

	# Install any submodules.
	git -C $(MULTIVERSE_HOME) submodule update --init --recursive --remote --rebase

	# Add fork as origin.
	if ! git -C $(MULTIVERSE_HOME) remote | grep -q "^origin$$"; then git -C $(MULTIVERSE_HOME) remote add origin git@github.com:$(GITHUB_USERNAME)/multiverse.git; fi

	# Install bazelisk.
	if ! command -v bazelisk &> /dev/null; then brew install bazelisk; else brew upgrade bazelisk; fi

	# Test bazel installation.
	cd $(MULTIVERSE_HOME); bazel info; ./build/make-rules/diagnostics.sh

	# Build multiverse.
	cd $(MULTIVERSE_HOME); make go-link-stubs; make go-mod

	# Install scloud.
	if ! command -v scloud &> /dev/null; then wget -q --show-progress -O $(HOME)/bin/scloud https://jenkins.service.sugarcrm.com/job/multiverse/job/monorepo/job/master/lastSuccessfulBuild/artifact/artifacts/bin/scloud-darwin-amd64; chmod +x $(HOME)/bin/scloud; else scloud update; fi

	# Log into kubernetes clusters.
	if [[ $$($(MULTIVERSE_TOOLS_BIN)/kubectl config view | grep -q "contexts: null")$$? -eq 0 ]]; then scloud kubeconfig setup; else; scloud kubeconfig sync --email $(EMAIL); fi

	# Log into quay.io.
	# Note: Generate encrypted Docker CLI password at https://quay.io/user/$$(whoami)?tab=settings.
	if ! grep -q quay.io $(HOME)/.docker/config.json; then IFS= read -rs 'password?quay.io password: ' </dev/tty && printf '%s' "$${password}" | docker login -u="$$(whoami)" --password-stdin quay.io; fi

	# Configure AWS CLI for use with sugararch account.
	# Note: Create access key as described at https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html. Or, copy an access key from ~/.aws/credentials and transfer it to another machine to use an existing access key.
	if ! grep -q $(EMAIL) $(HOME)/.aws/config || ! grep -q $(EMAIL) $(HOME)/.aws/credentials; then aws configure --profile $(EMAIL); fi

	# Configure skaffold.
	$(MULTIVERSE_TOOLS_BIN)/skaffold config set -g update-check false
	$(MULTIVERSE_TOOLS_BIN)/skaffold config set -g --survey disable-prompt true
	$(MULTIVERSE_TOOLS_BIN)/skaffold config set -g collect-metrics false

	# Clone ops-terraform-nosilo.
	if [[ ! -d $(TERRAFORM_HOME) ]]; then git clone --recurse-submodules --remote-submodules -o upstream git@github.com:sugarcrm/ops-terraform-nosilo.git $(TERRAFORM_HOME); fi

	# Install any submodules.
	git -C $(TERRAFORM_HOME) submodule update --init --recursive --remote --rebase

	# Add fork as origin.
	if ! git -C $(TERRAFORM_HOME) remote | grep -q "^origin$$"; then git -C $(TERRAFORM_HOME) remote add origin git@github.com:$(TERRAFORM_HOME)/ops-terraform-nosilo.git; fi

define CADENCE_IDE_WORKSPACE_SETTINGS
{
	"python.pythonPath": "$${env:HOME}/.pyenv/versions/$(PYTHON_VERSION)/envs/sugarconnect@$(PYTHON_VERSION)/bin/python"
}
endef
export CADENCE_IDE_WORKSPACE_SETTINGS
define CADENCE_IDE_DEBUG_SETTINGS
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Webserver",
            "type": "python",
            "request": "launch",
            "justMyCode": false,
            "program": "$${workspaceFolder}/backend/main/src/manage.py",
            "console": "integratedTerminal",
            "args": [
                "runsslserver",
                "0.0.0.0:28081",
                "--noreload",
                "--nothreading"
            ],
            "env": {
                "DJANGO_SETTINGS_MODULE": "config.settings.debug"
            },
            "django": true
        },
        {
            "name": "Celery Worker",
            "type": "python",
            "request": "launch",
            "program": "$${env:HOME}/.pyenv/versions/$(PYTHON_VERSION)/envs/sugarconnect@$(PYTHON_VERSION)/bin/celery",
            "console": "integratedTerminal",
            "cwd": "$${workspaceFolder}/backend/main/src",
            "args": [
                "--app=config.celery:app",
                "worker",
                "--loglevel=DEBUG",
                "-O",
                "fair",
                "-P",
                "solo"
            ],
            "env": {
                "DJANGO_SETTINGS_MODULE": "config.settings.debug"
            }
        },
        {
            "name": "Refresh SA Tokens",
            "type": "python",
            "request": "launch",
            "justMyCode": false,
            "program": "$${workspaceFolder}/backend/main/src/manage.py",
            "console": "integratedTerminal",
            "args": [
                "refresh_sa_tokens"
            ],
            "env": {
                "DJANGO_SETTINGS_MODULE": "config.settings.debug"
            },
            "django": true
        },
        {
            "name": "Shell Plus",
            "type": "python",
            "request": "launch",
            "justMyCode": false,
            "program": "$${workspaceFolder}/backend/main/src/manage.py",
            "console": "integratedTerminal",
            "args": [
                "shell_plus",
                "--ipython"
            ],
            "env": {
                "DJANGO_SETTINGS_MODULE": "config.settings.debug"
            },
            "django": true
        },
        {
            "name": "Integration Tests",
            "type": "python",
            "request": "launch",
            "justMyCode": false,
			"cwd": "$${workspaceFolder}",
            "program": "pytest",
            "console": "integratedTerminal",
            "args": [
            ],
            "env": {
                "DJANGO_SETTINGS_MODULE": "config.settings.debug"
            },
            "django": true
        }
    ]
}
endef
export CADENCE_IDE_DEBUG_SETTINGS
.PHONY: sugarconnect
sugarconnect: CADENCE_HOME := $(HOME)/github.com/sugarcrm/collabspot-cadence
sugarconnect: PYTHON_VERSION := 3.9.10
sugarconnect: NODEJS_VERSION := 14
sugarconnect:
	# Clone collabspot-cadence.
	if [[ ! -d $(CADENCE_HOME) ]]; then git clone --recurse-submodules --remote-submodules -o upstream git@github.com:sugarcrm/collabspot-cadence.git $(CADENCE_HOME); fi

	# Install any submodules.
	git -C $(CADENCE_HOME) submodule update --init --recursive --remote --rebase

	# Add fork as origin.
	if ! git -C $(CADENCE_HOME) remote | grep -q "^origin$$"; then git -C $(CADENCE_HOME) remote add origin git@github.com:$(GITHUB_USERNAME)/collabspot-cadence.git; fi

	# PostgreSQL is needed to compile psycopg. The database is actually run in Docker.
	if ! command -v postgres &> /dev/null; then brew install postgresql; else brew upgrade postgresql; fi

	# An empty access key satisfies the requirements.
	# The secret will be loaded from SUGAR_OAUTH_SA_CLIENT_SECRETS in custom_local.py.
	touch $(CADENCE_HOME)/backend/main/src/resources/local/sugar_connect_sa_secret

	# Add settings to custom_local.py.
	touch $(CADENCE_HOME)/backend/main/src/config/settings/custom_local.py
	if ! grep -Fxq "PUBLIC_TENANT_BASE_URL = 'clbspot.localhost.com:28081'" $(CADENCE_HOME)/backend/main/src/config/settings/custom_local.py; then echo "PUBLIC_TENANT_BASE_URL = 'clbspot.localhost.com:28081'" >> $(CADENCE_HOME)/backend/main/src/config/settings/custom_local.py; fi
	if ! grep -Fxq "PUBLIC_TENANT_BASE_URL_FULL = 'https://' + PUBLIC_TENANT_BASE_URL" $(CADENCE_HOME)/backend/main/src/config/settings/custom_local.py; then echo "PUBLIC_TENANT_BASE_URL_FULL = 'https://' + PUBLIC_TENANT_BASE_URL" >> $(CADENCE_HOME)/backend/main/src/config/settings/custom_local.py; fi
	if ! grep -Fxq "SESSION_COOKIE_DOMAIN = '.clbspot.localhost.com'" $(CADENCE_HOME)/backend/main/src/config/settings/custom_local.py; then echo "SESSION_COOKIE_DOMAIN = '.clbspot.localhost.com'" >> $(CADENCE_HOME)/backend/main/src/config/settings/custom_local.py; fi
	if ! grep -Fxq "HTTP_SCHEME = 'https'" $(CADENCE_HOME)/backend/main/src/config/settings/custom_local.py; then echo "HTTP_SCHEME = 'https'" >> $(CADENCE_HOME)/backend/main/src/config/settings/custom_local.py; fi
	if ! grep -Fxq "SUGAR_OAUTH_STS_SERVER = 'https://sts-stage.service.sugarcrm.com'" $(CADENCE_HOME)/backend/main/src/config/settings/custom_local.py; then echo "SUGAR_OAUTH_STS_SERVER = 'https://sts-stage.service.sugarcrm.com'" >> $(CADENCE_HOME)/backend/main/src/config/settings/custom_local.py; fi

	# Some settings must be added to $(CADENCE_HOME)/backend/main/src/config/settings/custom_local.py manually.
	# 	- SUGAR_OAUTH_CLIENT_ID
	# 	- SUGAR_OAUTH_SA_CLIENTS
	# 	- SUGAR_OAUTH_SA_CLIENT_SECRETS

	# Install Python.
	pyenv install -s $(PYTHON_VERSION)

	# Create a virtual environment.
	pyenv virtualenv -f $(PYTHON_VERSION) sugarconnect@$(PYTHON_VERSION)
	if ! grep -Fxq "export DJANGO_SETTINGS_MODULE=config.settings.debug" $(HOME)/.pyenv/versions/$(PYTHON_VERSION)/envs/sugarconnect@$(PYTHON_VERSION)/bin/activate; then echo "export DJANGO_SETTINGS_MODULE=config.settings.debug" >> $(HOME)/.pyenv/versions/$(PYTHON_VERSION)/envs/sugarconnect@$(PYTHON_VERSION)/bin/activate; fi

	# Enable automatic virtual environment activation.
	cd $(CADENCE_HOME); pyenv local sugarconnect@$(PYTHON_VERSION)

	# Install Python dependencies.
	cd $(CADENCE_HOME)/backend/main; python -m pip install --upgrade pip-tools; pip-compile requirements.in; pip-compile requirements-test.in; pip-compile requirements-dev.in; GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1 GRPC_PYTHON_BUILD_SYSTEM_ZLIB=1 pip-sync requirements.txt requirements-test.txt requirements-dev.txt

	# Install Node.js.
	volta install node@$(NODEJS_VERSION)

	# Install the latest npm.
	volta install npm

	# Configure Visual Studio Code.
	mkdir -p $(CADENCE_HOME)/.vscode
	echo "$$CADENCE_IDE_WORKSPACE_SETTINGS" > $(CADENCE_HOME)/.vscode/settings.json
	echo "$$CADENCE_IDE_DEBUG_SETTINGS" > $(CADENCE_HOME)/.vscode/launch.json

	# Add local hosts.
	if ! grep -Fxq "127.0.0.1 clbspot.localhost.com" /etc/hosts; then sudo -- sh -c "echo 127.0.0.1 clbspot.localhost.com >> /etc/hosts"; fi
	if ! grep -Fxq "127.0.0.1 sugarcrm.clbspot.localhost.com" /etc/hosts; then sudo -- sh -c "echo 127.0.0.1 sugarcrm.clbspot.localhost.com >> /etc/hosts"; fi

	# Build the application.
	cd $(CADENCE_HOME); make scratch

	# Link the portal.
	ln -sf $(CADENCE_HOME)/sugar-connect-portal/dist/sugar-connect-portal $(CADENCE_HOME)/backend/main/src/static/app

	# Connect the service account.
	cd $(CADENCE_HOME)/backend/main/src; python manage.py refresh_sa_tokens --settings=config.settings.debug
