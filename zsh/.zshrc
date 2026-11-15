
# export PATH=$HOME/bin:/usr/local/bin:$PATH
ZSH_DISABLE_COMPFIX="true"

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS=true

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    git pj composer aws                 # git aliases, project jumper, composer, aws profiles
    gh ng uv                            # completion; each does nothing when its tool is missing
    sudo extract                        # Esc Esc prefixes sudo; `x file` unpacks any archive
    alias-finder colored-man-pages
)

# These print a warning or an error in every new shell when their tool is
# missing, so they are only loaded where it is installed. The -x test also
# rules out a dangling link, which is what an uninstalled Docker Desktop leaves.
if (( $+commands[fzf] )); then plugins+=(fzf); fi
if (( $+commands[zoxide] )); then plugins+=(zoxide); fi
if [[ -x $commands[docker] ]]; then plugins+=(docker); fi

# Plugins that are not part of oh-my-zsh; `make deps` clones them. The order
# matters: fzf-tab has to come before the other two, and syntax highlighting
# has to be last.
for _plugin in fzf-tab zsh-autosuggestions zsh-syntax-highlighting; do
    if [[ $_plugin == fzf-tab ]] && (( ! $+commands[fzf] )); then
        continue
    fi
    if [[ -d $ZSH/custom/plugins/$_plugin ]]; then
        plugins+=($_plugin)
    fi
done
unset _plugin

# alias-finder: after a command, show a shorter alias for it if one exists
zstyle ':omz:plugins:alias-finder' autoload yes
zstyle ':omz:plugins:alias-finder' cheaper yes

# configuration for pj plugin
export PROJECT_PATHS=(~/projects)

source $ZSH/oh-my-zsh.sh

# default file creation mode (775)
umask 002

# User configuration
export GIT_EDITOR=vim

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR='vim'
else
    export EDITOR='code'
fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
# useful aliases
#alias ls='ls -AGF'
alias ls='ls -lha'
alias p='pj'

# Debian and Ubuntu install bat under the name batcat
if ! command -v bat >/dev/null && command -v batcat >/dev/null; then
    alias bat='batcat'
fi
alias sail='bash vendor/bin/sail'

if [ -f ~/.zsh/aliases ]; then
    source ~/.zsh/aliases
fi

# Custom functions

# function to change the title of the current terminal tab
function t() {
    echo -ne "\033]0;"$*"\007"
}

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.zsh/.p10k.zsh ]] || source ~/.zsh/.p10k.zsh

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# Android SDK: the first path is the macOS default, the second the Linux one
for _sdk in "$HOME/Library/Android/sdk" "$HOME/Android/Sdk"; do
    if [[ -d $_sdk ]]; then
        export ANDROID_HOME="$_sdk"
        export ANDROID_SDK_ROOT="$_sdk"
        export ANDROID_AVD_HOME="$HOME/.android/avd"
        # avdmanager, sdkmanager / adb, logcat / emulator
        export PATH="$PATH:$_sdk/tools/bin:$_sdk/platform-tools:$_sdk/emulator"
        break
    fi
done
unset _sdk

# java_home only exists on macOS
if [[ -x /usr/libexec/java_home ]]; then
    export JAVA_HOME="$(/usr/libexec/java_home 2>/dev/null)"
fi

export PYENV_ROOT="$HOME/.pyenv"
if ! command -v pyenv >/dev/null && [[ -d $PYENV_ROOT/bin ]]; then
    export PATH="$PYENV_ROOT/bin:$PATH"
fi
if command -v pyenv >/dev/null; then
    eval "$(pyenv init -)"
fi

export PATH="$HOME/.docker/bin":$PATH
if command -v go >/dev/null; then
    export PATH="$PATH:$(go env GOPATH)/bin"
fi

# Machine-specific settings that don't belong in the dotfiles repo
if [[ -f ~/.zshrc.local ]]; then
    source ~/.zshrc.local
fi
