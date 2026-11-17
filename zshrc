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

# Ashen palette for zsh-syntax-highlighting, matching the vendored Emacs theme
# (doom/themes/ashen-theme.el): strings and keywords use its font-lock colours,
# and commands use orange-glow, the colour Ashen puts in the terminal's green
# slot. Set before oh-my-zsh loads the plugin, whose defaults only fill unset styles.
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main cursor)
typeset -gA ZSH_HIGHLIGHT_STYLES
() {
    local fg='#b4b4b4' comment='#535353' command='#d87c4a' option='#e49a44'
    local string='#df6464' keyword='#b14242' builtin='#4a8b8b'
    local separator='#c4693d' error='#c53030'
    ZSH_HIGHLIGHT_STYLES[comment]="fg=$comment,italic"
    ZSH_HIGHLIGHT_STYLES[alias]="fg=$command"
    ZSH_HIGHLIGHT_STYLES[suffix-alias]="fg=$command"
    ZSH_HIGHLIGHT_STYLES[global-alias]="fg=$command"
    ZSH_HIGHLIGHT_STYLES[function]="fg=$command"
    ZSH_HIGHLIGHT_STYLES[command]="fg=$command"
    ZSH_HIGHLIGHT_STYLES[hashed-command]="fg=$command"
    ZSH_HIGHLIGHT_STYLES[precommand]="fg=$command,italic"
    ZSH_HIGHLIGHT_STYLES[builtin]="fg=$builtin"
    ZSH_HIGHLIGHT_STYLES[reserved-word]="fg=$keyword"
    ZSH_HIGHLIGHT_STYLES[autodirectory]="fg=$option,italic"
    ZSH_HIGHLIGHT_STYLES[single-hyphen-option]="fg=$option"
    ZSH_HIGHLIGHT_STYLES[double-hyphen-option]="fg=$option"
    ZSH_HIGHLIGHT_STYLES[back-quoted-argument]="fg=$builtin"
    ZSH_HIGHLIGHT_STYLES[history-expansion]="fg=$builtin"
    ZSH_HIGHLIGHT_STYLES[commandseparator]="fg=$separator"
    ZSH_HIGHLIGHT_STYLES[back-quoted-argument-delimiter]="fg=$separator"
    ZSH_HIGHLIGHT_STYLES[path_pathseparator]="fg=$separator"
    ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]="fg=$separator"
    # Escapes inside strings, like the theme's font-lock-escape-face
    ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]="fg=$option"
    ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]="fg=$option"
    ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg=$string"
    ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=$string"
    ZSH_HIGHLIGHT_STYLES[rc-quote]="fg=$string"
    ZSH_HIGHLIGHT_STYLES[command-substitution-quoted]="fg=$string"
    ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter-quoted]="fg=$string"
    ZSH_HIGHLIGHT_STYLES[single-quoted-argument-unclosed]="fg=$error"
    ZSH_HIGHLIGHT_STYLES[double-quoted-argument-unclosed]="fg=$error"
    ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument-unclosed]="fg=$error"
    ZSH_HIGHLIGHT_STYLES[back-quoted-argument-unclosed]="fg=$error"
    ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=$error"
    local style
    for style in command-substitution-delimiter \
        command-substitution-delimiter-unquoted process-substitution-delimiter \
        dollar-quoted-argument dollar-double-quoted-argument assign named-fd \
        numeric-fd path path_prefix globbing redirection arg0 default; do
        ZSH_HIGHLIGHT_STYLES[$style]="fg=$fg"
    done
}
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
# zsh rewrites the file from the in-memory list, so SAVEHIST above HISTSIZE
# would still cap the file at HISTSIZE.
HISTSIZE=100000
SAVEHIST=100000

# Editor: git and other tools exec this directly, bypassing oh-my-zsh's emacs
# alias, so plain "emacs" booted a second full Doom for every commit message.
# emacsclient reuses the daemon in the current terminal; -a '' starts one if
# none is running.
export EDITOR="emacsclient -t -a ''"
export VISUAL="$EDITOR"
export GIT_EDITOR="$EDITOR"

# Aliases
alias ll='ls -lah'

# extra_config for special variables for personnal or job configs
[ -f ~/.extra_config ] && source ~/.extra_config

# PATHs
# Unique entries only: every zellij pane is a nested shell that inherits PATH
# and would otherwise prepend each of these again.
typeset -U path PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.config/emacs/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"
export PATH="$HOME/.pi/agent/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

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

# nvm resolving its default alias took ~1.2 s of a 1.6 s startup, paid by every
# zellij pane and Emacs terminal. --no-use loads only the nvm command; the
# newest installed Node goes on PATH directly, which is what the default alias
# `node` resolves to anyway. `nvm use` still switches per project.
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
my_node_bin=( "$NVM_DIR"/versions/node/*(N/nOn[1]) )
(( $#my_node_bin )) && export PATH="$my_node_bin[1]/bin:$PATH"
unset my_node_bin

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
