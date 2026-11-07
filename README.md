# config

ZSH extra config: `~/.extra_config`

Doom packages extra: `doom/extra_packages.el`

Doom config extra: `doom/extra_config.el`

## Setup

```sh
./deps.sh                     # packages, oh-my-zsh, Node, Lean, TLA+, Quint, SDKMAN, ...
./install.sh                  # symlink the configs into ~ and ~/.config
./deps.sh --skip-base --doom  # Doom Emacs, once ~/.config/doom points at this repo
```

`deps.sh` detects Arch/EndeavourOS or Ubuntu 26.04 and is safe to re-run: package
installs skip what is present and each installer skips if its directory exists.
Opt-in extras, combinable:

| Flag | Adds |
| --- | --- |
| `--heavy` | TeX Live, LanguageTool (Arch), PlantUML, Jupyter: several GB |
| `--firewall` | ufw: deny inbound, allow outbound and KDE Connect (1714-1764) |
| `--llama` | `llama.cpp-cuda` from the AUR (Arch only), see [Local LLM](#local-llm-llamacpp) |
| `--doom` | Doom Emacs core + `doom install` |

`--dry-run` prints the commands without running them; `--help` lists every flag.

- Emacs is the Wayland build (`emacs-wayland` on Arch, `emacs-pgtk` on Ubuntu); on
  X11, swap in `emacs` / `emacs-gtk` in `deps.sh`. On Arch it is skipped if any
  installed package already provides `emacs`.
- Ubuntu: most packages live in `universe` (enabled by default on desktop).
- `--firewall` on EndeavourOS disables firewalld first: two firewalls rewriting the
  same nftables rules conflict.
- The NVM, SDKMAN and oh-my-zsh installers are kept from editing `~/.zshrc`, which is
  this repo's `zshrc` and already loads them.

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
./deps.sh --skip-base --llama   # Arch / EndeavourOS, from the AUR
```

### Start the server

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
