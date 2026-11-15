#!/usr/bin/env bash
#
# Dotfiles installer for macOS, Linux and WSL.
# (Native Windows uses install.ps1 instead.)
#
# Usage: ./install.sh [-n] <command>
#
#   install    link + deps, then offer to make zsh your login shell (the default)
#   deps       fetch oh-my-zsh, powerlevel10k and the vim plugins
#   link       symlink everything into $HOME, backing up what is already there
#   status     show what is linked, what differs and what is missing
#   unlink     remove the symlinks this script created
#   packages   install the base packages for this OS
#   shell      make zsh your login shell
#   fonts      install the Hack Nerd Font that the prompt's icons need
#
#   -n         dry run: print what would happen, change nothing
#
# Written for bash 3.2 so that it runs on a stock macOS.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
readonly BACKUP_DIR

DRY_RUN=0
MODE=link
BACKED_UP=0
PROBLEMS=0

# ---------------------------------------------------------------- output ----

if [ -t 1 ]; then
	C_RED=$'\033[31m' C_GREEN=$'\033[32m' C_YELLOW=$'\033[33m' C_BLUE=$'\033[34m' C_OFF=$'\033[0m'
else
	C_RED='' C_GREEN='' C_YELLOW='' C_BLUE='' C_OFF=''
fi

say()  { printf '%s%-8s%s %s\n' "$1" "$2" "$C_OFF" "$3"; }
info() { say "$C_BLUE" "$1" "$2"; }
good() { say "$C_GREEN" "$1" "$2"; }
warn() { say "$C_YELLOW" "$1" "$2"; }
fail() { say "$C_RED" "$1" "$2" >&2; }

# Run a command, or just print it when in dry-run mode.
run() {
	if [ "$DRY_RUN" = 1 ]; then
		printf '         would run: %s\n' "$*"
	else
		"$@"
	fi
}

# Same, for steps whose effect the caller already reports on its own line.
quiet_run() {
	if [ "$DRY_RUN" != 1 ]; then
		"$@"
	fi
}

# Paths are easier to read with ~ in place of the home directory.
short() { printf '%s' "${1/#"$HOME"/~}"; }

# ------------------------------------------------------------- detection ----

detect_os() {
	case "$(uname -s)" in
		Darwin) echo macos ;;
		Linux)
			if grep -qi microsoft /proc/version 2>/dev/null; then
				echo wsl
			else
				echo linux
			fi
			;;
		MINGW* | MSYS* | CYGWIN*) echo windows ;;
		*) echo unknown ;;
	esac
}

OS="$(detect_os)"
readonly OS

# Where VS Code keeps user settings on this OS. Prints nothing when VS Code
# is not installed here, so that headless boxes don't grow an empty config dir.
vscode_user_dir() {
	local dir
	case "$OS" in
		macos) dir="$HOME/Library/Application Support/Code/User" ;;
		linux) dir="${XDG_CONFIG_HOME:-$HOME/.config}/Code/User" ;;
		*) return 0 ;; # WSL: VS Code runs on the Windows side, see install.ps1
	esac

	if [ -d "$dir" ] || command -v code >/dev/null 2>&1 ||
		[ -d "/Applications/Visual Studio Code.app" ]; then
		echo "$dir"
	fi
}

# -------------------------------------------------------------- manifest ----

# Every file this repo manages: <path in repo> <path on disk>.
# Add a line here when you add a config file to the repo.
manifest() {
	entry .gitconfig            "$HOME/.gitconfig"
	entry .bash_aliases         "$HOME/.bash_aliases"
	entry .vimrc                "$HOME/.vimrc"
	entry .vim                  "$HOME/.vim"
	entry zsh/.zshrc            "$HOME/.zshrc"
	entry zsh/.zsh/.p10k.zsh    "$HOME/.zsh/.p10k.zsh"

	local code_dir
	code_dir="$(vscode_user_dir)"
	if [ -n "$code_dir" ]; then
		entry vscode/settings.json                  "$code_dir/settings.json"
		entry vscode/snippets/global.code-snippets  "$code_dir/snippets/global.code-snippets"
		entry vscode/colors/helix-theme             "$HOME/.vscode/extensions/helix-theme"
	elif [ "$OS" = wsl ]; then
		info "skip" "VS Code settings live on the Windows side: run install.ps1 there"
	else
		info "skip" "VS Code not found, leaving its settings alone"
	fi
}

entry() {
	local src="$DOTFILES/$1" dst="$2"

	if [ ! -e "$src" ]; then
		fail "error" "$1 is in the manifest but not in the repo"
		PROBLEMS=$((PROBLEMS + 1))
		return 0
	fi

	case "$MODE" in
		link) do_link "$src" "$dst" ;;
		status) do_status "$src" "$dst" ;;
		unlink) do_unlink "$src" "$dst" ;;
	esac
}

