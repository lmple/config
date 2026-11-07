# ZSH
ln -s "$(pwd)/zshrc" "$HOME/.zshrc"

# Starship
ln -s "$(pwd)/starship.toml" "$HOME/.config/starship.toml"

# Zellij
ln -sfn "$(pwd)/zellij" "$HOME/.config/zellij"

# Alacritty
ln -sfn "$(pwd)/alacritty" "$HOME/.config/alacritty"

# Doom Emacs
ln -sfn "$(pwd)/doom" "$HOME/.config/doom"

# llama-server presets and its user service (enable it per machine, see README)
ln -sfn "$(pwd)/llama" "$HOME/.config/llama"
mkdir -p "$HOME/.config/systemd/user"
ln -sf "$(pwd)/systemd/llama-server@.service" "$HOME/.config/systemd/user/llama-server@.service"
