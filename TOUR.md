# Tour

What this setup gives you and how to use it. Run `tour` in zsh to read this
page in the terminal, or `tour vim` (or `shell`, `fzf`, `zoxide`, `git`,
`tools`, `prompt`, `dotfiles`) for one section. On Windows only the Vim, Git
and Tools sections apply.

## Shell

Typing helpers, active in every zsh prompt:

| Do this | To get |
|---|---|
| Start typing, then press Right arrow | Accept the grey suggestion from your history |
| Press Tab | A searchable completion menu; type to filter, Enter to accept |
| Press Esc twice | Put `sudo` in front of the current (or previous) command |
| Watch the command colour as you type | Green is a valid command, red is a typo |

After you run a command that has a shorter alias, the alias is printed above
the output, so you learn the short forms as you go.

| Command | What it does |
|---|---|
| `x archive.zip` | Unpack any archive (zip, tar.gz, 7z, ...) |
| `t some title` | Set the terminal tab's title |
| `ls` | Long listing with hidden files and readable sizes |
| `sail` | Laravel Sail from the current project |
| `man <command>` | Man pages, in colour |
| `alias \| grep <word>` | Find an alias |

Completion is set up for `git`, `gh`, `ng`, `uv`, `aws`, `composer` and
`docker`. `asp <profile>` switches the AWS profile.

## fzf

A fuzzy finder: type a few letters in any order of appearance to narrow a list.

| Key | What it does |
|---|---|
| Ctrl-R | Search command history; Enter puts the command on the prompt |
| Ctrl-T | Pick a file and insert its path into the command line |
| Alt-C | Pick a subfolder and `cd` into it |
| `vim **` then Tab | Pick a file as the argument (works for any command) |
| `kill -9 **` then Tab | Pick a process |

Inside a list: `'word` matches exactly, `^word` at the start, `word$` at the
end, `!word` excludes, and a space between terms means "and".

```sh
git checkout $(git branch | fzf)     # pick a branch
fzf --preview 'bat --color=always {}'   # browse files with a preview
```

## zoxide

Jump to folders you have visited by typing part of the name.

| Command | What it does |
|---|---|
| `z deck` | Go to the most used folder whose name matches "deck" |
| `z fidb data` | Narrow with several words, matched in order |
| `zi data` | Choose from all matches in a list |
| `z data` then Space, Tab | The same list as a completion menu |
| `z -` | Back to the previous folder |
| `zoxide query -ls` | Show every known folder with its score |
| `zoxide add ~/projects/*/` | Register all project folders at once |

It only knows folders you have been in (or added), and the last word has to
match the final folder name.

## Git

oh-my-zsh shortcuts (shell aliases):

| Alias | Runs |
|---|---|
| `gst` | `git status` |
| `gco`, `gcb` | `git checkout`, `git checkout -b` |
| `gaa` | `git add --all` |
| `gcmsg "msg"` | `git commit -m "msg"` |
| `gd`, `gds` | `git diff`, `git diff --staged` |
| `gl`, `gp` | `git pull`, `git push` |
| `glog` | One-line graph log |

Your own aliases from `.gitconfig`:

| Alias | What it does |
|---|---|
| `git s`, `git st` | Short status, full status |
| `git ca` | Add everything and commit, showing the diff |
| `git nb <name>` | New branch |
| `git lg` | Graph log of all branches |
| `git dfc` | Diff of what is staged |
| `git last` | Files changed in the last commit |
| `git sync` | Pull with rebase, then push the current branch |
| `git up` | Pull with rebase, update submodules, push |
| `git today`, `git yesterday` | Your commits as a bullet list (for stand-up) |
| `git sincelast` | Commits since the last tag |
| `git merged`, `git localclean` | List, then delete, local branches already merged |
| `git remoteclean` | Drop references to branches deleted on the remote |
| `git conflicts` | Files with merge conflicts |
| `git root` | Path of the repository root |

`git config --get-regexp '^alias'` lists all of them.

## Vim

