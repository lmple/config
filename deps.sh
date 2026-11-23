#!/usr/bin/env bash
# Install the system packages and toolchains this config expects.
# Steps run in a fixed order whatever the flag order, because later steps need
# earlier ones (npm needs Node from NVM, Doom needs the symlinks from install.sh).

# SC2016: run_sh snippets are single-quoted on purpose; they expand in the inner shell.
# shellcheck disable=SC2016

set -euo pipefail

REPO_DIR="$(dirname "$(realpath "$0")")"
readonly REPO_DIR
readonly NVM_DIR="$HOME/.nvm"
readonly ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
# Its runtime/ is linked beside the hx binary, see helix()
readonly HELIX_SRC="$HOME/.local/src/helix"

DRY_RUN=false

usage() {
  cat <<'EOF'
Usage: ./deps.sh [options]

Without options, installs the base set: distro packages, oh-my-zsh, Node (NVM),
the coding agents (Claude Code, opencode, pi), npm/pipx tools, Lean, Quint
and SDKMAN.

  --heavy       Also install TeX Live, LanguageTool, PlantUML, Jupyter (several GB)
  --firewall    Also install and configure ufw (deny inbound, allow KDE Connect)
  --llama       Also install llama.cpp with the llama.app installer, on every
                distro: CUDA/ROCm/Vulkan/CPU build into ~/.local/bin/llama
  --helix       Also build Helix from upstream master (updated on every run)
  --hyprland    Also install the Hyprland desktop: Waybar, lock, idle, wifi
                and power tools (Arch only)
  --doom        Also install Doom Emacs (run ./install.sh first)
  --skip-base   Skip the base set, e.g. ./deps.sh --skip-base --doom
  --dry-run     Print the commands instead of running them
  -h, --help    Show this help

DEPS_DISTRO=arch|ubuntu|debian overrides distro detection (useful with --dry-run).
EOF
}

log() { printf '\n==> %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

# Run a command given as separate arguments.
run() {
  printf '+ %s\n' "$*"
  "$DRY_RUN" || "$@"
}

# Run a shell snippet; needed for pipes (curl | sh) and for sourcing nvm.sh,
# which is not safe under `set -u`, so it gets its own shell without it.
# pipefail, though: in `curl ... | sh` a failed download gives sh empty
# input, which it runs happily, and the step would pass with nothing installed.
run_sh() {
  printf '+ %s\n' "$1"
  "$DRY_RUN" || bash -o pipefail -c "$1"
}

detect_distro() {
  if [[ -n "${DEPS_DISTRO:-}" ]]; then
    printf '%s\n' "$DEPS_DISTRO"
    return
  fi
  local id
  # shellcheck source=/dev/null
  id="$(. /etc/os-release && printf '%s' "$ID")"
  case "$id" in
    arch | endeavouros | manjaro) printf 'arch\n' ;;
    ubuntu) printf 'ubuntu\n' ;;
    debian) printf 'debian\n' ;;
    *) die "unsupported distro '$id' (set DEPS_DISTRO=arch|ubuntu|debian to force)" ;;
  esac
}

pacman_install() { run sudo pacman -S --needed "$@"; }
apt_install() { run sudo apt install "$@"; }

# ---------------------------------------------------------------- base

