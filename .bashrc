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
# Server based aliases
alias poot='cd /var/www/pohly/wp-content/themes/pohly'
alias emerson='cd /var/www/emerson'
alias coinup='cd /var/www/coinup'
alias bbhd='cd /var/www/bbhd'
alias lamp='ssh root@lamp'
alias usdb='ssh -i ~/internal.pem ubuntu@us.coinupdb.theatomgroup.com'
alias cadb='ssh -i ~/internal.pem ubuntu@ca.coinupdb.theatomgroup.com'
alias cndb='ssh -i ~/internal.pem ubuntu@cn.coinupdb.theatomgroup.com'
alias audb='ssh -i ~/internal.pem ubuntu@au.coinupdb.theatomgroup.com'
alias zenimax='cd /var/www/zenimax_beta'
# Make tmux try to reconnect/reattach to an existing session, yet fallback if none are running
alias tmux="if tmux has; then tmux -2 attach; else tmux -2 new; fi"

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
    echo -n '\[\e[0;'"$ansi"'m\]'"($branch)"'\[\e[m\]'
  fi
}

function _prompt_command() {
    CURRENT_USER=`whoami`
    if [ "$CURRENT_USER" = "root" ]; then
	 PS1="\[\033[0;36m\]\u`_git_prompt` \W"'$ '
    else
	 PS1="\u`_git_prompt` \W"'$ '
    fi
}
PROMPT_COMMAND=_prompt_command
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
