# .hashrc
export GOPATH=$HOME/go
export ANDROID_HOME=/var/lib/android
export PATH=~/bin:$GOPATH/bin:/usr/local/bin:/usr/bin:~/.composer/vendor/bin:$PATH:$ANDROID_HOME
export LD_LIBRARY_PATH=/usr/lib:/usr/local/lib:$LD_LIBRARY_PATH
export SVN_EDITOR=vim
export GIT_EDITOR=vim
export TERM=xterm-256color

LS_COLORS=$LS_COLORS:'di=0;35:'
export LS_COLORS


#color variables

YELLOW="\[\033[38;5;221m\]"
PURPLE="\[\033[38;5;103m\]"
GREEN="\[\033[38;5;77m\]"
LIGHTGREY="\[\033[38;5;246m\]"
GREY="\[\033[38;5;237m\]"
ORANGE="\[\033[38;5;208m\]"
BLUE="\[\033[38;5;38m\]"
RED="\[\033[38;5;95m\]"
LIGHTGREEN="\[\033[38;5;113m\]"
DEFAULT="\[\033[38;5;7m\]"

SEP="$GREY]$LIGHTGREY-$GREY["
FILES="\$(ls -1 | wc -l | sed 's: ::g') files"


# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific aliases and functions

umask 002
alias openhere='nautilus .'
alias lsa='ls -lha'
alias ls='ls -atGF'
alias ll='ls -latGF'
alias ack='ack-grep'
alias gc='cat ~/.gitconfig | grep'
alias comp-ass='compass watch --css-dir app/webroot/css/ --sass-dir app/webroot/sass/'
alias lst='sh ~/lstime.sh'
alias tink='php artisan tinker'
alias art='php artisan'
alias dbref='php artisan migrate:refresh --seed'
alias cda='composer dumpautoload'
alias v='vagrant'
alias vim='mvim'

# Make tmux try to reconnect/reattach to an existing session, yet fallback if none are running
alias tmux="if tmux has; then tmux -2 attach; else tmux -2 new; fi"

stty ixany
stty ixoff -ixon

# Add bash aliases.
if [ -f ~/.bash_aliases ]; then
    source ~/.bash_aliases
fi

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

if [ -f ~/.git-completion.bash ]; then
	. ~/.git-completion.bash
fi

if [ -f /etc/bash_completion ]; then
	. /etc/bash_completion
fi
if [ hash brew 2>/dev/null ]; then
    if [ -f $(brew --prefix)/etc/bash_completion ]; then
    . $(brew --prefix)/etc/bash_completion
    fi
fi

# completion of .ssh/hosts
#complete -W "$(echo $(grep ^Host ~/.ssh/config | sed -e 's/Host //' | grep -v "\*"))" ssh

function stopvm(){
    /usr/bin/VBoxManage controlvm "$@" poweroff;
}

function tagssh(){
    /usr/bin/ssh -i ~/.ssh/tag-aws.pem ubuntu@"$@".theatomgroup.com
}

function tagscp(){
    /usr/bin/scp -i ~/.ssh/tag-aws.pem $1 ubuntu@"$2".theatomgroup.com:/home/ubuntu/
}

function s(){
    scp ~/.bashrc $1:/tmp/.bashrc_temp
    if [[ $* == *--setup* ]]; then
        scp -r ~/devops $1:/tmp/devops
    fi
    ssh -t $1 "bash --rcfile /tmp/.bashrc_temp ; rm /tmp/.bashrc_temp"
}

function setup(){
    sh /tmp/devops/scripts/lemp/setup.sh
}

function t {
    echo -ne "\033]0;"$*"\007"
}

function p(){
	cd /var/www/"$@"
	name="$@"
	t ${name%/}
}

_p (){
	local cur
    cur=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=( $( compgen -S/ -d /var/www/$cur | cut -b 10- ) )
}

complete -o nospace -F _p p

function g(){
	cd ~/go/src/github.com/doctorallen/"$@"
}

_g (){
	local cur
    cur=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=( $( compgen -S/ -d ~/go/src/github.com/doctorallen/$cur | cut -b 44- ) )
}

complete -o nospace -F _g g

function _git_prompt() {
  local git_status="`git status -unormal 2>&1`"
  if ! [[ "$git_status" =~ Not\ a\ git\ repo ]]; then
    if [[ "$git_status" =~ nothing\ to\ commit ]]; then
      local ansi=77
    elif [[ "$git_status" =~ nothing\ added\ to\ commit\ but\ untracked\ files\ present ]]; then
      local ansi=221
    else
      local ansi=103
    fi
    if [[ "$git_status" =~ On\ branch\ ([^[:space:]]+) ]]; then
      branch=${BASH_REMATCH[1]}
      test "$branch" != master || local ansi=88
    else
      # Detached HEAD.  (branch=HEAD is a faster alternative.)
      branch="(`git describe --all --contains --abbrev=4 HEAD 2> /dev/null ||
		  echo HEAD`)"
    fi
	 echo -n "$LIGHTGREY-$GREY[$LIGHTGREY"'git \[\033[38;5;'"$ansi"'m\]'"$branch"'\[\e[m\]'"$GREY]"
  fi
}

function _parse_vagrant_status {
  status=`vagrant status 2>&1`
  if [[ -n `echo ${status} | grep "poweroff"` ]]; then
    echo "[off]"
  fi
  if [[ -n `echo ${status} | grep "running"` ]]; then
    echo "[on]"
  fi
  if [[ -n `echo ${status} | grep "aborted"` ]]; then
    echo "[aborted]"
  fi
  return
}

function _prompt_command() {
PS1="$GREY[$LIGHTGREY\$(date +%l)$ORANGE:$LIGHTGREY\$(date +%M) $ORANGE\$(date +%p)$SEP$BLUE\u$RED@$ORANGE\h$SEP$BLUE\w$GREY$SEP$RED$FILES$GREY]`_git_prompt` $DEFAULT\n"'$ '
}
PROMPT_COMMAND=_prompt_command