pkgs_arch() {
  log "Arch packages"
  # Base tooling (base-devel builds pdf-tools, tree-sitter grammars and AUR packages)
  pacman_install git base-devel curl wget unzip
  # Shell: zshrc loads starship, pyenv and direnv; fzf/ripgrep/fd back fuzzy search in Emacs;
  # jq parses zellij's pane list for zellij/url-picker.sh
  pacman_install zsh starship pyenv direnv fzf ripgrep fd jq
  # Terminal: zshrc auto-starts zellij; alacritty, kitty and Doom use FiraCode Nerd Font
  pacman_install alacritty kitty ttf-firacode-nerd zellij wl-clipboard xclip
  # Terminal git UI, alongside magit
  pacman_install lazygit
  # Zed editor; Arch names the command zeditor, not zed
  pacman_install zed
  # File manager: Super+E in Hyprland (hypr/hyprland.lua) and Meta+E in Plasma open it
  pacman_install dolphin
  # emacs-wayland is the pure-GTK build for Wayland (KDE); swap in emacs on X11.
  # Skip when any variant already provides emacs: they conflict with each other,
  # and pacman would ask to remove the installed one.
  if ! pacman -T emacs >/dev/null; then
    pacman_install emacs-wayland
  fi
  # Languages and LSP servers: Doom (sh +lsp), (cc +lsp), (javascript +lsp)
  pacman_install python-pipx rustup shellcheck shfmt bash-language-server \
    clang typescript-language-server prettier
  run rustup default stable
  run rustup component add rust-analyzer
  # Doom modules: spell (English + French dictionaries), pass, graphviz, org +pandoc/+gnuplot, pdf (poppler-glib)
  pacman_install aspell aspell-en aspell-fr pass graphviz pandoc-cli gnuplot poppler-glib
  # Doom web: tidy formats HTML (stylelint and js-beautify come from npm)
  pacman_install tidy
  # Doom org +dragndrop: doctor wants maim/scrot/gnome-screenshot, but on Wayland
  # config.el takes screenshots with spectacle; scrot only quiets the warning
  pacman_install scrot
}

# Debian and Ubuntu share one package list: Ubuntu's universe is synced from Debian
pkgs_apt() {
  local distro=$1
  log "apt packages ($distro)"
  # Base tooling, plus the -dev libraries needed to build pdf-tools and pyenv Pythons
  apt_install git build-essential curl wget unzip pkg-config autoconf automake \
    libpoppler-glib-dev libpng-dev zlib1g-dev libssl-dev libbz2-dev libreadline-dev \
    libsqlite3-dev libncurses-dev xz-utils tk-dev libffi-dev liblzma-dev libxml2-dev
  # Shell: Debian and Ubuntu ship fd as fdfind, link it so Emacs finds it as fd
  apt_install zsh starship pyenv direnv fzf ripgrep fd-find jq
  run mkdir -p "$HOME/.local/bin"
  run_sh 'ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"'
  # Terminal: FiraCode Nerd Font is not packaged, install it per user
  apt_install alacritty kitty wl-clipboard xclip
  if [[ ! -d "$HOME/.local/share/fonts/FiraCodeNerd" ]]; then
    run mkdir -p "$HOME/.local/share/fonts/FiraCodeNerd"
    run_sh 'curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.tar.xz | tar -xJ -C "$HOME/.local/share/fonts/FiraCodeNerd" && fc-cache -f'
  fi
  # emacs-pgtk is for Wayland, swap in emacs-gtk on X11; lazygit is a terminal git UI
  apt_install emacs-pgtk lazygit
  # Zed is not packaged: its installer puts zed in ~/.local/bin, no sudo, and
  # Zed updates itself after that, so only run it once.
  if [[ ! -x "$HOME/.local/bin/zed" ]]; then
    run_sh 'curl -fsSL https://zed.dev/install.sh | sh'
  fi
  # Languages and LSP servers; zellij is not packaged, so build it with cargo
  apt_install pipx rustup shellcheck shfmt clang clangd
  run rustup default stable
  run rustup component add rust-analyzer
  run cargo install --locked zellij
  # Doom modules: spell (English + French dictionaries), pass, graphviz, org +pandoc/+gnuplot
  apt_install aspell aspell-en aspell-fr pass graphviz pandoc gnuplot
  # Doom web: tidy formats HTML (stylelint and js-beautify come from npm)
  apt_install tidy
  # Doom org +dragndrop: doctor wants maim/scrot/gnome-screenshot, but on Wayland
  # config.el takes screenshots with spectacle; scrot only quiets the warning
  apt_install scrot
}

