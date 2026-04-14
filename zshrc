# Path to Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Disable oh-my-zsh theme (using starship instead)
ZSH_THEME=""

# Enable plugins
plugins=(
    emacs
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    history
    extract
    tmux
)

# Enable command auto-correction (must be set before sourcing oh-my-zsh)
export ENABLE_CORRECTION="true"

# Tmux: auto-start a session on new terminal (must be set before sourcing oh-my-zsh)
ZSH_TMUX_AUTOSTART=true

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Starship prompt
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
eval "$(starship init zsh)"

# Enable history sharing across terminals
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
HISTSIZE=50000
SAVEHIST=100000

# Aliases
alias ll='ls -lah'
alias gs='git status'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --all'
alias hx='helix'

# extra_config for special variables for personnal or job configs
[ -f ~/.extra_config ] && source ~/.extra_config

# PATHs
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.config/emacs/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"

# PyEnv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# RTK
export RTK_TELEMETRY_DISABLED=1

# BEGIN opam configuration
# This is useful if you're using opam as it adds:
#   - the correct directories to the PATH
#   - auto-completion for the opam binary
# This section can be safely removed at any time if needed.
[[ ! -r '/home/loic/.opam/opam-init/init.zsh' ]] || source '/home/loic/.opam/opam-init/init.zsh' > /dev/null 2> /dev/null
# END opam configuration

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
