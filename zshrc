# Path to Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Disable oh-my-zsh theme (using starship instead)
ZSH_THEME=""

# Enable plugins
plugins=(
    aws
    emacs
    extract
    git
    history
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# Dracula theme for zsh-syntax-highlighting
# https://github.com/dracula/zsh-syntax-highlighting (MIT, George Pickering, Zeno Rocha)
# Set before oh-my-zsh loads the plugin, whose defaults only fill unset styles.
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main cursor)
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[comment]='fg=#6272A4'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#50FA7B'
ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=#50FA7B'
ZSH_HIGHLIGHT_STYLES[global-alias]='fg=#50FA7B'
ZSH_HIGHLIGHT_STYLES[function]='fg=#50FA7B'
ZSH_HIGHLIGHT_STYLES[command]='fg=#50FA7B'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#50FA7B,italic'
ZSH_HIGHLIGHT_STYLES[autodirectory]='fg=#FFB86C,italic'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#FFB86C'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#FFB86C'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=#BD93F9'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#8BE9FD'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#8BE9FD'
ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=#8BE9FD'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#FF79C6'
ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]='fg=#F8F8F2'
ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter-unquoted]='fg=#F8F8F2'
ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]='fg=#F8F8F2'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument-delimiter]='fg=#FF79C6'
ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]='fg=#FF79C6'
ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]='fg=#FF79C6'
ZSH_HIGHLIGHT_STYLES[command-substitution-quoted]='fg=#F1FA8C'
ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter-quoted]='fg=#F1FA8C'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#F1FA8C'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument-unclosed]='fg=#FF5555'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#F1FA8C'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument-unclosed]='fg=#FF5555'
ZSH_HIGHLIGHT_STYLES[rc-quote]='fg=#F1FA8C'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#F8F8F2'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument-unclosed]='fg=#FF5555'
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=#F8F8F2'
ZSH_HIGHLIGHT_STYLES[assign]='fg=#F8F8F2'
ZSH_HIGHLIGHT_STYLES[named-fd]='fg=#F8F8F2'
ZSH_HIGHLIGHT_STYLES[numeric-fd]='fg=#F8F8F2'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#FF5555'
ZSH_HIGHLIGHT_STYLES[path]='fg=#F8F8F2'
ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=#FF79C6'
ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=#F8F8F2'
ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]='fg=#FF79C6'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#F8F8F2'
ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=#BD93F9'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument-unclosed]='fg=#FF5555'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#F8F8F2'
ZSH_HIGHLIGHT_STYLES[arg0]='fg=#F8F8F2'
ZSH_HIGHLIGHT_STYLES[default]='fg=#F8F8F2'
ZSH_HIGHLIGHT_STYLES[cursor]='standout'

# Load Oh My Zsh
source "$ZSH/oh-my-zsh.sh"

# Starship prompt
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
eval "$(starship init zsh)"

# Enable history sharing across terminals
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
# A leading space keeps a command out of the history, e.g. one with a token in it
setopt HIST_IGNORE_SPACE
HISTSIZE=50000
SAVEHIST=100000

# Editor
export EDITOR="emacs"
export VISUAL="$EDITOR"
export GIT_EDITOR="$EDITOR"

# Aliases
alias ll='ls -lah'

# extra_config for special variables for personnal or job configs
[ -f ~/.extra_config ] && source ~/.extra_config

# PATHs
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.config/emacs/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"
export PATH="$HOME/.pi/agent/bin:$PATH"
export PATH="$HOME/.cargo/bin/:$PATH"

# PyEnv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Telemetry opt-outs
# Claude Code: usage metrics, error reports, surveys. NONESSENTIAL_TRAFFIC is
# deliberately not used because it also kills the autoupdater.
export DISABLE_TELEMETRY=1
export DISABLE_ERROR_REPORTING=1
export CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY=1
# Superpowers visual companion fetches a version-tagged logo from primeradiant.com
export SUPERPOWERS_DISABLE_TELEMETRY=1
# RTK sends an anonymous daily ping
export RTK_TELEMETRY_DISABLED=1
# huggingface_hub (hf CLI)
export HF_HUB_DISABLE_TELEMETRY=1
# Catch-all convention honoured by many CLIs (consoledonottrack.com)
export DO_NOT_TRACK=1

# Zellij auto-start, written out rather than `zellij setup --generate-auto-start`:
# that one only checks $ZELLIJ, so an Emacs started from a zellij pane inherited
# it and every ghostel terminal silently got a plain shell.

# Print a live session no client is attached to, such as the one a crashed
# Alacritty left behind, so a new window picks it up instead of starting
# another. emacs-* sessions belong to Emacs, which reattaches them itself.
my_zellij_orphan() {
    local session
    for session in ${(f)"$(zellij list-sessions --no-formatting 2>/dev/null \
        | awk '!/EXITED/ && $1 !~ /^emacs-/ { print $1 }')"}; do
        # A header line, then one line per attached client
        if (( $(zellij --session "$session" action list-clients 2>/dev/null | wc -l) == 1 )); then
            print -r -- "$session"
            return 0
        fi
    done
    return 1
}

if [[ -z "$ZELLIJ" ]]; then
    if [[ -n "$MY_ZELLIJ_SESSION" ]]; then
        # An Emacs project terminal: a named session that outlives Emacs, so a
        # crash only detaches it. Exit with zellij (detach, quit) to close the
        # buffer, but stay on an error so it can be read.
        # A session the zellij server lost (reboot, logout) is listed as EXITED,
        # and attaching resurrects it with its agent suspended behind an "ENTER
        # to run" prompt, outside any shell. Its processes are gone anyway, so
        # start afresh and let MY_ZELLIJ_RUN type the agent into zsh again.
        if zellij list-sessions --no-formatting 2>/dev/null \
                | awk -v s="$MY_ZELLIJ_SESSION" '$1 == s && /EXITED/ { found = 1 } END { exit !found }'; then
            zellij delete-session "$MY_ZELLIJ_SESSION"
        fi
        zellij attach --create "$MY_ZELLIJ_SESSION" && exit
    elif [[ "${INSIDE_EMACS%%,*}" != ghostel ]]; then
        # Plain ghostel terminals (M-x ghostel) skip this and stay plain zsh.
        if my_zellij_orphan_session="$(my_zellij_orphan)"; then
            zellij attach "$my_zellij_orphan_session"
        else
            zellij
        fi
        unset my_zellij_orphan_session
    fi
fi

# Inside a session Emacs created for its agent, the first pane runs
# MY_ZELLIJ_RUN as if typed: it lands in history, and quitting it leaves this
# shell. Reattaching to a live session spawns no shell, so it never runs twice,
# and unsetting it keeps the agent and later panes from inheriting it.
if [[ -n "$ZELLIJ" && -n "$MY_ZELLIJ_RUN" ]]; then
    if [[ "$ZELLIJ_PANE_ID" == 0 ]]; then
        typeset -g my_zellij_run="$MY_ZELLIJ_RUN"
        my_zellij_run_once() {
            add-zle-hook-widget -d line-init my_zellij_run_once
            BUFFER="$my_zellij_run"
            unset my_zellij_run
            zle accept-line
        }
        # The hook API, not zle-line-init itself, which plugins may own
        autoload -Uz add-zle-hook-widget
        add-zle-hook-widget line-init my_zellij_run_once
    fi
    unset MY_ZELLIJ_RUN
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
