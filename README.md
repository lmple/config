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
sudo pacman -S --needed alacritty ttf-firacode-nerd zellij wl-clipboard xclip

# Editors (Mason in nvim also needs Node from NVM below)
sudo pacman -S --needed emacs neovim python-pynvim tree-sitter-cli lazygit

# Languages and LSP servers: Doom (sh +lsp), (cc +lsp), (javascript +lsp), nvim lua/bash packs
sudo pacman -S --needed python-pipx rustup shellcheck shfmt bash-language-server \
  clang typescript-language-server prettier lua-language-server stylua
rustup default stable
rustup component add rust-analyzer

# Doom modules: spell (English + French dictionaries), pass, graphviz, org +pandoc/+gnuplot, pdf (poppler-glib)
sudo pacman -S --needed aspell aspell-en aspell-fr pass graphviz pandoc-cli gnuplot poppler-glib
```

Optional, heavy (several GB, mostly TeX Live):

```sh
# LaTeX (Doom latex, nvim vimtex): the texlive group is the full TeX Live minus
# languages, so add French. It brings latexmk (both editors compile with it) and
# chktex (Doom's checker) via texlive-binextra. biber backs biblatex, and the perl
# modules let texlab format with latexindent.
sudo pacman -S --needed texlive texlive-langfrench biber texlab \
  perl-yaml-tiny perl-file-homedir zathura zathura-pdf-mupdf

# Grammar checking, PlantUML, Jupyter (ein, jupynium)
sudo pacman -S --needed languagetool plantuml jupyter-notebook
```

## Ubuntu 26.04 dependencies

Most packages live in `universe`, which is enabled by default on desktop installs.

```sh
# Base tooling, plus the -dev libraries needed to build pdf-tools and pyenv Pythons
sudo apt install git build-essential curl wget unzip pkg-config autoconf automake \
  libpoppler-glib-dev libpng-dev zlib1g-dev libssl-dev libbz2-dev libreadline-dev \
  libsqlite3-dev libncurses-dev xz-utils tk-dev libffi-dev liblzma-dev libxml2-dev

# Shell: Ubuntu ships fd as fdfind, link it so both editors find it as fd
sudo apt install zsh starship pyenv direnv fzf ripgrep fd-find
mkdir -p ~/.local/bin && ln -sf "$(command -v fdfind)" ~/.local/bin/fd

# Terminal: FiraCode Nerd Font is not packaged, install it per user
sudo apt install alacritty wl-clipboard xclip
mkdir -p ~/.local/share/fonts/FiraCodeNerd
curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.tar.xz \
  | tar -xJ -C ~/.local/share/fonts/FiraCodeNerd && fc-cache -f

# Editors (use emacs-gtk instead of emacs-pgtk on X11)
sudo apt install emacs-pgtk neovim python3-pynvim tree-sitter-cli lazygit

# Languages and LSP servers; zellij is not packaged, so build it with cargo
sudo apt install pipx rustup shellcheck shfmt clang clangd
rustup default stable
rustup component add rust-analyzer
cargo install --locked zellij

# Node-based LSP servers are not packaged (needs Node from NVM below);
# lua-language-server and stylua come from Mason (nvim/lua/plugins/mason.lua)
npm install -g bash-language-server typescript-language-server typescript prettier

# Doom modules: spell (English + French dictionaries), pass, graphviz, org +pandoc/+gnuplot
sudo apt install aspell aspell-en aspell-fr pass graphviz pandoc gnuplot
```

Optional, heavy (LanguageTool is not packaged, Doom's grammar module just warns without it):

```sh
# LaTeX (Doom latex, nvim vimtex): texlive-full is the full TeX Live, every language
# included, and already pulls in latexmk, chktex and biber
sudo apt install texlive-full texlab zathura

# PlantUML, Jupyter (ein, jupynium)
sudo apt install plantuml jupyter-notebook
```

## Firewall (ufw)

Deny unsolicited inbound traffic, allow all outbound. EndeavourOS enables firewalld
out of the box; two firewalls rewriting the same nftables rules conflict, so turn it
off before enabling ufw.

```sh
# Arch / EndeavourOS
sudo pacman -S --needed ufw
sudo systemctl disable --now firewalld   # only if installed (EndeavourOS default)
sudo systemctl enable --now ufw          # loads the rules at boot

# Ubuntu ships ufw installed but inactive
sudo apt install ufw
```

```sh
# Both distros
sudo ufw default deny incoming
sudo ufw default allow outgoing

# KDE Connect / GSConnect pair and transfer over 1714-1764
sudo ufw allow 1714:1764/tcp
sudo ufw allow 1714:1764/udp

# Only if this machine runs an SSH server: rate-limit repeated login attempts
# sudo ufw limit ssh

sudo ufw enable
sudo ufw status verbose
```

## Local LLM (llama.cpp)

Doom's gptel (`C-c o l l`) talks to a local `llama-server` on port 8080, serving
Gemma 4 12B under the name `gemma-4-12b` (see `doom/config.el`). Start it by hand
when needed; the first run downloads the model into `~/.cache/huggingface`.

```sh
# Arch / EndeavourOS (AUR)
paru -S llama.cpp-cuda

# The repo only publishes Q4_0, Q8_0 and BF16; Q4_0 is the one that fits an 8 GB
# GPU. --fit picks GPU layers for a 16k context, and the q8_0 KV cache saves
# memory. Bound to 127.0.0.1 and CORS-restricted to localhost, so neither other
# machines nor web pages in the browser can reach it.
llama-server -hf ggml-org/gemma-4-12B-it-GGUF:Q4_0 --alias gemma-4-12b \
  --host 127.0.0.1 --port 8080 --cors-origins localhost --no-cors-credentials \
  --no-mmproj -np 1 --fit-ctx 16384 -ctk q8_0 -ctv q8_0
```

Gemma 4 needs a recent build (version 8589 fails with "unknown model architecture:
'gemma4'"; 10217 works). Check `llama-server --version`: an older copy in
`/usr/local/bin` takes precedence over the package's `/usr/bin`.

## Toolchains (both distros)

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
