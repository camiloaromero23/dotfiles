# Dotfiles

**NOTE:** Clone this repo on your home folder for the setup script to run appropriately. Otherwise, update the link path to match the repo's location
>
>## Clone repository
>
>To clone the repository including submodules:
>
>```bash
>git clone --recurse-submodules -j8 <repository_location>
>```
>
>Otherwise:
>
>```bash
>git clone
>```
>
>### Load submodules
>
>To load submodules after cloning the repo:
>
>```bash
>git submodule update --init --recursive
>```

## Make the script executable

```bash
chmod +x setup.sh
```

## Check files to be linked

To check the files that are going to be linked:

``` bash
./setup.sh
```

> Modify `setup.sh` to remove any of the dotfiles to linking process

## Link files

To link all the files:

``` bash
./setup.sh | bash
```