oh_my_zsh() {
  log "oh-my-zsh"
  # --keep-zshrc: ~/.zshrc is this repo's zshrc (symlinked by install.sh) and
  # already sources oh-my-zsh; --unattended skips chsh, so do it below.
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    # Downloaded first: pipefail can't see a failure inside $(...), and
    # `sh -c ""` would succeed with nothing installed
    run_sh 'script="$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && sh -c "$script" "" --unattended --keep-zshrc'
  fi
  local plugin
  for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    if [[ ! -d "$ZSH_CUSTOM_DIR/plugins/$plugin" ]]; then
      run git clone "https://github.com/zsh-users/$plugin" "$ZSH_CUSTOM_DIR/plugins/$plugin"
    fi
  done
  if [[ "$(basename "${SHELL:-}")" != zsh ]]; then
    run_sh 'chsh -s "$(command -v zsh)"'
  fi
}

nvm_node() {
  log "NVM and Node"
  # PROFILE=/dev/null: zshrc already loads nvm, don't let the installer append to it
  if [[ ! -d "$NVM_DIR" ]]; then
    run_sh 'curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | PROFILE=/dev/null bash'
  fi
  with_nvm 'nvm install --lts'
}

# npm from NVM is only on PATH once nvm.sh is sourced
with_nvm() { run_sh ". \"$NVM_DIR/nvm.sh\" && $1"; }

# Coding agents, each from its vendor's installer. Skipped once installed:
# all three update themselves (claude on its own, opencode upgrade, pi update).
# zshrc already puts their bin directories on PATH, and ~/.zshrc is this
# repo's zshrc, so no installer may add its own line there.
agents() {
  log "Coding agents"
  if [[ ! -x "$HOME/.local/bin/claude" ]]; then
    run_sh 'curl -fsSL https://claude.ai/install.sh | bash'
  fi
  if [[ ! -x "$HOME/.opencode/bin/opencode" ]]; then
    run_sh 'curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path'
  fi
  # pi needs Node 22.19+, so with NVM's on PATH rather than letting it install
  # its own. It asks through /dev/tty, not stdin, whether to add a PATH line
  # to ~/.zshrc (its duplicate check misses zshrc's $HOME form) and whether to
  # start pi mid-install; setsid leaves it no terminal, so it asks neither.
  if [[ ! -x "$HOME/.pi/agent/bin/pi" ]]; then
    with_nvm 'curl -fsSL https://pi.dev/install.sh | setsid -w sh'
  fi
}

npm_globals() {
  local distro=$1
  log "npm global packages"
  if [[ "$distro" != arch ]]; then
    # Not packaged on Debian or Ubuntu
    with_nvm 'npm install -g bash-language-server typescript-language-server typescript prettier'
  fi
  # Quint and its language server
  with_nvm 'npm install -g @informalsystems/quint @informalsystems/quint-language-server'
  # Doom web: CSS linting and JS/CSS/HTML formatting, from npm on both distros
  with_nvm 'npm install -g stylelint js-beautify'
}

pipx_tools() {
  log "pipx tools"
  run pipx install ruff mypy pylint basedpyright
}

toolchains() {
  log "Lean"
  # elan adds itself to PATH via ~/.profile and ~/.zprofile, not the repo's zshrc
  if [[ ! -d "$HOME/.elan" ]]; then
    run_sh 'curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh -s -- -y'
  fi
}

sdkman() {
  log "SDKMAN"
  # rcupdate=false: zshrc already sources sdkman-init.sh at its end
  if [[ ! -d "$HOME/.sdkman" ]]; then
    run_sh 'curl -fsSL "https://get.sdkman.io?rcupdate=false" | bash'
  fi
}

base() {
  local distro=$1
  case "$distro" in
    arch) pkgs_arch ;;
    ubuntu | debian) pkgs_apt "$distro" ;;
  esac
  oh_my_zsh
  nvm_node
  agents
  npm_globals "$distro"
  pipx_tools
  toolchains
  sdkman
}

# ---------------------------------------------------------------- extras