is_our_link() { [ -L "$2" ] && [ "$(readlink "$2")" = "$1" ]; }

do_link() {
	local src="$1" dst="$2"

	if is_our_link "$src" "$dst"; then
		good "ok" "$(short "$dst")"
		return 0
	fi

	# Anything already there (file, directory, or someone else's symlink) is
	# moved aside, never deleted.
	if [ -e "$dst" ] || [ -L "$dst" ]; then
		local backup="$BACKUP_DIR/${dst#"$HOME"/}"
		warn "backup" "$(short "$dst") -> $(short "$backup")"
		quiet_run mkdir -p "$(dirname "$backup")"
		quiet_run mv "$dst" "$backup"
		BACKED_UP=$((BACKED_UP + 1))
	fi

	quiet_run mkdir -p "$(dirname "$dst")"
	quiet_run ln -s "$src" "$dst"
	good "link" "$(short "$dst") -> $(short "$src")"
}

do_status() {
	local src="$1" dst="$2"

	if is_our_link "$src" "$dst"; then
		good "linked" "$(short "$dst")"
	elif [ -L "$dst" ]; then
		warn "foreign" "$(short "$dst") is a symlink to $(readlink "$dst")"
	elif [ -e "$dst" ]; then
		if diff -rq "$src" "$dst" >/dev/null 2>&1; then
			warn "copy" "$(short "$dst") is an identical copy, not a link"
		else
			warn "differs" "$(short "$dst") is a copy that differs from the repo"
		fi
	else
		warn "missing" "$(short "$dst")"
	fi
}

do_unlink() {
	local src="$1" dst="$2"

	if is_our_link "$src" "$dst"; then
		quiet_run rm "$dst"
		good "unlink" "$(short "$dst")"
	else
		info "skip" "$(short "$dst") is not one of our links"
	fi
}

# -------------------------------------------------------------- commands ----

clone_if_missing() {
	local url="$1" dir="$2"

	if [ -d "$dir" ]; then
		good "ok" "$(short "$dir")"
	else
		info "clone" "$url -> $(short "$dir")"
		quiet_run git clone --quiet --depth 1 "$url" "$dir"
	fi
}

cmd_deps() {
	command -v git >/dev/null 2>&1 || { fail "error" "git is required"; exit 1; }

	# These are the paths .zshrc loads from.
	local omz="$HOME/.oh-my-zsh"
	clone_if_missing https://github.com/ohmyzsh/ohmyzsh.git "$omz"
	clone_if_missing https://github.com/romkatv/powerlevel10k.git \
		"$omz/custom/themes/powerlevel10k"

	# vim-plug reads the plugin list from .vimrc, so that has to be linked first.
	if ! command -v vim >/dev/null 2>&1; then
		warn "note" "vim is not installed: run 'make packages', then 'make deps'"
	elif ! is_our_link "$DOTFILES/.vimrc" "$HOME/.vimrc"; then
		warn "note" "~/.vimrc is not linked yet: run 'make link', then 'make deps'"
	else
		info "deps" "vim plugins (vim-plug)"
		# Vim's exit status in silent mode is unreliable, so it is ignored;
		# :PlugStatus inside vim shows the result.
		run vim -es -u "$HOME/.vimrc" -i NONE -c 'PlugInstall --sync' -c 'qa' || true
	fi

}

# The login shell on record for this user, which is what a new terminal starts.
login_shell() {
	local entry
	if command -v getent >/dev/null 2>&1 && entry="$(getent passwd "$(id -un)")"; then
		echo "${entry##*:}"
	else
		echo "${SHELL:-}"
	fi
}

zsh_is_login_shell() { [ "$(basename "$(login_shell)")" = zsh ]; }

cmd_shell() {
	local zsh_path

	if ! zsh_path="$(command -v zsh)"; then
		warn "note" "zsh is not installed: run 'make packages', then 'make shell'"
		return 0
	fi
	if zsh_is_login_shell; then
		good "ok" "zsh is already your login shell"
		return 0
	fi

	# chsh refuses any shell that is not listed in /etc/shells.
	if [ -r /etc/shells ] && ! grep -qx "$zsh_path" /etc/shells; then
		info "shell" "adding $zsh_path to /etc/shells"
		as_root sh -c 'echo "$1" >> /etc/shells' sh "$zsh_path"
	fi

	info "shell" "making zsh your login shell (chsh may ask for your password)"
	if run chsh -s "$zsh_path"; then
		[ "$DRY_RUN" = 1 ] || good "ok" "open a new terminal to start using zsh"
	else
		warn "note" "the login shell was not changed: run 'make shell' to try again"
	fi
}

