# config

ZSH extra config: `~/.extra_config`

Doom packages extra: `doom/extra_packages.el`

Doom config extra: `doom/extra_config.el`

## Arch Linux dependencies

```sh
# Base tooling (base-devel builds pdf-tools, tree-sitter grammars and AUR packages)
sudo pacman -S --needed git base-devel curl wget unzip

# Shell: zshrc loads starship, pyenv and direnv; fzf/ripgrep/fd back fuzzy search in both editors
sudo pacman -S --needed zsh starship pyenv direnv fzf ripgrep fd

# Terminal: zshrc auto-starts zellij; alacritty and Doom use FiraCode Nerd Font
sudo pacman -S --needed alacritty ttf-firacode-nerd zellij tmux wl-clipboard xclip

# Editors (Mason in nvim also needs Node from NVM below)
sudo pacman -S --needed emacs neovim python-pynvim tree-sitter-cli lazygit

# Languages and LSP servers: Doom (sh +lsp), (cc +lsp), (javascript +lsp), nvim lua/bash packs
sudo pacman -S --needed python-pipx rustup shellcheck shfmt bash-language-server \
  clang typescript-language-server prettier lua-language-server stylua
rustup default stable
rustup component add rust-analyzer

# Doom modules: spell, pass, graphviz, org +pandoc/+gnuplot, pdf (poppler-glib)
sudo pacman -S --needed aspell aspell-en pass graphviz pandoc-cli gnuplot poppler-glib
```

Optional, heavy (several GB, mostly TeX Live):

```sh
# LaTeX (Doom latex, nvim vimtex), grammar checking, PlantUML, Jupyter (ein, jupynium)
sudo pacman -S --needed texlive-basic texlive-latexextra texlab zathura zathura-pdf-mupdf \
  languagetool plantuml jupyter-notebook
```

Toolchains not in the official repos:

```sh
# Lean 4
curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh

# TLA+: nvim/lua/plugins/tlaplus.lua expects the jar here (Java comes from SDKMAN below)
mkdir -p ~/.local/lib/tlaplus
curl -fsSL -o ~/.local/lib/tlaplus/tla2tools.jar \
  https://github.com/tlaplus/tlaplus/releases/latest/download/tla2tools.jar

# Quint and its language server (needs Node from NVM below)
npm install -g @informalsystems/quint @informalsystems/quint-language-server
```

## SDK man

```sh
curl -s "https://get.sdkman.io" | bash
```

## Install Oh My Zsh

```sh
# oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

## pipx

```sh
pipx install ruff mypy pylint basedpyright
```

## NVM

```sh
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
```

## Install config

```sh
./install.sh
```

## Doom Emacs

Run after `./install.sh` so `~/.config/doom` already points at this repo.

```sh
git clone --depth 1 https://github.com/doomemacs/core ~/.config/emacs
~/.config/emacs/bin/doom install
```
