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

Doom's gptel talks to a local `llama-server` on port 8080, run in router mode: one
server offers every model in a presets file and loads whichever one gptel asks for.
gptel reads that list from the server, so the presets file is the only list of
models to maintain.

| File | GPU | Models (gptel names) |
| --- | --- | --- |
| `llama/home.ini` | 8 GB | `gemma-4-12b` |
| `llama/work.ini` | 24 GB | `gemma-4-26b-a4b` (default), `qwen3-coder-30b`, `gemma-4-31b` |

The Emacs side is the `;;; LLM` section of `doom/config.el`.

### Install

```sh
# Arch / EndeavourOS (AUR)
paru -S llama.cpp-cuda
llama-server --version   # 10217 works; 8589 fails with "unknown model architecture: 'gemma4'"
```

An older hand-built copy in `/usr/local/bin` takes precedence over the package's
`/usr/bin`; remove it if `--version` shows an old build.

### Start the server

Start it by hand in a terminal and leave it running; `Ctrl-C` stops it. It is ready
once it prints `listening on http://127.0.0.1:8080`, and the default model
(`load-on-startup`) loads right after: about 10 s for the home 12B once downloaded,
longer for the bigger work models.

```sh
# Home (8 GB GPU)
llama-server --models-preset ~/sources/config/llama/home.ini --models-max 1 \
  --host 127.0.0.1 --port 8080 --cors-origins localhost --no-cors-credentials

# Work (24 GB GPU)
llama-server --models-preset ~/sources/config/llama/work.ini --models-max 1 \
  --host 127.0.0.1 --port 8080 --cors-origins localhost --no-cors-credentials
```

- `--models-max 1` keeps a single model in VRAM: switching unloads the previous one.
- `--host 127.0.0.1` keeps other machines out, and `--cors-origins localhost
  --no-cors-credentials` stops web pages open in the browser from using the server
  (by default it accepts any origin and has no API key).
- The first time a model is used, it is downloaded into `~/.cache/huggingface`
  (15-18 GB for the work models), and that first request waits for the download.

### Use it from Emacs

| Key | Action |
| --- | --- |
| `C-c o l l` | Open a gptel chat buffer |
| `C-c RET` | Send, in a chat buffer |
| `C-c o l s` | Send from any buffer: the region, or the text up to point |
| `C-c o l m` | Menu: pick the model (refreshed from the server on every open), tools, options |
| `C-c o l r` | Rewrite the region |
| `C-c o l a` / `C-c o l f` | Add the region / a file to the context |

The model can use these tools on its own. Relative paths resolve against the project
of the buffer gptel was opened from, and output is capped at 32,000 characters.

- `read_file`, `list_directory`, `search_project` (ripgrep), `list_buffers`,
  `read_buffer` (including unsaved changes): run without asking.
- `write_file`: gptel shows the proposed call in the buffer and waits; `C-c C-c`
  runs it, `C-c C-k` rejects it.

### Add or change a model

Add a section to the machine's presets file and restart the server. The section name
is the model name gptel shows; the other keys are `llama-server` flags without the
leading dashes, and `[*]` holds the settings every model shares.

```ini
[my-model]
hf-repo = ggml-org/<repo>-GGUF:<quant>   ; the quants a repo offers are listed on Hugging Face
c = 32768                                ; context size; keep it at 16384 or more
load-on-startup = true                   ; optional, one model per file: the default
```

Keep every context at 16384 or more: the tools cap their output for a 16k context.
The work context sizes are estimates, so on first use of each model, check what it
got and whether it fits in VRAM, and lower `c` if it spills onto the CPU:

```sh
curl -s 'localhost:8080/props?model=gemma-4-26b-a4b' | grep -o '"n_ctx":[0-9]*'
nvidia-smi --query-gpu=memory.used,memory.total --format=csv
```

### Troubleshooting

- **gptel says "Curl failed with exit code 7"**: nothing is listening on port 8080;
  start the server.
- **A model is missing from gptel's menu**: check what the server offers with
  `curl -s localhost:8080/v1/models`. Only `source: preset` entries are shown (the
  server also lists everything in the Hugging Face cache); after editing a presets
  file, restart the server.
- **The first answer after switching model is slow**: the server is loading it
  (downloading it, the first time); later requests are fast.
- **`no GGUF files found in repository`**: the quant in `hf-repo` isn't published
  (any more); pick one the repo lists in that error.

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
