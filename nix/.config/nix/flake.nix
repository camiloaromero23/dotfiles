{
  description = "MacOS Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:
    let
      configuration = { pkgs, config, lib, ... }: {
        # List packages installed in system profile. To search by name, run:
        # $ nix-env -qaP | grep wget

        nixpkgs.config.allowUnfree = true;

        environment.variables = {
          LC_ALL = "en_US.UTF-8";
          LANG = "en_US.UTF-8";
        };

        # Link vendor fish snippets (e.g., nix-darwin PATH hooks)
        # environment.pathsToLink = [ "/share/fish" ];

        # environment.systemPackages = [ pkgs.fish ];

        homebrew = {
          enable = true;
          brews = [
            "Azure/kubelogin/kubelogin"
            "atuin"
            "azure-cli"
            "bat"
            "bob"
            "btop"
            "bun"
            "cmake"
            "cmatrix"
            "csvlens"
            "curl"
            "delta"
            "eza"
            "fd"
            "ffmpeg"
            "fish"
            "fnm"
            "fzf"
            "gettext"
            "gh"
            "ghostscript"
            "git"
            "gnu-getopt"
            "gnupg"
            "go"
            "gromgit/brewtils/taproom"
            "htop"
            "hyperfine"
            "jq"
            "imagemagick"
            "kanata"
            "lazygit"
            "lazydocker"
            "lua"
            "mole"
            "ninja"
            "pass"
            "pass-otp"
            "pass-update"
            "pinentry-mac"
            "poppler"
            "postgresql"
            "resvg"
            "ripgrep"
            "rustup"
            "rift"
            "sevenzip"
            "silicon"
            "sqlcmd"
            "starship"
            "stow"
            "tmux"
            "uv"
            "yazi"
            "zoxide"
            "zsh-autosuggestions"
            "zsh-syntax-highlighting"
            "zbar"
          ];
          casks = [
            "aerospace"
            "brave-browser@nightly"
            "chatgpt"
            "claude"
            "claude-code"
            "codex"
            "drawio"
            "font-symbols-only-nerd-font"
            "ghostty"
            "google-chrome@beta"
            "homerow"
            "httpmon"
            "keycastr"
            "kitty"
            "legcord"
            "logi-options+"
            "microsoft-auto-update"
            "microsoft-excel"
            "microsoft-powerpoint"
            "microsoft-teams"
            "microsoft-word"
            "monitorcontrol"
            "obsidian"
            "orbstack"
            "pcsx2"
            "postman"
            "raycast"
            "responsively"
            "shottr"
            "slack"
            "spotify"
            "stats"
            "supercmd"
            "visual-studio-code"
            "whatsapp"
            "yaak"
            "zed"
            "zen"
          ];
          taps = [
            "acsandmann/tap"
            "kostyay/tap"
            "nikitabobko/tap"
            "oven-sh/bun"
            "simplydanny/pass-extensions"
            "supercmdlabs/supercmd"
          ];
          onActivation.cleanup = "zap";
          onActivation.autoUpdate = true;
          onActivation.upgrade = true;
        };

        system.primaryUser = "camilo";

        # system.activationScripts.postUserActivation.text = ''
        # # Following line should allow us to avoid a logout/login cycle
        # /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
        # '';
        system.defaults = {
          dock = {
            autohide = true;
            expose-group-apps = true;
            persistent-apps = [ ];
            static-only = true;
            tilesize = 64;
          };
          loginwindow.GuestEnabled = false;
          menuExtraClock.Show24Hour = true;
          controlcenter.BatteryShowPercentage = true;
          NSGlobalDomain = {
            ApplePressAndHoldEnabled = false;
            AppleICUForce24HourTime = true;
            AppleKeyboardUIMode = 3;
            AppleInterfaceStyle = "Dark";
            KeyRepeat = 2;
            AppleEnableSwipeNavigateWithScrolls = true;
          };
          trackpad = {
            Clicking = true;
          };
          CustomUserPreferences = {
            "com.apple.controlcenter" = {
              "NSStatusItem Visible Battery" = false;
            };
            "com.apple.symbolichotkeys" = {
              AppleSymbolicHotKeys = {
                # Cycle through input sources (next)
                "60" = {
                  enabled = false;
                  value = {
                    parameters = [ 32 49 262144 ];
                    type = "standard";
                  };
                };
                # Cycle through input sources (previous)
                "61" = {
                  enabled = false;
                  value = {
                    parameters = [ 32 49 786432 ];
                    type = "standard";
                  };
                };
                # Spotlight
                "64" = {
                  enabled = true;
                  value = {
                    parameters = [ 32 49 1572864 ]; # 49 = space key, 524288 = Option modifier
                    type = "standard";
                  };
                };
                # Cycle through windows of the same app
                "27" = {
                  enabled = true;
                  value = {
                    parameters = [ 99 8 1966080 ];
                    type = "standard";
                  };
                };
                # Screenshot - Entire Screen
                "28" = {
                  enabled = false;
                  value = {
                    parameters = [ 51 20 1179648 ];
                    type = "standard";
                  };
                };
                # Screenshot - Selected Portion
                "29" = {
                  enabled = false;
                  value = {
                    parameters = [ 52 21 1179648 ];
                    type = "standard";
                  };
                };
                # Screenshot - Window
                "30" = {
                  enabled = false;
                  value = {
                    parameters = [ 53 22 1179648 ];
                    type = "standard";
                  };
                };
                # Screenshot to clipboard - Entire Screen
                "31" = {
                  enabled = false;
                  value = {
                    parameters = [ 51 20 1441792 ];
                    type = "standard";
                  };
                };
                # Screenshot to clipboard - Selected Portion
                "32" = {
                  enabled = false;
                  value = {
                    parameters = [ 52 21 1441792 ];
                    type = "standard";
                  };
                };
                # Screenshot to clipboard - Window
                "33" = {
                  enabled = false;
                  value = {
                    parameters = [ 53 22 1441792 ];
                    type = "standard";
                  };
                };
                # Screenshot and recording options
                "184" = {
                  enabled = true;
                  value = {
                    parameters = [ 54 22 1179648 ];
                    type = "standard";
                  };
                };
              };
            };
          };
        };

        # Auto upgrade nix package and the daemon service.
        # services.nix-daemon.enable = true;
        # nix.package = pkgs.nix;
        nix.enable = true;

        # Necessary for using flakes on this system.
        nix.settings.experimental-features = "nix-command flakes";

        # Create /etc/zshrc that loads the nix-darwin environment.
        programs.zsh.enable = true; # default shell on catalina
        # programs.fish = {
        #   enable = true;
        #   shellInit = ''
        #     for p in $HOME/.nix-profile /etc/profiles/per-user/$USER /run/current-system/sw /nix/var/nix/profiles/default
        #       if test -d "$p/bin"
        #         fish_add_path "$p/bin"
        #       end
        #     end
        #   '';
        # };

        # Ensure login shells get Nix paths too (zsh, bash, etc.)
        environment.loginShellInit = ''
          for p in "$HOME/.nix-profile" "/etc/profiles/per-user/$USER" "/run/current-system/sw" "/nix/var/nix/profiles/default"
          do
            [ -d "$p/bin" ] && export PATH="$p/bin:$PATH"
          done
        '';

        # Set Git commit hash for darwin-version.
        system.configurationRevision = self.rev or self.dirtyRev or null;

        # Used for backwards compatibility, please read the changelog before changing.
        # $ darwin-rebuild changelog
        system.stateVersion = 5;

        # The platform the configuration will be used on.
        nixpkgs.hostPlatform = "aarch64-darwin";
      };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#simple
      darwinConfigurations."mac" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              # Apple Silicon only
              enableRosetta = true;
              user = "camilo";
              autoMigrate = true;
            };
          }
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."mac".pkgs;
    };
}
