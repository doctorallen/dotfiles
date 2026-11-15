# One entry point for every OS: macOS, Linux and WSL run install.sh,
# native Windows runs install.ps1.

ifeq ($(OS),Windows_NT)
RUN     := powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1
DRY_RUN := $(RUN) install -DryRun
else
RUN     := bash install.sh
DRY_RUN := $(RUN) -n install
endif

.DEFAULT_GOAL := help

help: ## Show this help
	@echo "Usage: make <target>"
	@echo
	@echo "  install    Symlink everything into place, then fetch dependencies"
	@echo "  dry-run    Show what 'make install' would do, without changing anything"
	@echo "  deps       Fetch oh-my-zsh, powerlevel10k and the vim plugins"
	@echo "  link       Symlink the configs, backing up whatever is already there"
	@echo "  status     Show what is linked, what differs and what is missing"
	@echo "  unlink     Remove the symlinks"
	@echo "  packages   Install the base packages for this OS (brew / apt / winget)"
	@echo "  shell      Make zsh your login shell"
	@echo "  fonts      Install the Hack Nerd Font that the prompt's icons need"

install:
	@$(RUN) install

dry-run:
	@$(DRY_RUN)

deps:
	@$(RUN) deps

link:
	@$(RUN) link

status:
	@$(RUN) status

unlink:
	@$(RUN) unlink

packages:
	@$(RUN) packages

shell:
	@$(RUN) shell

fonts:
	@$(RUN) fonts

.PHONY: help install dry-run deps link status unlink packages shell fonts
