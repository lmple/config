# Path to Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Disable oh-my-zsh theme (using starship instead)
ZSH_THEME=""

# Enable plugins
plugins=(
    aws
    emacs
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    history
    extract
    tmux
)

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

# Editor
export EDITOR="emacs"
export VISUAL="emacs"
export GIT_EDITOR="emacs"

# Aliases
alias ll='ls -lah'
alias tlc="java -cp $HOME/.local/bin/tla2tools.jar tlc2.TLC"

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

# RTK
export RTK_TELEMETRY_DISABLED=1

# BEGIN opam configuration
# This is useful if you're using opam as it adds:
#   - the correct directories to the PATH
#   - auto-completion for the opam binary
# This section can be safely removed at any time if needed.
[[ ! -r '/home/loic/.opam/opam-init/init.zsh' ]] || source '/home/loic/.opam/opam-init/init.zsh' > /dev/null 2> /dev/null
# END opam configuration

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