heavy() {
  local distro=$1
  log "Heavy extras"
  if [[ "$distro" == arch ]]; then
    # LaTeX (Doom latex): the texlive group is the full TeX Live minus languages,
    # so add French. It brings latexmk and chktex (Doom's checker) via
    # texlive-binextra. biber backs biblatex, and the perl
    # modules let texlab format with latexindent.
    pacman_install texlive texlive-langfrench biber texlab \
      perl-yaml-tiny perl-file-homedir
    # Grammar checking, PlantUML, Jupyter (ein)
    pacman_install languagetool plantuml jupyter-notebook
  else
    # texlive-full is the full TeX Live, every language included, and already
    # pulls in latexmk, chktex and biber
    apt_install texlive-full
    # Debian 13 does not package texlab; Doom's latex module is enabled
    # without +lsp, so it works without it
    if [[ "$distro" == ubuntu ]]; then
      apt_install texlab
    fi
    # PlantUML, Jupyter (ein); LanguageTool is not packaged on Debian or
    # Ubuntu, Doom's grammar module just warns without it
    apt_install plantuml jupyter-notebook
  fi
}

firewall() {
  local distro=$1
  log "Firewall (ufw)"
  if [[ "$distro" == arch ]]; then
    pacman_install ufw
    # EndeavourOS enables firewalld out of the box; two firewalls rewriting the
    # same nftables rules conflict, so turn it off first
    if systemctl list-unit-files firewalld.service >/dev/null 2>&1; then
      run sudo systemctl disable --now firewalld
    fi
    run sudo systemctl enable --now ufw # loads the rules at boot
  else
    # Ubuntu ships ufw installed but inactive, Debian does not install it
    apt_install ufw
  fi
  run sudo ufw default deny incoming
  run sudo ufw default allow outgoing
  # KDE Connect / GSConnect pair and transfer over 1714-1764
  run sudo ufw allow 1714:1764/tcp
  run sudo ufw allow 1714:1764/udp
  # Only if this machine runs an SSH server: rate-limit repeated login attempts
  # run sudo ufw limit ssh
  run sudo ufw enable
  run sudo ufw status verbose
}

llama() {
  log "llama.cpp"
  # llama.app's installer on every distro, Arch included: it picks the CUDA,
  # ROCm, Vulkan or CPU build itself, needs no sudo, and puts one `llama`
  # binary (llama serve, llama cli) in ~/.local/bin. That binary links no
  # ggml or CUDA runtime from the system, only the driver's libcuda, so a
  # distro upgrade can't break it: Arch's split llama-cpp did when ggml 1.0
  # changed its soname before llama-cpp was rebuilt. A re-run updates it to
  # the latest build, and does nothing when it is already there.
  run_sh 'curl -LsSf https://llama.app/install.sh | sh'
  # llama/serve.sh no longer runs a distro package's llama-server
  if [[ -e /usr/bin/llama-server || -e /usr/local/bin/llama-server ]]; then
    warn "a distro llama.cpp is still installed (llama-server); it is unused now, remove it with your package manager (Arch: sudo pacman -Rns llama-cpp ggml-cuda ggml)"
  fi
}

