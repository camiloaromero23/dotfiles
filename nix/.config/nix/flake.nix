{
  description = "MacOS Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, neovim-nightly-overlay }:
    let
      configuration = { pkgs, config, lib, ... }: {
        # List packages installed in system profile. To search by name, run:
        # $ nix-env -qaP | grep wget

        nixpkgs.config.allowUnfree = true;

        environment.variables = {
          LC_ALL = "en_US.UTF-8";
          LANG = "en_US.UTF-8";
        };
        environment.systemPackages =
          [ 
            pkgs.alacritty
            pkgs.bat
            pkgs.btop
            pkgs.bun
            pkgs.delta
            pkgs.fd
            pkgs.fnm
            pkgs.fzf
            pkgs.geist-font
            pkgs.go
            pkgs.google-cloud-sdk
            pkgs.htop
            pkgs.jq
            pkgs.kitty
            pkgs.lazygit
            pkgs.lazydocker
            pkgs.lua
            pkgs.mkalias
            pkgs.passExtensions.pass-otp
            pkgs.passExtensions.pass-update
            (pkgs.pass.withExtensions (ext: with ext; [pass-otp pass-update]))
            pkgs.pass
            pkgs.pinentry_mac
            pkgs.ripgrep
            pkgs.rustup
            pkgs.silicon
            pkgs.stow
            pkgs.tmux
            pkgs.uv
            pkgs.vscode
            pkgs.yazi
            pkgs.zbar
            pkgs.zoxide
            pkgs.zsh-autosuggestions
            pkgs.zsh-syntax-highlighting
            neovim-nightly-overlay.packages.${pkgs.system}.default
          ];

        fonts.packages = [
          pkgs.nerd-fonts.caskaydia-cove
          pkgs.nerd-fonts.geist-mono
          pkgs.nerd-fonts.jetbrains-mono
          pkgs.nerd-fonts.symbols-only
          pkgs.nerd-fonts.zed-mono
          pkgs.geist-font
        ];

        homebrew = {
          enable = true;
          brews = [
            "borders"
            "eza"
            "ghostscript"
            "azure-cli"
            "Azure/kubelogin/kubelogin"
            "git"
            "gnupg"
            "imagemagick"
            "sqlcmd"
            "starship"
          ];
          casks = [
            "aerospace"
            "anydesk"
            "arc"
            "firefox"
            "ghostty"
            "homerow"
            "jetbrains-toolbox"
            "karabiner-elements"
            "keycastr"
            "legcord"
            "logi-options+"
            "microsoft-powerpoint"
            "microsoft-teams"
            "microsoft-word"
            "monitorcontrol"
            "obsidian"
            "orbstack"
            "postman"
            "raycast"
            "responsively"
            "shottr"
            "slack"
            "stats"
            "wezterm"
            "whatsapp"
            "vivaldi"
            "yaak"
            "zed"
            "zen-browser"
            "zoom"
          ];
          taps = [
            "nikitabobko/tap"
            "FelixKratz/formulae"
          ];
          onActivation.cleanup = "zap";
          onActivation.autoUpdate = true;
          onActivation.upgrade = true;
        };

        system.activationScripts.applications.text = let
          env = pkgs.buildEnv {
            name = "system-applications";
            paths = config.environment.systemPackages;
            pathsToLink = "/Applications";
          };
        in
          pkgs.lib.mkForce ''
        # Set up applications.
        echo "setting up /Applications..." >&2
        rm -rf /Applications/Nix\ Apps
        mkdir -p /Applications/Nix\ Apps
        find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
        while read -r src; do
          app_name=$(basename "$src")
            echo "copying $src" >&2
            ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
            done
          '';
        system.primaryUser = "camilo";

        # system.activationScripts.postUserActivation.text = ''
        # # Following line should allow us to avoid a logout/login cycle
        # /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
        # '';
        system.defaults = {
          dock = {
            autohide = true;
            expose-group-apps = true;
            persistent-apps = [];
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
                    parameters = [ 32 49 1572864 ];  # 49 = space key, 524288 = Option modifier
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
        programs.zsh.enable = true;  # default shell on catalina
        # programs.fish.enable = true;

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

