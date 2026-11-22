# config

ZSH extra config: `~/.extra_config`

Doom packages extra: `doom/extra_packages.el`

Doom config extra: `doom/extra_config.el`, loaded last so its settings win

Doom config layout: `doom/config.el` keeps the core settings (theme, fonts, modeline)
and loads one file per topic from `doom/lisp/`: `terminals`, `documents` (org,
LaTeX), `lang-python`, `lang-js`, `llm`, `llm-tools`, `lang-lean`, `lang-quint`.

Doom environment: started from the desktop menu, Emacs never runs zshrc, so it
loads a snapshot of the shell environment instead. After changing PATH in `zshrc`
or installing a new Node, run `doom sync --env` from a shell and restart Emacs.
`doom/cli.el` keeps zellij and Claude Code session variables out of the snapshot.

## Setup

```sh
./deps.sh                     # packages, oh-my-zsh, Node, Lean, Quint, SDKMAN, ...
./install.sh                  # symlink the configs into ~ and ~/.config
./deps.sh --skip-base --doom  # Doom Emacs, once ~/.config/doom points at this repo
```

`deps.sh` detects Arch/EndeavourOS/Manjaro, Ubuntu 26.04 or Debian 13 and is safe to re-run: package
installs skip what is present and each installer skips if its directory exists.
Opt-in extras, combinable:

