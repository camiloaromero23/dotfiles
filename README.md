# Dotfiles

To include all the dotfiles, install git & gnu stow

To stow all the dotfiles run:

``` bash
stow --target=$HOME */
```

To stow only some configs run:

``` bash
stow --target=$HOME <folder_name>
```

To re-generate installed ports from macports run:

```bash
port installed requested | tail -n+2 | awk '{print $1;}' | uniq > installed_ports
```

To re-generate installed crates from cargo run:

```bash
cat ~/.cargo/.crates2.json | jq -r '.installs | keys[] | split(" ")[0]' > installed_crates
```

## Toolchains (mise)

Language toolchains (go, node, rust, bun, uv, pi, neovim) are managed by [mise](https://mise.jdx.dev)
instead of Homebrew. The declared tool set lives in `mise/.config/mise/config.toml`
and is stowed to `~/.config/mise/config.toml`.

After stowing, install the declared toolchains:

```bash
mise install
```

`zsh/.zshenv` puts the mise shims on PATH so non-interactive shells resolve them;
`zsh/.config/zsh/.zshrc` and `fish/.config/fish/config.fish` activate mise
interactively. Homebrew provides `mise` itself, the CLI tools, and the casks — not
language runtimes.
