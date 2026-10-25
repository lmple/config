# ZSH
ln -s "$(pwd)/zshrc" "$HOME/.zshrc"

# Starship
ln -s "$(pwd)/starship.toml" "$HOME/.config/starship.toml"

# Zellij
ln -sfn "$(pwd)/zellij" "$HOME/.config/zellij"

# Alacritty
ln -sfn "$(pwd)/alacritty" "$HOME/.config/alacritty"

# nvim
ln -sfn "$(pwd)/nvim" "$HOME/.config/nvim"

# Doom Emacs
ln -sfn "$(pwd)/doom" "$HOME/.config/doom"
