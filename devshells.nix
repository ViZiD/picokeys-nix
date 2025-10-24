{ lib, ... }:
{
  perSystem =
    {
      pkgs,
      config,
      self',
      ...
    }:
    let
      recursiveMerge =
        with lib;
        attrList:
        let
          f =
            attrPath:
            zipAttrsWith (
              n: values:
              if tail values == [ ] then
                head values
              else if all isList values then
                unique (concatLists values)
              else if all isAttrs values then
                f (attrPath ++ [ n ]) values
              else
                last values
            );
        in
        f [ ] attrList;

      # cursed scripts
      # runPkg = pkgs: pkg: "${pkgs.${pkg}}/bin/${pkg}";
      # run = pkg: runPkg pkgs pkg;
      mapVar = map (x: x.name);

      tui = with pkgs; {
        packages = [ gum ];
        scripts = [
        ];
        envvars = {
          gum = {
            # GUM_CHOOSE_ORDERED = true;
            GUM_CHOOSE_ITEM_FOREGROUND = "";
            GUM_CHOOSE_SELECTED_FOREGROUND = "212";
            GUM_CHOOSE_HEADER_FOREGROUND = "240";
            # GUM_CONFIRM_TIMEOUT = "5s";
            # GUM_CONFIRM_DEFAULT =
            # GUM_CONFIRM_PROMPT_FOREGROUND = 212;
            GUM_INPUT_PLACEHOLDER = "";
            BORDER = "normal";
            # MARGIN = "1";
            # PADDING = "1 2";
            FOREGROUND = "212";
          };
          aux = {
            KEYDIRPATH = "keys";
            BOARDTYPE = "waveshare_rp2350_one";
          };
        };
        hook = {
          shellHook = ''
            clear
            trap "clear" EXIT
            gum style --padding "1 2" --margin 1 "Hello! Welcome to $DESCRIPTION environment."
            if [[ -n $TUI_DEPLOY ]];
              then
                gum style --padding "1 2" --margin 1 "You will be asked to go through wizard to aid your key setup journey."
                generate-key
                generate-firmware
                enter-pin
            fi
            if [[ -n $TUI_HOOK ]];
              then
                gum style "Press C-c to enter shell!"
                while [[ -z $EXEC_NEXT ]]
                do
                EXEC_NEXT=$(gum choose $TUI_HOOK "exit" --select-if-one)
                if [ -z $EXEC_NEXT ];
                  then
                    gum style "Nothing was picked or environment is not available. Welcome to shell!" 
                    TUI_EXIT="0"
                    break
                  else 
                    gum confirm --negative="Nay" --affirmative="YOLO!" --default=0 $EXEC_NEXT \
                      && gum spin "$($EXEC_NEXT)" \
                      && gum style --foreground 260 "Done!" \
                      || gum style Abort!
                      # unset EXEC_NEXT
                    EXEC_NEXT="0"
                fi
                done
                sleep 1
              else
                gum style "Environment is not available. Welcome to shell!"
            fi
            if [[ -n $TUI_EXIT ]];
              then
                exit
            fi
          '';
        };
        main = with tui; ({ packages = packages ++ scripts; } // envvars.gum // envvars.aux // hook);
      };

      core = {
        packages =
          (with pkgs; [ openssl ])
          ++ (with self'.packages; [
            pico-fido-tool
            pico-hsm-tool
          ]);

        scripts = with pkgs; [
          (writeShellScriptBin "generate-key" ''
            gum confirm --negative="Existing pem key" --affirmative="Generate key" --default=0 "Select private pem key option:" \
             && KEYPATH="$KEYDIRPATH/key.pem" KEYGEN=1 \
             || KEYPATH=$(gum input --placeholder="/path/to/key")
            if [[ -n $KEYGEN ]];
              then
                mkdir -p $KEYDIRPATH
                openssl ecparam -genkey -name secp256k1 -noout -out $KEYPATH
            fi
            KEYPATH=$(realpath $KEYPATH)
          '')

          (writeShellScriptBin "generate-firmware" ''
            gum confirm --negative="Existing firmware" --affirmative="Generate firmware" --default=0 "Select firmware option:" \
             || FWGEN=1 
            if [[ -n $FWGEN ]];
              then
                FWPATH=$(gum input --placeholder="/path/to/firware")
              else
                gum confirm --negative="Use default" --affirmative="Use vidpid" --default=0 "Select vid/pid option:" \
                && VIDPID=$(gum input --placeholder="/path/to/firware") \
                || VIDPID="Yubikey"
                gum confirm --negative="Disable" --affirmative="Enable" --default=0 "Select eddsa support option:" \
                && EDDSASUPPORT="true" || EDDSASUPPORT="false"
                gum confirm --negative="Disable" --affirmative="Enable" --default=0 "Select delayed boot option:" \
                && DELAYEDBOOT="true" || DELAYEDBOOT="false"
                NIX_CONF_DIR=/var/empty gum spin --title="Builting firmware..." -- \
                nix --option standbox-paths $KEYDIRPATH \
                 --extra-experimental-features 'nix-command flakes' \
                 $NIXPATHS $NIXCONF -L build --impure --expr \
                '(builtins.getFlake "github:vizid/picokeys-nix?ref=dev").packages.$''\{builtins.currentSystem}.pico-fido2.override
                { picoBoard = "'$BOARDTYPE'"; vidPid = "'$VIDPID'"; delayedBoot = '$DELAYEDBOOT'; eddsaSupport = '$EDDSASUPPORT';
                }'
                # secureBootKey = "'$KEYPATH'" ;
            fi
          '')

          (writeShellScriptBin "enter-pin" ''
            gum style --border="normal" --padding "1 2" --margin 1 "WARNING! PLEASE BE CAREFUL! Enter pin:"
            KEYPIN=$(gum input --placeholder="PIN")
          '')

          (writeShellScriptBin "generate-public-pem" ''
            openssl ec -in $KEYPATH -pubout -out ${tui.envvars.aux.KEYDIRPATH}/public.pem
          '')
          (writeShellScriptBin "picotool-set-otp-keys" ''
            sudo pico-fido-tool otp load ${tui.envvars.aux.KEYDIRPATH}/otp.json
            sudo pico-fido-tool otp set OTP_DATA_CRIT1.DEBUG_DISABLE 1
            sudo pico-fido-tool otp set OTP_DATA_BOOT_FLAGS1.KEY_INVALID 0xe
            sudo pico-fido-tool otp set OTP_DATA_CRIT1.GLITCH_DETECTOR_ENABLE 1
            sudo pico-fido-tool otp set OTP_DATA_CRIT1.GLITCH_DETECTOR_SENS 3
          '')
          (writeShellScriptBin "picotool-seal" ''
            picotool seal result/*.uf2 test.uf2 $KEYPATH --sign --hash
          '')
          (writeShellScriptBin "disable-leds" ''
            pico-fido-tool -p $KEYPIN phy led_dimmable disable
            pico-fido-tool -p $KEYPIN phy led_brightness 1
          '')
        ];
        envvars = {
          DESCRIPTION = "Wizard shell";
          TUI_HOOK = mapVar core.scripts;
          TUI_DEPLOY = 1;
          TUI_EXIT = 1;
        };
        main = with core; ({ packages = packages ++ scripts; } // envvars);
      };

      enroll = {
        envvars = {
          DESCRIPTION = "Simple shell";
          TUI_HOOK = mapVar core.scripts;
          TUI_EXIT = 1;
        };
        main = with core; ({ packages = packages ++ scripts; } // enroll.envvars);
      };

    in

    {
      devShells = {
        core = pkgs.mkShellNoCC (recursiveMerge [
          core.main
          tui.main
        ]);
        enroll = pkgs.mkShellNoCC (recursiveMerge [
          enroll.main
          tui.main
        ]);
        default = config.devShells.core;
      };
    };
}
