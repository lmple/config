# config

- Per-machine extras, outside git: `~/.extra_config` (zsh),
  `doom/extra_packages.el`, `doom/extra_config.el` (loaded last, so it wins).
- `doom/config.el` holds the core settings and loads one file per topic from
  `doom/lisp/`: `terminals`, `remote`, `documents` (org, LaTeX), `lang-python`,
  `lang-js`, `llm`, `llm-tools`, `lang-lean`, `lang-quint`.
- `C-c o s` opens Dired on a host from `~/.ssh/config`, over TRAMP (by hand:
  `C-x d`, then `/ssh:` and TAB).
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

Every terminal but Emacs's Claude runs in a zellij session, so its processes
live on the zellij server rather than in the window, and a crash only detaches
them:

| Where | Session | After a crash |
| --- | --- | --- |
| Emacs shell (`C-c p p`), and the agent when it isn't claude | `emacs-<project>-<name>-<hash>`, buffer `<project> :: <name>` | `C-c p p` the project again and pick the same agent: same agent, same shell |
| Emacs Claude (`C-c p p`) | none: claude-code-ide runs it in Emacs, buffer `<project> :: claude-ide` | gone with Emacs; `M-x claude-code-ide-continue` brings the conversation back |
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
- `C-c p p` asks which agent to start after the file picker: RET takes claude,
  or pick `pi-local` (pi on the local model) or `opencode`. The list is
  `my/project-agents` in `doom/lisp/terminals.el`; `my/project-agent` (per
  machine, in `extra_config.el`) is the one offered first. Treemacs opens on
  the left, on the file you picked, and follows the files you open next.
- The agents list sits in `main`, above the `~` shell; `C-c o a` goes there
  from anywhere (`doom/lisp/agents.el`). It shows every agent: Emacs's Claude
  sessions, from the state Claude Code reports to ghostel, and the agents in
  zellij, from `doom/agents.sh`, cockpits and Alacritty included.
  Waiting for you comes first, then done, working and idle; pi only ever shows
  as running. RET jumps to the agent's project workspace (an agent outside
  Emacs only says which session it's in), `g` refreshes, and it refreshes
  itself every 3 s while shown.
- Emacs's Claude is a claude-code-ide session: its edits open in ediff, and it
  sees the open file, the selection, diagnostics and xref. `C-c o c` opens its
  menu. `M-x claude-code-ide` starts another one in the project, under a name
  you pick (`<project> :: claude-ide:<name>`); C-x C-b shows which is which.

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
| Launch an app (wofi) | `Super P` or `Super Space` |
| Lock | `Super L`; also after 10 min idle and before every suspend |
| Lock, suspend, log out, reboot, shut down | `Super Escape`, or the bar's power button |
| Next / previous window, in order (not most-recent first) | `Alt Tab` / `Alt Shift Tab`, or `Super Tab` / `Super Shift Tab` |
| Focus, move, resize a window | `Super` + arrows, `Super Shift` + `h j k l`, `Super Alt` + `h j k l` |
| Workspace 1-10, send a window to 1-5 | `Super 1`..`0`, `Super Shift 1`..`5` |
| Wifi | click the bar's network pill: nmtui lists the networks in range and asks for the password; right-click edits saved networks |
| Power profile | click the bolt/scale/leaf in the bar: performance, balanced, power saver |
| Screen brightness | the brightness keys (`Fn F5` / `Fn F6`, held to repeat, also on the lock screen), or scroll on the bar's brightness pill: 5% steps, never below 5% (hidden without a backlight) |
| Screenshot of a region, then copy it, save it to `~/Pictures/Screenshots`, or both | `Print` or `Super Shift S` |
| Dismiss a notification | click it |
| See the agents, and which one waits | Emacs's agents list, in its `main` workspace; `C-c o a` from anywhere in Emacs (see [Terminals and crashes](#terminals-and-crashes)) |

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
- Caps Lock is a second Ctrl (`kb_options = "ctrl:nocaps"` in
  `hypr/hyprland.lua`); there is no Caps Lock key left.
- `Super M` quits Hyprland without asking.
- `Hyprland --verify-config -c hypr/hyprland.lua` checks syntax and option
  names, not dispatcher arguments.

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

gptel (and pi) talk to a local `llama-server` on port 9091 that offers every
model of the machine's presets file and loads the one asked for; gptel reads
the list from the server. Emacs side: `doom/lisp/llm.el`, `doom/lisp/llm-tools.el`.

| File | GPU | Models (gptel names) |
| --- | --- | --- |
| `llama/home.ini` | 8 GB | `gemma-4-12b` |
| `llama/work.ini` | 24 GB | `gemma-4-26b-a4b` (default), `qwen3-coder-30b`, `gemma-4-31b` |

Install with `./deps.sh --skip-base --llama` (any distro, re-run to update).
Then, once per machine, create the API key the server and gptel share (never
committed) and enable the user service, `@home` or `@work` after the presets file:

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

- One model in VRAM at a time, reachable from localhost only, never from a web
  page, and only with the key (flags in `systemd/llama-server@.service`).
- A model downloads into `~/.cache/huggingface` on first use (15-18 GB for the
  work models); that first request waits for it.

### gptel tools

Reading tools run without asking; `write_file` waits for `C-c C-c` (run) or
`C-c C-k` (reject). No tool reaches remote paths, `.gpg`/`.age` files or
`my/gptel-tool-denied-paths` (`~/.ssh`, `~/.gnupg`, `~/.password-store`,
`~/.aws`, `~/.extra_config`, ...).

### pi on the local model

`Alt f` in a cockpit shows or hides it; `pi-local` starts it anywhere else. It
uses the loaded model, searches the notes in `~/notes` (or `$MY_NOTES_DIR`), and
`pi/guard.ts` gives it gptel's rules: reading runs, `edit`/`write` ask, no
`bash`, the same denied paths plus `/proc`. Don't `/login llama.cpp` in pi: a
stored key wins over the key file and goes stale.

### Add or change a model

Add a section to the presets file and restart the server. The section name is
the name gptel shows, the keys are `llama-server` flags without dashes, and
`[*]` holds what every model shares:

```ini
[my-model]
hf-repo = ggml-org/<repo>-GGUF:<quant>   ; the quants a repo offers are listed on Hugging Face
c = 32768                                ; context size; keep it at 16384 or more (the tools assume 16k)
load-on-startup = true                   ; optional, one model per file: the default
```

On first use, check the context it got and that it fits in VRAM; lower `c` if it
spills onto the CPU:

```sh
curl -s 'localhost:9091/props?model=gemma-4-26b-a4b' | grep -o '"n_ctx":[0-9]*'
nvidia-smi --query-gpu=memory.used,memory.total --format=csv
```
