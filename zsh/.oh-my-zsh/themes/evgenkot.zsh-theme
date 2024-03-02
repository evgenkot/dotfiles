# My custom theme:
#   - based on essembeh
#   - single line
#   - quite simple by default: user@host:$PWD
#   - green for local shell as non root
#   - yellow for ssh shell as non root
#   - red for root sessions
#   - prefix with remote address for ssh shells
#   - prefix to detect docker containers or chroot
#   - git plugin to display current branch and status

# git plugin 
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[cyan]%}("
ZSH_THEME_GIT_PROMPT_SUFFIX=") %{$reset_color%}"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%%"
ZSH_THEME_GIT_PROMPT_ADDED="+"
ZSH_THEME_GIT_PROMPT_MODIFIED="*"
ZSH_THEME_GIT_PROMPT_RENAMED="~"
ZSH_THEME_GIT_PROMPT_DELETED="!"
ZSH_THEME_GIT_PROMPT_UNMERGED="?"

function zsh_evgenkot_gitstatus {
	ref=$(git symbolic-ref HEAD 2> /dev/null) || return
	GIT_STATUS=$(git_prompt_status)
	if [[ -n $GIT_STATUS ]]; then
		GIT_STATUS=" $GIT_STATUS"
	fi
	echo "$ZSH_THEME_GIT_PROMPT_PREFIX${ref#refs/heads/}$GIT_STATUS$ZSH_THEME_GIT_PROMPT_SUFFIX"
}

# by default, use green for user@host and no prefix
local ZSH_EVGENKOT_COLOR="green"
local ZSH_EVGENKOT_PREFIX=""
if [[ -n "$SSH_CONNECTION" ]]; then
	# display the source address if connected via ssh
	ZSH_EVGENKOT_PREFIX="%{$fg[magenta]%}[$(echo $SSH_CONNECTION | awk '{print $1}')]%{$reset_color%} "
	# use yellow color to highlight a remote connection
	ZSH_EVGENKOT_COLOR="yellow"
elif [[ -r /etc/debian_chroot ]]; then 
	# prefix prompt in case of chroot
	ZSH_EVGENKOT_PREFIX="%{$fg[magenta]%}[chroot:$(cat /etc/debian_chroot)]%{$reset_color%} "
elif [[ -r /.dockerenv ]]; then
	# also prefix prompt inside a docker container
	ZSH_EVGENKOT_PREFIX="%{$fg[magenta]%}[docker]%{$reset_color%} "
fi
if [[ $UID = 0 ]]; then
	# always use red for root sessions, even in ssh
	ZSH_EVGENKOT_COLOR="red"
fi
PROMPT='${ZSH_EVGENKOT_PREFIX}%{$fg[$ZSH_EVGENKOT_COLOR]%}%n@%M%{$reset_color%}:%{%B$fg[magenta]%}%~%{$reset_color%b%} $(zsh_evgenkot_gitstatus)%(!.#.$) '
RPROMPT="%(?..%{$fg[yellow]%}%?%{$reset_color%})"
