# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi


# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
	for rc in ~/.bashrc.d/*; do
		if [ -f "$rc" ]; then
			. "$rc"
		fi
	done
fi

shopt -s histappend
PROMPT_COMMAND='history -a;history -n'

unset rc

# --- Kiro/VS Code shell integration + systemd OSC 3008 reconciliation ---
# systemd's /etc/profile.d/80-systemd-osc-context.sh turns PROMPT_COMMAND into an
# array by appending __systemd_osc_context_precmdline. Kiro's shell integration
# (shellIntegration-bash.sh) only wraps PROMPT_COMMAND element [0] and drives
# command detection from a DEBUG trap; any trailing array element then runs as its
# own top-level command that re-trips the trap and swallows command output in the
# integrated terminal. Collapsing PROMPT_COMMAND back to a single scalar string
# keeps both features: the systemd hook runs inside Kiro's prompt-command loop.
if [ -n "${VSCODE_SHELL_INTEGRATION:-}" ] && [ "${#PROMPT_COMMAND[@]}" -gt 1 ]; then
	__kiro_pc_joined=""
	for __kiro_pc in "${PROMPT_COMMAND[@]}"; do
		[ -n "$__kiro_pc" ] || continue
		if [ -n "$__kiro_pc_joined" ]; then
			__kiro_pc_joined="$__kiro_pc_joined;$__kiro_pc"
		else
			__kiro_pc_joined="$__kiro_pc"
		fi
	done
	unset PROMPT_COMMAND
	PROMPT_COMMAND="$__kiro_pc_joined"
	unset __kiro_pc __kiro_pc_joined
fi