# Part of 'install': ask before touching the login shell, and never hang a
# script that is not attached to a terminal.
offer_shell() {
	local answer

	if ! command -v zsh >/dev/null 2>&1; then
		warn "note" "zsh is not installed: run 'make packages', then 'make shell'"
	elif zsh_is_login_shell; then
		return 0
	elif [ "$DRY_RUN" = 1 ] || [ ! -t 0 ]; then
		warn "note" "zsh is not your login shell: run 'make shell'"
	else
		printf 'Make zsh your login shell? [y/N] '
		read -r answer
		case "$answer" in
			y | Y | yes) cmd_shell ;;
			*) info "skip" "left the login shell alone: run 'make shell' to change it later" ;;
		esac
	fi
}

cmd_link() {
	MODE=link
	manifest
	if [ "$BACKED_UP" -gt 0 ]; then
		warn "note" "$BACKED_UP existing item(s) moved to $(short "$BACKUP_DIR")"
	fi
}

cmd_status() {
	MODE=status
	info "os" "$OS"
	manifest
}

cmd_unlink() {
	MODE=unlink
	manifest
	info "note" "earlier versions of your files, if any, are in ~/.dotfiles-backup"
}

# Use sudo only when we are not already root (containers often have no sudo).
as_root() {
	if [ "$(id -u)" -eq 0 ]; then run "$@"; else run sudo "$@"; fi
}

cmd_packages() {
	local list="$DOTFILES/packages/linux.txt" pkgs

	case "$OS" in
		macos)
			if ! command -v brew >/dev/null 2>&1; then
				fail "error" "Homebrew is not installed: see https://brew.sh"
				exit 1
			fi
			run brew bundle --file "$DOTFILES/packages/Brewfile"
			;;
		linux | wsl)
			pkgs="$(grep -v '^[[:space:]]*#' "$list" | tr '\n' ' ')"
			# Word splitting of $pkgs is intended: one argument per package.
			# shellcheck disable=SC2086
			if command -v apt-get >/dev/null 2>&1; then
				as_root apt-get update
				as_root apt-get install -y $pkgs
			elif command -v dnf >/dev/null 2>&1; then
				as_root dnf install -y $pkgs
			elif command -v pacman >/dev/null 2>&1; then
				as_root pacman -S --needed --noconfirm $pkgs
			else
				fail "error" "no supported package manager (apt, dnf, pacman): install by hand: $pkgs"
				exit 1
			fi
			cmd_fonts
			;;
	esac
}

readonly FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.tar.xz"

# The powerlevel10k prompt draws its icons with a Nerd Font. The font has to
# be on the machine that draws the terminal window, which for WSL is Windows.
cmd_fonts() {
	local dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/HackNerdFont"

	case "$OS" in
		macos)
			info "fonts" "on macOS the font comes from Homebrew: run 'make packages'"
			;;
		wsl)
			warn "note" "the prompt font belongs on the Windows side. In PowerShell, from this repo:"
			warn "" "    .\\install.ps1 fonts"
			warn "" "then choose 'Hack Nerd Font' in Windows Terminal:"
			warn "" "    Settings > Profiles > Defaults > Appearance > Font face"
			;;
		linux)
			if ! command -v fc-cache >/dev/null 2>&1; then
				info "skip" "no desktop font system here: install Hack Nerd Font on the machine your terminal runs on"
			elif ls "$dir"/*.ttf >/dev/null 2>&1; then
				good "ok" "$(short "$dir")"
			else
				info "fonts" "Hack Nerd Font -> $(short "$dir")"
				if [ "$DRY_RUN" != 1 ]; then
					mkdir -p "$dir"
					curl -fsSL "$FONT_URL" | tar -xJ -C "$dir"
					fc-cache -f "$dir"
					good "ok" "set your terminal's font to 'Hack Nerd Font'"
				fi
			fi
			;;
	esac
}

# ------------------------------------------------------------------ main ----

usage() { sed -n '3,18p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while getopts "nh" opt; do
	case "$opt" in
		n) DRY_RUN=1 ;;
		h) usage; exit 0 ;;
		*) usage >&2; exit 2 ;;
	esac
done
shift $((OPTIND - 1))

case "$OS" in
	windows)
		fail "error" "native Windows shells can't make real symlinks with ln: run install.ps1 from PowerShell"
		exit 1
		;;
	unknown)
		fail "error" "unsupported OS: $(uname -s)"
		exit 1
		;;
esac

case "${1:-install}" in
	install) cmd_link; cmd_deps; offer_shell ;;
	deps) cmd_deps ;;
	link) cmd_link ;;
	status) cmd_status ;;
	unlink) cmd_unlink ;;
	packages) cmd_packages ;;
	shell) cmd_shell ;;
	fonts) cmd_fonts ;;
	*) usage >&2; exit 2 ;;
esac

if [ "$PROBLEMS" -gt 0 ]; then
	exit 1
fi
