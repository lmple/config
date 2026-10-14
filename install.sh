# ZSH
ln -s "$(pwd)/zshrc" "$HOME/.zshrc"

# Starship
ln -s "$(pwd)/starship.toml" "$HOME/.config/"

# Alacritty
ln -sfn "$(pwd)/alacritty" "$HOME/.config/alacritty"

# zellij
ln -sfn "$(pwd)/zellij" "$HOME/.config/zellij"

# nvim
ln -sfn "$(pwd)/nvim" "$HOME/.config/nvim"

# doom emacs
ln -sfn "$(pwd)/doom" "$HOME/.config/doom"
