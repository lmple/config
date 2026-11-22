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
# Inside Emacs's own terminals (zellij panes included, which inherit
# INSIDE_EMACS), a terminal frame nested in the pane is awkward, so open a
# buffer in the Emacs frame instead; -r makes a frame if the daemon has none.
# C-x # finishes, e.g. a git commit or Claude Code's Ctrl-G prompt.
if [[ -n "$INSIDE_EMACS" ]]; then
    export EDITOR="emacsclient -r -a ''"
else
    export EDITOR="emacsclient -t -a ''"
fi
export VISUAL="$EDITOR"
export GIT_EDITOR="$EDITOR"

# Aliases
alias ll='ls -lah'
# pi on the local model, as in the main session's pi pane (pi/local.sh)
alias pi-local='~/.config/pi/local.sh'

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

# Helix built by deps.sh --helix needs no HELIX_RUNTIME: deps.sh links the
# runtime beside the binary, which every shell finds, old ones included.

# Without it, the Steel build runs a workspace's .helix/helix.scm and init.scm
# instead of ours whenever both exist, with no workspace trust check: any repo
# could run Scheme, and so shell commands, when `hx .` opens it (as `cockpit`
# does). Set, it is the only place Helix reads them from. The hx wrapper
# (helix/hx.sh) sets it as well, for shells started before this line; this
# covers the binary run directly, as hx-steel.
export HELIX_STEEL_CONFIG="$HOME/.config/helix"

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
        # Every window joins one general session, so a crashed window's
        # shells are in the next one. Windows share it but not their view:
        # with mirror_session off, each can be on its own tab. Projects get
        # their own cockpit-* sessions (`cockpit` below), Emacs its emacs-*.
        # A new main gets its layout (zellij/layouts/main.kdl: a shell and pi
        # on the local model), created first and joined after, as in
        # my_cockpit_session: --layout given to a live session adds a tab to
        # it. An exited main (after a reboot) is listed, so it resurrects.
        if ! zellij list-sessions --no-formatting 2>/dev/null \
                | awk '$1 == "main" { found = 1 } END { exit !found }'; then
            zellij --layout main attach --create-background main
        fi
        zellij attach --create main
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

# Print the name of the zellij cockpit session (zellij/layouts/cockpit.kdl) of
# the project at directory $1, creating the session detached if it isn't live.
my_cockpit_session() {
    local dir=${1:A}
    if [[ ! -d $dir ]]; then
        print -u2 -r -- "cockpit: $dir is not a directory"
        return 1
    fi
    # The project is the nearest directory with a .git (a file in a worktree),
    # found without running git, which runs the filters a repo's config names.
    local root=$dir
    until [[ -e $root/.git || $root == / ]]; do root=${root:h}; done
    [[ -e $root/.git ]] || root=$dir
    # Named after the project alone, so `zellij ls` and Ctrl o w read well;
    # the truncation keeps zellij's socket path under its limit.
    local name=${${root:t}[1,32]//[^A-Za-z0-9_-]/-}
    local session="cockpit-$name"
    local state=$(zellij list-sessions --no-formatting 2>/dev/null \
        | awk -v s="$session" '$1 == s { print (/EXITED/ ? "exited" : "live") }')
    # Without a hash, two projects with the same directory name share a
    # name, so each cockpit records its root when created. A record is only
    # read while its session is live, and sits in the runtime dir, which a
    # reboot clears along with those sessions; a live one without a record
    # (made by hand) isn't checked.
    local roots=${XDG_RUNTIME_DIR:-/tmp/cockpit-$UID}/cockpit-roots
    if [[ $state == live && -r $roots/$session && $(<$roots/$session) != $root ]]; then
        print -u2 -r -- "cockpit: $session is already the cockpit of $(<$roots/$session)"
        return 1
    fi
    # A session the server lost (reboot, logout) resurrects with its editor
    # and agent behind "ENTER to run"; their processes are gone, so start over.
    if [[ $state == exited ]]; then
        zellij delete-session "$session" >/dev/null || return
    fi
    if [[ $state != live ]]; then
        # Created first and joined after: `switch-session --layout` would also
        # stack the layout onto a session that already exists. The subshell
        # drops the current session's variables, which would otherwise make
        # zellij act on it and reach the new panes.
        ( cd "$root" && unset ZELLIJ ZELLIJ_PANE_ID ZELLIJ_SESSION_NAME &&
              zellij --layout cockpit attach --create-background "$session" ) \
            || return
        mkdir -p -m 700 $roots && print -r -- $root >| $roots/$session
    fi
    print -r -- "$session"
}

# cockpit [DIR]: go to the cockpit of the project at DIR (default: here), the
# zellij counterpart of Emacs's C-c p p. Its session outlives the terminal, so
# after a crash or a detach, running this again brings the same editor, agent
# and shell back; the agent only starts when the session is created.
cockpit() {
    local session
    session=$(my_cockpit_session "${1:-$PWD}") || return
    if [[ -n $ZELLIJ ]]; then
        # Attaching from inside a pane would nest a zellij in it
        zellij action switch-session "$session"
    else
        zellij attach "$session"
    fi
}

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
