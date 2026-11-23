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
| `--firewall` | ufw: deny inbound, allow outbound and KDE Connect (1714-1764) |
| `--llama` | llama.cpp from the llama.app installer, on every distro, see [Local LLM](#local-llm-llamacpp) |
| `--helix` | Helix from upstream master, built from source, see [Zellij cockpit](#zellij-cockpit-helix) |
| `--hyprland` | Hyprland, Waybar, hyprlock/hypridle, wofi, Dolphin, nm-applet, power-profiles-daemon, mako (Arch only), see [Hyprland desktop](#hyprland-desktop) |
| `--doom` | Doom Emacs core + `doom install` |

`--dry-run` prints the commands without running them; `--help` lists every flag.

Everything at once, links first:

```sh
./install.sh && ./deps.sh --heavy --firewall --llama --helix --hyprland --doom
```

- `install.sh` goes first: `--doom` needs `~/.config/doom` linked, and `--helix`
  builds its grammars into `~/.config/helix`, which would otherwise become a real
  directory that `install.sh` then refuses to replace.
- `--hyprland` is skipped with a warning outside Arch.

- Emacs is the Wayland build (`emacs-wayland` on Arch, `emacs-pgtk` on Debian/Ubuntu); on
  X11, swap in `emacs` / `emacs-gtk` in `deps.sh`. On Arch it is skipped if any
  installed package already provides `emacs`.
- On Arch the base set also installs Dolphin, which `Super E` opens; `--hyprland`
  installs it too, for `--skip-base`.
- Zed is `zeditor` on Arch; Debian and Ubuntu don't package it, so Zed's own
  installer puts `zed` in `~/.local/bin` and Zed updates itself from then on.
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
| `cockpit` | `cockpit-<project>`, refused while another project of that name has a live one | `cockpit` in the project again: same editor, agent and shell |
| Alacritty | `main`, shared by every window, each on its own tab | a new window attaches `main` again |
| `M-x ghostel` | none, plain zsh | gone with Emacs |

The agent starts only when its session is created, so a reattach never starts it
twice. Killing a buffer or window detaches too, so sessions last until you end
them: `Ctrl q` inside zellij, or `zellij ls` then `zellij kill-session <name>`.
After a reboot they show as EXITED, a saved layout with no processes:
`zellij delete-all-sessions -y` removes those and leaves live ones alone (its
`-f` would kill the live ones too). Emacs terminals delete their own on reopen.
Inside Emacs, `C-c`, `C-x` and `C-h` stay with Emacs, so zellij's move mode
(`Ctrl h`) is out of reach there.

A selection in any zellij pane goes to the clipboard when the mouse button
is released, through `wl-copy` (`copy_command` in `zellij/config.kdl`).
Emacs terminals included: ghostel ignores the OSC 52 sequence zellij would
otherwise use, and enabling it (`ghostel-enable-osc52`) would let any
program's output set the clipboard.

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

- `--helix` builds Helix from the tip of upstream master, and re-running it
  updates. Master rather than a distro package because workspace trust
  (`:workspace-trust` above) is in no release yet; without it, a repo's own
  `.helix/` config and language servers run as soon as Helix opens it.
  Replacing the earlier Steel build, it warns about that build's leftovers
  (`hx-steel`, `steel`, `forge`, `~/.local/src/helix-steel`, ...) until you
  delete them.
- The runtime is linked beside the binary (`~/.cargo/bin/runtime`), so every
  `hx` finds it, even from a shell started before `HELIX_RUNTIME` existed.
- Helix builds its grammars into `~/.config/helix/runtime`, which is
  `helix/runtime` here (ignored, 2+ GB).
- Still in Emacs: org, Lean's infoview (Helix gets `lake serve`'s diagnostics
  only), gptel and its tools, magit.

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
| Next / previous window | `Alt Tab` / `Alt Shift Tab`, or `Super Tab` / `Super Shift Tab` |
| Focus, move, resize a window | `Super` + arrows, `Super Shift` + `h j k l`, `Super Alt` + `h j k l` |
| Workspace 1-10, send a window to 1-5 | `Super 1`..`0`, `Super Shift 1`..`5` |
| Wifi | the nm-applet icon in the bar's tray; clicking the network module opens the connection editor |
| Power profile | click the bolt/scale/leaf in the bar: performance, balanced, power saver |
| Screen brightness | the brightness keys (`Fn F5` / `Fn F6`, held to repeat, also on the lock screen), or scroll on the bar's brightness pill: 5% steps, never below 5% (hidden without a backlight) |
| Screenshot of a region, to the clipboard | `Print` |
| Dismiss a notification | click it |
| See the agents, and which one waits | the bar's agents pill (hidden when none runs): ⚙ working, red 🔔 waiting for you, `>_` running only; hover it for the list |

- The agents pill (`waybar/agents.sh`) reads the zellij panes running
  `claude`, `pi` or `opencode` in every live session, and the state zellij
  keeps for each: Claude Code reports working and needing you itself, so it
  needs no hook. pi reports nothing and only counts as running. The
  tooltip lists each agent as session › pane, waiting ones first, with what
  it is doing or asking. Clicking it does nothing.
- The GPU pill (`waybar/gpu.sh`) shows an NVIDIA or AMD card's usage and
  VRAM (llama-server's model lives there), with temperature, power and the
  processes using it in the tooltip; it turns red once VRAM is 90% full.
  Machines without such a card (an Intel iGPU has no readout) don't show it.
  A laptop dGPU that sleeps shows as off and isn't queried, since
  `nvidia-smi` would wake it.

- Notifications are mako's, top right. The battery warns at 15% and again,
  until clicked, at 5%; those two show even over a fullscreen window, other
  notifications don't.
- The desktop is Ashen, like the terminals and editors: `waybar/style.css`
  names the palette once (`@define-color`), and mako, hyprlock and the window
  borders use the same values. Selected things are red-ember, as zellij's tab.
- The wallpaper (hyprpaper, `hypr/hyprpaper.conf`) is
  `~/Pictures/wallpaper.jpg`, a symlink made on each machine, so no image is
  in the repo. Without it the desktop is black. To change it:
  `ln -sf <image> ~/Pictures/wallpaper.jpg`, then
  `pkill hyprpaper; hyprpaper &` (or log in again).
- The laptop's screen (eDP-1) is always on the right: an external screen
  goes to its left, whichever is found first. The mouse wheel and TrackPoint
  scroll naturally, like the touchpad. Both are in `hypr/hyprland.lua`.
- Hyprland 0.57 reads only `hyprland.lua`; a `hyprland.conf` is ignored.
  hyprlock and hypridle still take `.conf`.
- `Alt Tab` cycles the workspace's windows in order, not most-recently-used
  as in Plasma.
- `Super M` quits Hyprland without asking; the power menu's Logout is the
  same, one step further away.
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

It runs the [llama.app](https://llama.app) installer, the same on every machine:
it picks the CUDA, ROCm, Vulkan or CPU build and installs a single
`~/.local/bin/llama`, started as `llama serve` rather than `llama-server` (the
systemd unit below does it through `llama/serve.sh`). No sudo, and nothing a
distro upgrade can break: the binary takes only the GPU driver from the system,
where Arch's `llama-cpp` broke when `ggml` changed under it. A distro llama.cpp
package is unused; `deps.sh` warns while one is installed.

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

### pi on the local model

Every cockpit has pi on the same server floating, hidden until `Alt f`, and
`pi-local` starts it anywhere else. `pi/local.sh` picks the model as gptel does (the loaded preset) and never
another provider; if the server is down it waits a minute, says so, and leaves
a shell.

It is told that the Markdown notes are in `~/notes` (an Obsidian vault works),
or in `$MY_NOTES_DIR` set per machine in `~/.extra_config`, and to search
there: the cockpit's float starts in `~`, which its `grep` refuses (below).
Without that folder it isn't told anything.

It has gptel's rules, through `pi/guard.ts` (loaded for this launcher only):

- `read`, `grep`, `find`, `ls` run without asking; `edit` and `write` ask first,
  and are refused in print mode (`-p`), where nothing can ask. No `bash`.
- The same credential paths are off limits, plus `/proc`. pi's `grep` searches
  hidden directories, so it refuses a directory that holds one, `~` included:
  ask it to search a project instead.
- The key comes from the key file through `pi/models.json` (linked into
  `~/.pi/agent`). Don't `/login llama.cpp` in pi: a stored key wins over the
  file and goes stale when the file changes.

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
