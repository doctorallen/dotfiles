# dotfiles

Config for zsh, vim, git and VS Code, with one installer for macOS, Linux, WSL
and Windows.

## Install

### macOS, Linux, WSL

```sh
git clone https://github.com/doctorallen/dotfiles.git ~/dotfiles
cd ~/dotfiles
make packages   # optional: git, vim, zsh and the Hack Nerd Font
make install
```

No `make` yet? `./install.sh` does the same thing, and `./install.sh packages`
installs `make` on Linux.

`make install` ends by offering to make zsh your login shell. Say no and you
can do it later with `make shell`.

### Windows

Symlinks need Developer Mode (Settings > System > For developers) or an
elevated PowerShell.

```powershell
git clone https://github.com/doctorallen/dotfiles.git $HOME\dotfiles
cd $HOME\dotfiles
.\install.ps1 packages   # optional: Git, Vim and VS Code via winget
.\install.ps1
```

If you get an execution policy error, run it as
`powershell -ExecutionPolicy Bypass -File install.ps1`.

### WSL, from a bare Ubuntu

The shell, vim and git live inside WSL. The prompt's font and VS Code live on
the Windows side, so there are two halves.

Inside WSL:

```sh
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/doctorallen/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh packages   # git, vim, zsh, curl, make
make install            # links, oh-my-zsh, powerlevel10k, vim plugins, login shell
```

In PowerShell on Windows, from a clone of this repo:

```powershell
.\install.ps1 fonts     # Hack Nerd Font, for the prompt's icons
.\install.ps1           # optional: git, vim and VS Code settings for Windows itself
```

Then pick the font in Windows Terminal: Settings > Profiles > Defaults >
Appearance > Font face > `Hack Nerd Font`. Open a new WSL tab and the prompt
should look the same as on the Mac.

Native Windows has no zsh, so the oh-my-zsh and powerlevel10k prompt is only
available through WSL.

## Targets

| Target          | What it does                                                    |
| --------------- | --------------------------------------------------------------- |
| `make install`  | `link` then `deps`                                              |
| `make dry-run`  | Show what `install` would do, without changing anything         |
| `make deps`     | Fetch oh-my-zsh, powerlevel10k and the vim plugins              |
| `make link`     | Symlink the configs into place                                  |
| `make status`   | Show what is linked, what differs from the repo, what is missing |
| `make unlink`   | Remove the symlinks                                             |
| `make packages` | Install the base packages (Homebrew, apt/dnf/pacman)            |
| `make shell`    | Make zsh your login shell                                       |
| `make fonts`    | Install the Hack Nerd Font (Linux desktops; see WSL above)      |

`install.ps1` takes the same names, apart from `shell`: `.\install.ps1 status`,
`.\install.ps1 link -DryRun`, and so on.

Nothing is ever deleted. A file that is already where a link should go is
moved to `~/.dotfiles-backup/<timestamp>/` first.

## What goes where

| In the repo                 | macOS / Linux / WSL       | Windows                      |
| --------------------------- | ------------------------- | ---------------------------- |
| `.gitconfig`                | `~/.gitconfig`            | `~\.gitconfig`               |
| `.vimrc`                    | `~/.vimrc`                | `~\_vimrc`                   |
| `.vim/`                     | `~/.vim`                  | `~\vimfiles`                 |
| `.bash_aliases`             | `~/.bash_aliases`         |                              |
| `zsh/.zshrc`                | `~/.zshrc`                |                              |
| `zsh/.zsh/.p10k.zsh`        | `~/.zsh/.p10k.zsh`        |                              |
| `vscode/settings.json`      | VS Code user dir          | `%APPDATA%\Code\User`        |
| `vscode/snippets/`          | VS Code user dir          | `%APPDATA%\Code\User`        |
| `vscode/colors/helix-theme` | `~/.vscode/extensions`    | `~\.vscode\extensions`       |

The VS Code user dir is `~/Library/Application Support/Code/User` on macOS and
`~/.config/Code/User` on Linux. VS Code is skipped when it isn't installed.

To manage another file, add it to the repo and add one line to `manifest` in
`install.sh` (and `Get-Manifest` in `install.ps1` if it applies to Windows).

`iterm2/` is not linked: import it from iTerm2's settings.

## Vim plugins

Plugins are managed by [vim-plug](https://github.com/junegunn/vim-plug). The
list lives at the top of `.vimrc`, and `make install` fetches them into
`.vim/plugged/`, which is not tracked.

| In vim         | What it does                                      |
| -------------- | ------------------------------------------------- |
| `:PlugInstall` | Install anything in the list that is missing      |
| `:PlugUpdate`  | Update every plugin to its latest version         |
| `:PlugClean`   | Remove plugins that are no longer in the list     |
| `:PlugUpgrade` | Update vim-plug itself (`.vim/autoload/plug.vim`) |

## Machine-specific settings

Keep anything that only belongs on one machine out of the repo:

- `~/.zshrc.local` is sourced at the end of `.zshrc`
- `~/.gitconfig.local` is included at the end of `.gitconfig`
- `~/.zsh/aliases` is sourced by `.zshrc` if it exists
