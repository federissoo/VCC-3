define RUN_ANSIBLE
( \
	export ANSIBLE_LOG_PATH=$(ANSIBLE_LOG_PATH); \
	. $(VENV_PATH)/bin/activate; \
	ansible-playbook -i $(INVENTORY) $(VAULT_OPT) $(ARGS) playbook.yml; \
)
endef

#
# Configurable variables
#

# Path to the Python virtual environment
VENV_PATH ?= /home/vagrant/.venv

# Ansible log path
ANSIBLE_LOG_PATH ?= log/ansible.log

# Name of the inventory file
INVENTORY ?= inventory

USEVAULT ?= 0

ifeq ($(USEVAULT),1)
VAULT_OPT := --ask-vault-pass
else
VAULT_OPT :=
endif

default: setup-all

#
# Python environment
#

.venv:
	python3 -m venv $(VENV_PATH)

.PHONY: python-setup
python-setup: .venv
	. $(VENV_PATH)/bin/activate \
		&& pip install --upgrade pip \
		&& pip install -r requirements.txt \
		&& ansible-galaxy collection install -r requirements.yml
#
# Tests
#

.PHONY: ping
ping: .venv
	. $(VENV_PATH)/bin/activate && \
		ansible -i $(INVENTORY) all -m ping

#
# Targets
#

.PHONY: setup-all
setup-all: .venv
	$(RUN_ANSIBLE)

.PHONY: registry
registry: .venv
	$(eval ARGS := --tags "registry" -v)
	$(RUN_ANSIBLE)

.PHONY: images
images: .venv
	$(eval ARGS := --tags "images" -v)
	$(RUN_ANSIBLE)

.PHONY: services
services: .venv
	$(eval ARGS := --tags "services" -v)
	$(RUN_ANSIBLE)

.PHONY: deploy
deploy: .venv
	$(eval ARGS := --tags "deploy" -v)
	$(RUN_ANSIBLE)

# ifeq ($(USEVAULT),1)
# 	( \
# 		export ANSIBLE_LOG_PATH=$(ANSIBLE_LOG_PATH); \
# 		. $(VENV_PATH)/bin/activate; \
# 		ansible-playbook -i $(INVENTORY) --ask-vault-pass -v playbook.yml \
# 	)
# else
# 	( \
# 		export ANSIBLE_LOG_PATH=$(ANSIBLE_LOG_PATH); \
# 		. $(VENV_PATH)/bin/activate; \
# 		ansible-playbook -i $(INVENTORY) -v playbook.yml \
# 	)
# endif