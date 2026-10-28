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

# Load Oh My Zsh
source "$ZSH/oh-my-zsh.sh"

# Starship prompt
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
eval "$(starship init zsh)"

# Enable history sharing across terminals
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
HISTSIZE=50000
SAVEHIST=100000

# Editor
export EDITOR="emacs"
export VISUAL="$EDITOR"
export GIT_EDITOR="$EDITOR"

# Aliases
alias ll='ls -lah'
alias nv='nvim'

# extra_config for special variables for personnal or job configs
[ -f ~/.extra_config ] && source ~/.extra_config

# PATHs
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.config/emacs/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"
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

eval "$(zellij setup --generate-auto-start zsh)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
