# config

- Per-machine extras, outside git: `~/.extra_config` (zsh),
  `doom/extra_packages.el`, `doom/extra_config.el` (loaded last, so it wins).
- `doom/config.el` holds the core settings and loads one file per topic from
  `doom/lisp/`: `terminals`, `documents` (org, LaTeX), `lang-python`, `lang-js`,
  `llm`, `llm-tools`, `lang-lean`, `lang-quint`.
- Emacs loads a snapshot of the shell environment, not zshrc: after changing
  PATH in `zshrc` or installing a new Node, run `doom sync --env` and restart it.

## Setup

```sh
./deps.sh                     # packages, oh-my-zsh, Node, coding agents, Lean, Quint, SDKMAN, ...
./install.sh                  # symlink the configs into ~ and ~/.config
./deps.sh --skip-base --doom  # Doom Emacs, once ~/.config/doom points at this repo
```

`deps.sh` detects Arch/EndeavourOS/Manjaro, Ubuntu 26.04 or Debian 13 and is safe to re-run: package
installs skip what is present and each installer skips if its directory exists.
Opt-in extras, combinable:

| Flag | Adds |
| --- | --- |
| `--heavy` | TeX Live, LanguageTool (Arch), PlantUML, Jupyter: several GB |
| `--firewall` | ufw: deny inbound, allow outbound |
| `--clamav` | ClamAV with its signature updater and daemon (about 1 GB of RAM); scan by hand with `clamdscan --multiscan --fdpass <path>` |
| `--llama` | llama.cpp from the llama.app installer, on every distro, see [Local LLM](#local-llm-llamacpp) |
| `--helix` | Helix from upstream master, built from source, see [Zellij cockpit](#zellij-cockpit-helix) |
| `--hyprland` | Hyprland, Waybar, hyprlock/hypridle, wofi, Dolphin, nm-applet, power-profiles-daemon, mako, btop (Arch only), see [Hyprland desktop](#hyprland-desktop) |
| `--doom` | Doom Emacs core + `doom install` |

`--dry-run` prints the commands without running them; `--help` lists every flag.

Everything at once, links first:

```sh
./install.sh && ./deps.sh --heavy --firewall --clamav --llama --helix --hyprland --doom
```

- `install.sh` goes first: `--doom` needs `~/.config/doom` linked, and `--helix`
  would otherwise make `~/.config/helix` a real directory.
- Emacs is the Wayland build (`emacs-wayland` / `emacs-pgtk`); on X11, swap in
  `emacs` / `emacs-gtk` in `deps.sh`.
- Ubuntu: most packages live in `universe` (enabled by default on desktop).
- Debian: your user needs `sudo` rights (`su - -c "usermod -aG sudo $USER"`,
  then log in again); `--heavy` leaves out texlab, which Debian doesn't package.

## Terminals and crashes

Every terminal runs in a zellij session, so its processes live on the zellij
server rather than in the window, and a crash only detaches them:

| Where | Session | After a crash |
| --- | --- | --- |
| Emacs agent and shell (`C-c p p`) | `emacs-<project>-<name>-<hash>`, buffer `<project> :: <name>` | `C-c p p` the project again: same agent, same shell |
| Emacs `main` workspace, beside `*scratch*` | `emacs-home-shell`, buffer `~ :: shell`, in `~/` | reattached on the next start |
| Emacs `org` workspace, beside Dired of `~/org` | `emacs-org-shell`, buffer `org :: shell`, in `~/org` | reattached on the next start |
| Emacs `C-c o T` | the same, with `term-1`, `term-2`, ... as names | `C-c o z` reattaches every one the project still has |
| `cockpit` | `cockpit-<project>`, refused while another project of that name has a live one | `cockpit` in the project again: same editor, agent and shell |
| Alacritty | `main`, shared by every window, each on its own tab | a new window attaches `main` again |
| `M-x ghostel` | none, plain zsh | gone with Emacs |

- Killing a buffer or window only detaches, and a reattach never starts the
  agent twice. End a session with `Ctrl q`, or `zellij kill-session <name>`.
- After a reboot, sessions show as EXITED (no processes):
  `zellij delete-all-sessions -y` removes those only; `-f` kills live ones too.
- Inside Emacs, `C-c`, `C-x` and `C-h` stay with Emacs, so zellij's move mode
  (`Ctrl h`) is out of reach there.
- A mouse selection in any pane, Emacs included, goes to the clipboard through
  `wl-copy` (`zellij/config.kdl`), not OSC 52, which ghostel ignores.

## Zellij cockpit (Helix)

A terminal-only take on `C-c p p`: `cockpit [DIR]` opens the project at DIR
(default: here) in zellij with Helix on the left, the agent top-right and a
shell below (`zellij/layouts/cockpit.kdl`). The agent is `$MY_COCKPIT_AGENT`,
`claude` by default; set it per machine in `~/.extra_config`. From inside
zellij it switches session, from outside it attaches.

```sh
./install.sh                    # links ~/.config/helix
./deps.sh --skip-base --helix   # builds hx into ~/.cargo/bin
```

| Want | How |
| --- | --- |
| Open a file in the editor pane | `Alt e` (fzf), or `~/.config/zellij/hx-open.sh FILE[:LINE]` from the agent or shell; in any session, a tab without one gets a new Helix pane |
| See an agent's edits | `space R` rereads every buffer from disk (`:reload-all`); Helix doesn't notice changes by itself |
| Start the language servers | `:workspace-trust` once per project, or Enter on the prompt; until then nothing from the project runs |
| Switch project | `Ctrl o w`, or `cockpit DIR` again |
| Open or go to a project's cockpit from any pane | `Alt c`: fzf over the live cockpits (●), then the repos under `~/sources`; a typed path that matches nothing opens as is |
| Ask the local model (docs, small tasks) | `Alt f` shows or hides pi on the local model, floating, in `~` (see [pi on the local model](#pi-on-the-local-model)); only cockpits created since it was added have it |

- `--helix` builds upstream master and re-running it updates: workspace trust
  is in no release yet, and without it a repo's `.helix/` config and language
  servers run as soon as Helix opens it.
- Grammars build into `helix/runtime` here (ignored, 2+ GB).
- Still in Emacs: org, Lean's infoview (Helix gets diagnostics only), gptel,
  magit.

## Hyprland desktop

A Hyprland session beside Plasma: pick it at the login screen, Plasma stays
the fallback and keeps its own settings. `hypr/`, `waybar/` and `mako/` are
linked into `~/.config` by `install.sh`.

```sh
./deps.sh --skip-base --hyprland   # Arch only
./install.sh                       # move a real ~/.config/hypr, waybar or mako away first
```

| Want | Key or click |
| --- | --- |
| Terminal (joins zellij's `main`) | `Super Return` |
| Files (Dolphin) | `Super E` |
| Launch an app (wofi) | `Super P` |
| Lock | `Super L`; also after 10 min idle and before every suspend |
| Lock, suspend, log out, reboot, shut down | `Super Escape`, or the bar's power button |
| Next / previous window, in order (not most-recent first) | `Alt Tab` / `Alt Shift Tab`, or `Super Tab` / `Super Shift Tab` |
| Focus, move, resize a window | `Super` + arrows, `Super Shift` + `h j k l`, `Super Alt` + `h j k l` |
| Workspace 1-10, send a window to 1-5 | `Super 1`..`0`, `Super Shift 1`..`5` |
| Wifi | the nm-applet icon in the bar's tray; clicking the network module opens the connection editor |
| Power profile | click the bolt/scale/leaf in the bar: performance, balanced, power saver |
| Screen brightness | the brightness keys (`Fn F5` / `Fn F6`, held to repeat, also on the lock screen), or scroll on the bar's brightness pill: 5% steps, never below 5% (hidden without a backlight) |
| Screenshot of a region, to the clipboard | `Print` |
| Dismiss a notification | click it |
| See the agents, and which one waits | the bar's agents pill (hidden when none runs): ⚙ working, red 🔔 waiting for you, `>_` running only; hover it for the list |

- Agents pill (`waybar/agents.sh`): the `claude`, `pi` and `opencode` panes of
  every live zellij session. Claude Code reports its state itself; pi only
  counts as running.
- GPU pill (`waybar/gpu.sh`): an NVIDIA or AMD card's usage and VRAM, red at
  90% full; hidden without one, and a sleeping laptop dGPU isn't woken.
- Notifications are mako's, top right. The battery warns at 15% and, until
  clicked, at 5%, even over a fullscreen window.
- The desktop is Ashen too: `waybar/style.css` names the palette, and mako,
  hyprlock and the window borders use the same values.
- Wallpaper: `~/Pictures/wallpaper.jpg`, a symlink per machine (black
  without it). Change it with `ln -sf <image> ~/Pictures/wallpaper.jpg`, then
  `pkill hyprpaper; hyprpaper &`.
- The laptop's screen (eDP-1) is always on the right of an external one; the
  mouse and TrackPoint scroll naturally, like the touchpad.
- `Super M` quits Hyprland without asking.
- `Hyprland --verify-config -c hypr/hyprland.lua` checks syntax and option
  names, not dispatcher arguments.

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
| Alacritty | `Shift`+click (Shift is needed inside Zellij), `Ctrl+Shift+O` opens, `Ctrl+Shift+Y` copies |

Claude Code follows the terminal's Ashen colours with `/theme` → "Dark mode
(ANSI colors only)". The choice lives in `~/.claude.json`, outside this repo, so
pick it once per machine. Ashen has no green, so lines a diff adds show orange.

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
./deps.sh --skip-base --llama   # any distro; run it again to update
```

The [llama.app](https://llama.app) installer picks the CUDA, ROCm, Vulkan or CPU
build and installs one `~/.local/bin/llama`, with no sudo and nothing a distro
upgrade can break. A distro llama.cpp package is unused; `deps.sh` warns about it.

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

While it runs, the `load-on-startup` model stays in VRAM. The unit's flags:

- `--models-max 1`: one model in VRAM; switching unloads the previous one.
- `--host 127.0.0.1` and `--cors-origins localhost --no-cors-credentials`: no
  other machine, and no web page open in the browser, can use it.
- `--api-key-file`: every request carries the key, which gptel reads from the
  same file (`my/gptel-llama-key-file`); without the file the server won't start.
- A model is downloaded into `~/.cache/huggingface` on first use (15-18 GB for
  the work models), and that first request waits for it.

### gptel tools

- Run without asking: `read_file`, `list_directory`, `search_project` (ripgrep),
  `search_org` (ripgrep over `org-directory`), `list_buffers`, `read_buffer`.
- `write_file` waits: `C-c C-c` runs the proposed call, `C-c C-k` rejects it.
- Off limits to every tool, since a prompt injected into a file could ask for
  secrets: remote (TRAMP) paths, `.gpg`/`.age` files, and
  `my/gptel-tool-denied-paths` (`~/.ssh`, `~/.gnupg`, `~/.password-store`,
  `~/.aws`, `~/.extra_config`, ...).

### pi on the local model

Every cockpit has pi on the same server, floating and hidden until `Alt f`;
`pi-local` starts it anywhere else. `pi/local.sh` uses the loaded model, never
another provider, and waits a minute for a server that is down.

It is told to search the Markdown notes in `~/notes` (an Obsidian vault works),
or `$MY_NOTES_DIR` from `~/.extra_config`, when that folder exists.

`pi/guard.ts` gives it gptel's rules:

- `read`, `grep`, `find`, `ls` run without asking; `edit` and `write` ask, and
  are refused in print mode (`-p`). No `bash`.
- The same credential paths are off limits, plus `/proc`. Its `grep` refuses a
  directory holding hidden ones, `~` included: ask it to search a project.
- The key comes from the key file through `pi/models.json`. Don't
  `/login llama.cpp` in pi: a stored key wins over the file and goes stale.

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