The leader key is `\`.

| Key | What it does |
|---|---|
| F2 | Show or hide the file tree |
| F3 | Reveal the current file in the tree |
| F5 | Undo history browser |
| Ctrl-P | Fuzzy-find a file |
| Shift-Arrow | Move between splits |
| `\q` | Re-wrap the paragraph |
| `\r` | Convert tabs to match the indent settings |
| `\s` | Reload `.vimrc` |
| `\t=` `\t>` `\t:` `\t,` | Align on `=`, `=>`, `:` or `,` |
| `%` | Jump between matching brackets, tags and if/else/end |

Editing:

| Key | What it does |
|---|---|
| `gcc`, `gc` on a selection | Comment or uncomment |
| `cs"'` | Change surrounding `"` to `'` |
| `ds(` | Delete surrounding parentheses |
| `ysiw]` | Wrap the word in brackets |
| `S"` on a selection | Wrap the selection in quotes |
| `crs`, `crc`, `cru` | Convert the word to snake_case, camelCase, UPPER_CASE |
| `:%S/old/new/g` | Replace keeping case (old, Old, OLD) |
| Ctrl-Y then `,` | Expand an Emmet abbreviation such as `ul>li*3` |
| `.` | Repeat the last change, including the ones above |

Brackets and quotes close themselves, and indentation is detected per file.

Files and search:

| Command | What it does |
|---|---|
| `:Files`, `:GFiles` | Find a file; only files tracked by git |
| `:Buffers` | Switch between open files |
| `:Rg word` | Search file contents (needs ripgrep) |
| `:Lines` | Search lines in open files |
| `:Rename`, `:Move`, `:Delete` | Rename, move or delete the current file |
| `:SudoWrite` | Save a file you opened without permission |

Git inside Vim:

| Command | What it does |
|---|---|
| `:Git` | Status window: `s` stages, `u` unstages, `cc` commits |
| `:Git blame` | Who changed each line |
| `:Gdiffsplit` | Diff the file against the last commit |
| `:GBrowse` | Open the file on GitHub |
| `]c`, `[c` | Next, previous changed block |
| `\hp`, `\hs`, `\hu` | Preview, stage, undo the block under the cursor |

Linting runs by itself with whatever linters are installed; `:ALEInfo` shows
which ones, `:ALEFix` applies fixes. In PHP files `\n` inserts a `use`
statement, `\nf` expands a class name and `\ns` sorts the `use` lines.

Plugins: `:PlugUpdate` updates, `:PlugInstall` installs new ones from
`.vimrc`, `:PlugClean` removes deleted ones.

## Tools

| Command | What it does |
|---|---|
| `bat file` | `cat` with syntax highlighting and line numbers |
| `glow README.md` | Read Markdown in the terminal; `glow -p` pages it |
| `ll`, `la` | Long list with git status (`la` includes hidden files); needs eza |
| `lt`, `tree` | Tree view that respects `.gitignore` (`lt` goes two levels deep); needs eza |
| `gh pr create`, `gh pr list`, `gh pr checkout 12` | Pull requests from the terminal |
| `gh pr view --web`, `gh repo view --web` | Open the pull request or repo in the browser |
| `uv venv`, `uv pip install -r requirements.txt` | Fast Python environments and installs |
| `uv run script.py`, `uvx ruff check` | Run a script or a tool without installing it |
| `marp deck.md -o deck.pdf` | Turn Markdown into slides (`--pptx`, `--html`) |
| `marp -p deck.md` | Live slide preview |

Not every tool is installed on every machine; `make packages` lists what it
skipped and why.

## Prompt

Powerlevel10k shows, left to right: the OS icon, the current folder and the
git branch with its state. On the right, when relevant: how long the last
command took, background jobs, and the active Python, Node or Go environment.

`p10k configure` reruns the style wizard. Icons need Hack Nerd Font selected
in the terminal (`make fonts`).

## Dotfiles

Run these from the dotfiles folder:

| Command | What it does |
|---|---|
| `make status` | What is linked, what differs, what is missing |
| `make install` | Link everything and fetch plugins |
| `make packages` | Install the tools above for this OS |
| `make deps` | Fetch or repair oh-my-zsh, the prompt and plugins |
| `omz update` | Update oh-my-zsh |

Settings for one machine only go in `~/.zshrc.local` and `~/.gitconfig.local`,
which are not tracked.
