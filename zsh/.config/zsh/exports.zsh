# Append binaries to path
export PATH=$HOME/.local/bin:$PATH
export PATH=/opt/homebrew/bin:$PATH
export PATH=/opt/local/bin:$PATH
export PATH=$HOME/.cargo/bin:$PATH
export PATH=$HOME/.fnm:$PATH
export ANDROID_SDK_ROOT=$HOME/Library/Android/sdk/
export PATH=$ANDROID_SDK_ROOT/emulator:$PATH
export PATH=$HOME/Library/Python/3.9/bin:$PATH
export PATH=$ANDROID_SDK_ROOT/platform-tools:$PATH

# Set up GPG
export GPG_TTY=$(tty)

# You may need to manually set your language environment
export LANG=en_US.UTF-8

export EDITOR='nvim'
# export BROWSER='firefox'
export LC_CTYPE=en_US.UTF-8
export MANPAGER='nvim +Man!'

# Set vi-mode cursor mode
VI_MODE_SET_CURSOR=true