| Flag | Adds |
| --- | --- |
| `--heavy` | TeX Live, LanguageTool (Arch), PlantUML, Jupyter: several GB |
| `--firewall` | ufw: deny inbound, allow outbound and KDE Connect (1714-1764) |
| `--llama` | `llama.cpp-cuda` from the AUR on Arch, the llama.app installer elsewhere, see [Local LLM](#local-llm-llamacpp) |
| `--helix` | Helix with Steel plugins, built from source, and its file watcher, see [Zellij cockpit](#zellij-cockpit-helix) |
| `--doom` | Doom Emacs core + `doom install` |

`--dry-run` prints the commands without running them; `--help` lists every flag.

- Emacs is the Wayland build (`emacs-wayland` on Arch, `emacs-pgtk` on Debian/Ubuntu); on
  X11, swap in `emacs` / `emacs-gtk` in `deps.sh`. On Arch it is skipped if any
  installed package already provides `emacs`.
- Ubuntu: most packages live in `universe` (enabled by default on desktop).
- Debian: your user needs `sudo` rights, which the installer skips when a root
  password is set (`su - -c "usermod -aG sudo $USER"`, then log in again). `--heavy`
  leaves out texlab, which Debian does not package.
- `--firewall` on EndeavourOS disables firewalld first: two firewalls rewriting the
  same nftables rules conflict.
- The NVM, SDKMAN and oh-my-zsh installers are kept from editing `~/.zshrc`, which is
  this repo's `zshrc` and already loads them.

## Terminals and crashes

Every terminal runs in a zellij session, so its processes live on the zellij
server rather than in the window, and a crash only detaches them:

| Where | Session | After a crash |
| --- | --- | --- |
| Emacs agent and shell (`C-c p p`) | `emacs-<project>-<name>-<hash>`, buffer `<project> :: <name>` | `C-c p p` the project again: same agent, same shell |
| Emacs `main` workspace, beside `*scratch*` | `emacs-home-shell`, buffer `~ :: shell`, in `~/` | reattached on the next start |
| Emacs `org` workspace, beside Dired of `~/org` | `emacs-org-shell`, buffer `org :: shell`, in `~/org` | reattached on the next start |
| Emacs `C-c o T` | the same, with `term-1`, `term-2`, ... as names | `C-c o z` reattaches every one the project still has |
| `cockpit` | `cockpit-<project>-<hash>` | `cockpit` in the project again: same editor, agent and shell |
| Alacritty or kitty | `main`, shared by every window, each on its own tab | a new window attaches `main` again |
| `M-x ghostel` | none, plain zsh | gone with Emacs |

The agent starts only when its session is created, so a reattach never starts it
twice. Killing a buffer or window detaches too, so sessions last until you end
them: `Ctrl q` inside zellij, or `zellij ls` then `zellij kill-session <name>`.
After a reboot they show as EXITED, a saved layout with no processes:
`zellij delete-all-sessions -y` removes those and leaves live ones alone (its
`-f` would kill the live ones too). Emacs terminals delete their own on reopen.
Inside Emacs, `C-c`, `C-x` and `C-h` stay with Emacs, so zellij's move mode
(`Ctrl h`) is out of reach there.

## Zellij cockpit (Helix)

A terminal-only take on `C-c p p`: `cockpit [DIR]` opens the project at DIR
(default: here) in zellij with Helix on the left, the agent top-right and a
shell below (`zellij/layouts/cockpit.kdl`). The agent is `$MY_COCKPIT_AGENT`,
`claude` by default; set it per machine in `~/.extra_config`. From inside
zellij it switches session, from outside it attaches.

```sh
./install.sh                    # links ~/.config/helix
./deps.sh --skip-base --helix   # builds hx, steel and forge into ~/.cargo/bin
```

| Want | How |
| --- | --- |
| Open a file in the editor pane | `Alt e` (fzf), or `~/.config/zellij/hx-open.sh FILE[:LINE]` from the agent or shell; in any session, a tab without one gets a new Helix pane |
| See an agent's edits | automatic, `helix/init.scm`'s file watcher reloads within 2 s; `space R` reloads every buffer by hand |
| Start the language servers | `:workspace-trust` once per project, or Enter on the prompt; until then nothing from the project runs |
| Switch project | `Ctrl o w`, or `cockpit DIR` again |

- `--helix` builds Helix from the tip of the `steel-event-system` branch, the
  open plugin PR ([helix#8675](https://github.com/helix-editor/helix/pull/8675)),
  and re-running it updates. The watcher is pinned in `deps.sh`
  (`HELIX_WATCHER_REV`); read a new revision before bumping it, since it is a
  native library loaded into the editor.
- A reload replaces unsaved edits too, but as one undo step: `u` brings them back.
- `hx` is `helix/hx.sh`, which sets `HELIX_STEEL_CONFIG` and runs the binary,
  `hx-steel`: without it, a project's own `.helix/helix.scm` and `init.scm`
  would replace `helix/`'s, with no trust check. Being the `hx` on PATH, it
  covers shells started before zshrc set the variable too. The runtime is
  linked beside the binary (`~/.cargo/bin/runtime`) for the same reason.
- Helix builds its grammars into `~/.config/helix/runtime`, which is
  `helix/runtime` here (ignored, 2+ GB).
- Still in Emacs: org, Lean's infoview (Helix gets `lake serve`'s diagnostics
  only), gptel and its tools, magit.

## Untrusted code

Some tools run code a project supplies just because you look at it: git runs the
filters a repo's own `.git/config` names, a venv's binaries are the project's,
and language servers run build scripts. So treat a repo you didn't write as code:

| When | What runs the project's code |
| --- | --- |
| Opening a file, `cd` in a shell | Nothing: Emacs's vc is off (`doom/config.el`), the prompt skips git status (`starship.toml`) |
| First file of a new project | One question. For Python (`doom/lisp/lang-python.el`) it covers the `.venv`, mypy and its plugins, and the language server; no keeps ruff only. Other languages get lsp-mode's "import project root?" |
| Only when you ask | magit, `C-c p p` / `C-c p f` (`git ls-files`), treemacs's git colours, `direnv allow` |

Both answers live in lsp-mode's session; undo one with `M-x lsp-workspace-folders-remove`
or `M-x lsp-workspace-blocklist-remove`.

## Long URLs

Zellij links a wrapped URL only up to the end of its first row
([zellij#3436](https://github.com/zellij-org/zellij/issues/3436)), so use a picker:

| Where | Key |
| --- | --- |
| Zellij, any terminal | `Alt u`: Enter opens, `Ctrl-y` copies |
| Emacs buffer outside Zellij (`M-x ghostel`) | `C-c o u` |
| Alacritty or kitty | `Shift`+click (Shift is needed inside Zellij), `Ctrl+Shift+O` opens, `Ctrl+Shift+Y` copies |

`kitty/` mirrors `alacritty/`: same Ashen theme, font and keys, and zellij still
does the tabs and splits (kitty's own shortcuts are cleared). It also draws
FiraCode's ligatures, which Alacritty doesn't, and images through zellij.
`Ctrl+Shift+F5` reloads its config.

## Local LLM (llama.cpp)

Doom's gptel talks to a local `llama-server` on port 9091, run in router mode: one
server offers every model in a presets file and loads whichever one gptel asks for.
gptel reads that list from the server, so the presets file is the only list of
models to maintain.

| File | GPU | Models (gptel names) |
| --- | --- | --- |
| `llama/home.ini` | 8 GB | `gemma-4-12b` |
| `llama/work.ini` | 24 GB | `gemma-4-26b-a4b` (default), `qwen3-coder-30b`, `gemma-4-31b` |

The Emacs side is `doom/lisp/llm.el` (backend, model list) and
`doom/lisp/llm-tools.el` (the [tools](#gptel-tools)).

### Install

```sh
./deps.sh --skip-base --llama   # Arch / EndeavourOS / Manjaro, from the AUR
```

On Debian/Ubuntu the same flag runs the [llama.app](https://llama.app) installer
instead: it picks the CUDA, ROCm, Vulkan or CPU build and installs a single
`~/.local/bin/llama` binary, started as `llama serve` rather than `llama-server`.
The systemd unit below starts the server through `llama/serve.sh`, which runs
whichever of the two is installed.

### Start the server

`systemd/llama-server@.service` runs the server as a systemd user service. Its
instance name is the presets file: `@home` reads `llama/home.ini`, `@work` reads
`llama/work.ini` (through the `~/.config/llama` link from `install.sh`). On each
machine, create the API key the server and gptel share (outside the repo, never
committed), then enable its instance once; after that it starts at every login:

```sh
mkdir -p ~/.config/llama-server
(umask 077 && openssl rand -hex 32 > ~/.config/llama-server/api-key)
systemctl --user daemon-reload
systemctl --user enable --now llama-server@home   # work machine: llama-server@work
```

| Task | Command (`@work` on the work machine) |
| --- | --- |
| State | `systemctl --user status llama-server@home` |
| Logs, first download | `journalctl --user -u llama-server@home -f` |
| Reload the presets | `systemctl --user restart llama-server@home` |
| Free the GPU for now | `systemctl --user stop llama-server@home` |
| Stop starting at login | `systemctl --user disable --now llama-server@home` |

While it runs, the `load-on-startup` model stays in VRAM. The flags, set in the
unit file:

- `--models-max 1` keeps a single model in VRAM: switching unloads the previous one.
- `--host 127.0.0.1` keeps other machines out, and `--cors-origins localhost
  --no-cors-credentials` stops web pages open in the browser from using the server
  (by default it accepts any origin).
- `--api-key-file ~/.config/llama-server/api-key` makes every request, the model
  list included, carry the key, so other local processes and web pages can't use
  the server. gptel reads the same file (`my/gptel-llama-key-file`); without it
  the server doesn't start.
- The first time a model is used, it is downloaded into `~/.cache/huggingface`
  (15-18 GB for the work models), and that first request waits for the download.

### gptel tools

- `read_file`, `list_directory`, `search_project` (ripgrep), `search_org`
  (ripgrep over `org-directory` from any buffer, org files only, smart case),
  `list_buffers`, `read_buffer` (including unsaved changes): run without asking.
- `write_file`: gptel shows the proposed call in the buffer and waits; `C-c C-c`
  runs it, `C-c C-k` rejects it.
- Off limits to every tool, since reading never asks and a prompt injected into a
  file could ask for secrets: remote (TRAMP) paths, `.gpg`/`.age` files (Emacs
  would decrypt them), and the credential paths in `my/gptel-tool-denied-paths`
  (`~/.ssh`, `~/.gnupg`, `~/.password-store`, `~/.aws`, `~/.extra_config`, ...).

### Add or change a model

Add a section to the machine's presets file and restart the server
(`systemctl --user restart llama-server@home`, or `@work`). The section name
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
curl -s 'localhost:9091/props?model=gemma-4-26b-a4b' | grep -o '"n_ctx":[0-9]*'
nvidia-smi --query-gpu=memory.used,memory.total --format=csv
```
