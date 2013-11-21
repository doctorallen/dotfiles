# .bashrc

export PATH=~/bin:/usr/bin:/usr/local/bin:$PATH
export LD_LIBRARY_PATH=/usr/lib:/usr/local/lib:$LD_LIBRARY_PATH
export SVN_EDITOR=vim
export GIT_EDITOR=vim
export TERM=xterm-256color

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific aliases and functions

umask 002
alias lsa='ls -lha'
alias ls='ls -a'
alias ll='ls -l'
alias ack='ack-grep'
alias comp-ass='compass watch --css-dir app/webroot/css/ --sass-dir app/webroot/sass/'
# Make tmux try to reconnect/reattach to an existing session, yet fallback if none are running
alias tmux="if tmux has; then tmux -2 attach; else tmux -2 new; fi"

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

function _git_prompt() {
  local git_status="`git status -unormal 2>&1`"
  if ! [[ "$git_status" =~ Not\ a\ git\ repo ]]; then
    if [[ "$git_status" =~ nothing\ to\ commit ]]; then
      local ansi=32
    elif [[ "$git_status" =~ nothing\ added\ to\ commit\ but\ untracked\ files\ present ]]; then
      local ansi=33
    else
      local ansi=35
    fi
    if [[ "$git_status" =~ On\ branch\ ([^[:space:]]+) ]]; then
      branch=${BASH_REMATCH[1]}
      test "$branch" != master || local ansi=31
    else
      # Detached HEAD.  (branch=HEAD is a faster alternative.)
      branch="(`git describe --all --contains --abbrev=4 HEAD 2> /dev/null ||
		  echo HEAD`)"
    fi
    echo -n '[git \[\e[0;'"$ansi"'m\]'"$branch"'\[\e[m\]]'
  fi
}

function _prompt_command() {
	 PS1="\[\033[01;32m\]\u@\h\[\033[00m\]: \[\033[01;34m\]\w\[\033[00m\] `_git_prompt` \n"'$ '
}
PROMPT_COMMAND=_prompt_command
