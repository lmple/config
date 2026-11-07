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

- Ubuntu: most packages live in `universe` (enabled by default on desktop). On X11,
  swap `emacs-pgtk` for `emacs-gtk` in `deps.sh`.
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
llama-server --version          # 10217 works; 8589 fails with "unknown model architecture: 'gemma4'"
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
