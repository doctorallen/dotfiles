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

if [ -f ~/devops/scripts/scripts.sh ]; then
    source ~/devops/scripts/scripts.sh
fi

if [ -f /home/ubuntu/devops/scripts/scripts.sh ]; then
    source /home/ubuntu/devops/scripts/scripts.sh
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

if [ -f $(brew --prefix)/etc/bash_completion ]; then
. $(brew --prefix)/etc/bash_completion
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
        scp ~/devops/scripts/scripts.sh $1:~/scripts.sh
    fi

    ssh -t $1 "bash --rcfile /tmp/.bashrc_temp"

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

source ~/colors.sh

getGitPrompt () {

    local exit="$?"

    local addition_counter=0
    local modification_counter=0
    local deletion_counter=0
    local untracked_counter=0
    local staged_counter=0
    local unstaged_counter=0
    local conflicts_counter=0
    local stash_counter=0
    local ahead=0
    local behind=0

    local diff_string=""
    local stage_string=""
    local prompt_string=""
    local difference_string=""
    local branch_status=""
    local branch=""


    #
    # Parses the stash list from `git stash list`
    #
    function parseStash()
    {
        local stash_command="$(git stash list 2>/dev/null)"
        local stash_regex="^stash@"

        while read; do
            x="$REPLY"

            if [[ "$x" =~ $stash_regex ]]; then
                stash_counter=$[stash_counter + 1]
            fi
        done <<< "$stash_command"
    }

    #
    # Parses branch information and file modification status from `git status -sb`
    #
    # - Local branch name
    # - Number of commits ahead, number of commits behind remote
    # - Number of staged changes
    # - Number of unstaged changes
    # - Number of untracked files
    # - Number of stashed changes
    # - Number of conflicts
    #
    function parseStatus()
    {
        local status_command="$(git status --porcelain -b 2>/dev/null)"
        local ahead_regex="ahead ([0-9]+)"
        local behind_regex="behind ([0-9]+)"
        local initial_branch_regex="^## Initial commit on (.+)"
        local local_branch_regex="^## (.+)"
        local remote_branch_regex="^## (.+)\.\.\."
        local staged_regex="^[ADM][[:space:]][[:space:]]"
        local unstaged_regex="^[[:space:]][ADM][[:space:]]"
        local conflicts_regex="^UU"

        while read; do
            x="$REPLY"

            # Get conflicts count
            if [[ "$x" =~ $conflicts_regex ]]; then
                conflicts_counter=$[conflicts_counter + 1]
            fi

            # Get staged count
            if [[ "$x" =~ $staged_regex ]]; then
                staged_counter=$[staged_counter + 1] 
            fi

            # Get unstaged count
            if [[ "$x" =~ $unstaged_regex ]]; then
                unstaged_counter=$[unstaged_counter + 1] 
            fi

            # Get branch name
            if [[ "$x" =~ $initial_branch_regex ]]; then
                branch=${BASH_REMATCH[1]}
            elif [[ "$x" =~ $remote_branch_regex ]]; then
                branch=${BASH_REMATCH[1]}
            elif [[ "$x" =~ $local_branch_regex ]]; then
                branch=${BASH_REMATCH[1]}
            fi

            # Track if ahead: needs push
            if [[ "$x" =~ $ahead_regex ]]; then
               ahead=${BASH_REMATCH[1]}
            fi

            # Track if behind: needs pull
            if [[ "$x" =~ $behind_regex ]]; then
               behind=${BASH_REMATCH[1]}
            fi

            # Track additions
            if [[ "$x" =~ ^"A"[[:space:]]+ ]]; then 
                addition_counter=$[addition_counter + 1] 
            fi

            # Track modifications
            if [[ "$x" =~ ^"M"[[:space:]]+ ]]; then 
                modification_counter=$[modification_counter + 1] 
            fi

            # Track deletions
            if [[ "$x" =~ ^"D"[[:space:]]+ ]]; then 
                deletion_counter=$[deletion_counter + 1] 
            fi

            # Track untracked files
            if [[ "$x" =~ ^"??"[[:space:]]+ ]]; then 
                untracked_counter=$[untracked_counter + 1] 
            fi

        done <<< "$status_command"
    }

    #
    # Creates the string that displays staging and stash counts
    #
    # Example: 5∙2∙3∙15
    #
    # - First number is cyan, and is the number of staged modifications
    # - Second number is red, and is the number of unstaged modifications
    # - Third number is orange, and the is number of untracked files
    # - Fourth number is gray, and is the number of stashed changes
    #
    function buildStagingString()
    {
        if [[ $staged_counter > 0 ]]; then
            stage_string+="${P_VERY_DARK_GRAY}∙${P_BRIGHT_CYAN}${staged_counter}"
        fi

        if [[ $unstaged_counter > 0 ]]; then
            stage_string+="${P_VERY_DARK_GRAY}∙${P_RED}${unstaged_counter}"
        fi

        if [[ $untracked_counter > 0 ]]; then
            stage_string+="${P_VERY_DARK_GRAY}∙${P_ORANGE}${untracked_counter}"
        fi

        if [[ $stash_counter > 0 ]]; then
            stage_string+="${P_VERY_DARK_GRAY}∙${P_DARK_GRAY}${stash_counter}"
        fi

        stage_string+="${P_NC}"
    }

    #
    # Builds the string that shows how many commits ahead or behind the local branch is
    #
    # Example: [+10-5]
    #
    function buildDifferenceString()
    {
        if [[ -n "$branch" && $ahead > 0 && $behind == 0 ]]; then
            difference_string+="$P_DARK_GRAY[+$ahead] "
        fi

        if [[ -n "$branch" && $behind > 0 && $ahead == 0 ]]; then
            difference_string+="$P_DARK_GRAY[-$behind] "
        fi

        if [[ -n "$branch" && $ahead > 0 && $behind > 0 ]]; then
            difference_string+="$P_DARK_GRAY[+$ahead-$behind] "
        fi
    }
    
    #
    # Gets the icon for the current branch status
    #
    # * indicates the branch is out of sync with remote (either ahead or behind) 
    # ✓ indicates everything is ok! 
    # ⚠︎ indicates there are conflicts
    #
    function determineBranchStatus()
    {
        if [[ $ahead > 0 || $behind > 0 ]]; then
            branch_status=" *"
        fi

        if [[ $conflicts_counter > 0 ]]; then
            branch_status=" ⚠︎ "
        fi 

        if [[ $unstaged_counter == 0 && $staged_counter == 0 && $conflicts_counter == 0 && $ahead == 0 && $behind == 0 ]]; then
            branch_status=" ✓"
        fi
    }

    #
    # Final assembly of the prompt string
    #
    function assemblePromptString()
    {
        if [ -z "$branch" ]; then
            prompt_string=""
        elif [[ $ahead > 0 || $behind > 0 ]]; then
            prompt_string="$P_LIGHT_GREEN${branch}${branch_status}"
        else
            prompt_string="$P_GREEN${branch}${branch_status}"
        fi

        if [[ -n "$branch" && $unstaged_counter > 0 ]]; then
            prompt_string="$P_RED${branch}${branch_status}"
        fi

        if [[ -n "$branch" && $staged_counter > 0 ]]; then
            prompt_string="$P_BRIGHT_CYAN${branch}${branch_status}"
        fi

        if [[ -n "$branch" && $conflicts_counter > 0 ]]; then
            prompt_string="$P_RED{${branch}${branch_status}} [CONFLICTS: $conflicts_counter] "
        fi

        if [[ $difference_string != "" ]]; then
            prompt_string+="${difference_string}"
        fi

        echo "$LIGHTGREY-$GREY[${prompt_string}${stage_string}$GREY] ${P_LIGHT_GRAY}"
    }

    parseStash
    parseStatus
    buildStagingString
    buildDifferenceString
    determineBranchStatus
    assemblePromptString

    return $exit
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
PS1="$GREY[$LIGHTGREY\$(date +%l)$ORANGE:$LIGHTGREY\$(date +%M) $ORANGE\$(date +%p)$SEP$BLUE\u$RED@$ORANGE\h$SEP$BLUE\w$GREY$SEP$RED$FILES$GREY]`getGitPrompt` $DEFAULT\n"'$ '
}
PROMPT_COMMAND=_prompt_command
