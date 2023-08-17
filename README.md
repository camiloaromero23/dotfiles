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
port installed requested | tail -n+2 | awk '{print $1;}' > installed_ports
```

To re-generate installed crates from cargo run:

```bash
cat ~/.cargo/.crates2.json | jq -r '.installs | keys[] | split(" ")[0]' > installed_crates
```
