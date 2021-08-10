# Dotfiles

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