helix() {
  log "Helix from upstream master"
  # rustup comes with the base set; with --skip-base it must already be there
  command -v cargo >/dev/null || "$DRY_RUN" || die "cargo not found; run without --skip-base first"
  # Master rather than the distro package: workspace trust (helix/config.toml),
  # which keeps a repo's .helix/ config and language servers from running
  # until :workspace-trust, is in no release yet. Its tip on purpose: a re-run
  # pulls and rebuilds, like the llama.app installer updates.
  if [[ ! -d "$HELIX_SRC" ]]; then
    run git clone https://github.com/helix-editor/helix.git "$HELIX_SRC"
  fi
  run git -C "$HELIX_SRC" pull --ff-only
  # ~/.cargo/bin/hx may still be the link to the Steel build's wrapper:
  # remove it, so cargo writes the binary there, not through the link
  if [[ -L "$HOME/.cargo/bin/hx" ]]; then
    run rm "$HOME/.cargo/bin/hx"
  fi
  # Installs hx into ~/.cargo/bin, which zshrc puts ahead of /usr/bin
  run_sh "cd \"$HELIX_SRC\" && cargo install --path helix-term --locked"
  # Helix also looks for runtime/ beside its binary, so themes and queries are
  # found by every hx, even from a shell started before HELIX_RUNTIME existed
  run ln -sfn "$HELIX_SRC/runtime" "$HOME/.cargo/bin/runtime"
  # Grammars build into ~/.config/helix/runtime, the first runtime dir
  run_sh "export HELIX_RUNTIME=\"$HELIX_SRC/runtime\" && \"\$HOME/.cargo/bin/hx\" --grammar fetch && \"\$HOME/.cargo/bin/hx\" --grammar build"

  # The Steel build this replaced left its binaries and checkouts; nothing
  # uses them now, but they are the user's to delete
  local steel_leftovers=() path
  for path in "$HOME"/.cargo/bin/{hx-steel,steel,forge,steel-language-server,cargo-steel-lib} \
    "$HOME"/.local/src/{helix-steel,helix-file-watcher}; do
    if [[ -e "$path" ]]; then steel_leftovers+=("$path"); fi
  done
  if ((${#steel_leftovers[@]})); then
    warn "the Steel build of Helix left these behind, unused now: rm -rf ${steel_leftovers[*]}"
  fi
}

hyprland() {
  local distro=$1
  log "Hyprland desktop"
  # Debian/Ubuntu package Hyprland late or not at all, and hypr/hyprland.lua
  # needs 0.57+ (the Lua config)
  if [[ "$distro" != arch ]]; then
    warn "--hyprland is Arch only; skipping"
    return 0
  fi
  # Everything hypr/ and waybar/ start or bind: the compositor, its lock and
  # idle daemons, the bar, the launcher and power menu (wofi), screenshots
  # (grim, slurp; wl-clipboard is in the base set), the wifi tray applet,
  # a polkit agent, Super+E's Dolphin (also in the base set, but here for
  # --skip-base --hyprland), the audio mixer and power profiles,
  # whose daemon must also be running for the bar to switch them, and the
  # notification daemon (mako; Plasma's only runs inside Plasma) with the
  # notify-send that the battery alerts use (libnotify).
  pacman_install hyprland hyprlock hypridle hyprpaper waybar wofi grim slurp \
    network-manager-applet polkit-gnome dolphin pavucontrol power-profiles-daemon \
    mako libnotify
  run sudo systemctl enable --now power-profiles-daemon
}

doom() {
  log "Doom Emacs"
  if [[ "$(realpath "$HOME/.config/doom" 2>/dev/null)" != "$REPO_DIR/doom" ]]; then
    die "$HOME/.config/doom does not point at $REPO_DIR/doom; run ./install.sh first"
  fi
  if [[ ! -d "$HOME/.config/emacs" ]]; then
    run git clone --depth 1 https://github.com/doomemacs/core "$HOME/.config/emacs"
  fi
  run "$HOME/.config/emacs/bin/doom" install
}

# ---------------------------------------------------------------- main

main() {
  local want_base=true want_heavy=false want_firewall=false want_llama=false want_helix=false want_hyprland=false want_doom=false
  local arg
  for arg in "$@"; do
    case "$arg" in
      --heavy) want_heavy=true ;;
      --firewall) want_firewall=true ;;
      --llama) want_llama=true ;;
      --helix) want_helix=true ;;
      --hyprland) want_hyprland=true ;;
      --doom) want_doom=true ;;
      --skip-base) want_base=false ;;
      --dry-run) DRY_RUN=true ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        usage >&2
        die "unknown option '$arg'"
        ;;
    esac
  done

  local distro
  distro="$(detect_distro)"
  [[ "$distro" == arch || "$distro" == ubuntu || "$distro" == debian ]] ||
    die "DEPS_DISTRO must be arch, ubuntu or debian"
  log "Distro: $distro$("$DRY_RUN" && printf ' (dry run)')"

  # if, not `&&`: bash disables `set -e` inside a function called from a && list
  if "$want_base"; then base "$distro"; fi
  if "$want_heavy"; then heavy "$distro"; fi
  if "$want_firewall"; then firewall "$distro"; fi
  if "$want_llama"; then llama; fi
  if "$want_helix"; then helix; fi
  if "$want_hyprland"; then hyprland "$distro"; fi
  if "$want_doom"; then doom; fi
  log "Done"
}

main "$@"
