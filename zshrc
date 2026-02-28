# Path to Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Set Powerlevel10k as the theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Enable plugins
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  history
  extract
)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Load Powerlevel10k configuration if exists
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Aliases
alias ll='ls -lah'
alias gs='git status'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --all'
alias hx='helix'

# PATHs
export PATH="$HOME/.local/bin:$PATH"

# PyEnv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

# Enable history sharing across terminals
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS

# Enable command auto-correction
ENABLE_CORRECTION="true"

# Enable command completions
autoload -Uz compinit && compinit

# Optional: Faster prompt
POWERLEVEL9K_DISABLE_RPROMPT=true

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
