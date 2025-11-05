{ self, lib, ... }:
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

      tui = {
        packages = (with pkgs; [ gum openssl ])
         ++ (with self'.packages; [ pico-fido-tool pico-hsm-tool ]);
        scripts = with pkgs; {
            service-scripts =  [
          (writeShellScriptBin "wizard-picker" ''
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
                    EXEC_NEXT="exit"
                fi
                done
                sleep 1
              else
                gum style "Environment is not available. Welcome to shell!"
            fi
          '')

          (writeShellScriptBin "wizard-start" ''
            if [[ -n $TUI_DEPLOY ]];
              then
                gum style --padding "1 2" --margin 1 "You will be asked to go through wizard to aid your key setup journey."
                generate-key
                generate-firmware
                enter-pin
            fi
            wizard-picker
            if [[ -z $TUI_EXIT ]];
              then
                exit
            fi
          '')
        
          (writeShellScriptBin "generate-key" ''
            gum confirm --negative="Existing pem key" --affirmative="Generate key" --default=0 "Select private pem key option:" \
             && export KEYPATH="$KEYDIRPATH/key.pem" KEYGEN=1 \
             || export KEYPATH=$(gum input --placeholder="/path/to/key")
            if [[ -n $KEYGEN ]];
              then
                mkdir -p $KEYDIRPATH
                openssl ecparam -genkey -name secp256k1 -noout -out $KEYPATH
            fi
            export KEYPATH=$(realpath $KEYPATH)
          '')

          (writeShellScriptBin "generate-firmware" ''
            gum confirm --negative="Existing firmware" --affirmative="Generate firmware" --default=0 "Select firmware option:" \
             || FWGEN=1 
            if [[ -n $FWGEN ]];
              then
                export FWPATH=$(gum input --placeholder="/path/to/firmware")
              else
                gum confirm --negative="Pick defaults" --affirmative="Custom value" --default=0 "Board options:" \
                && export BOARDTYPE=$(gum input --placeholder="YourValue") \
                || export BOARDTYPE=$(gum choose $BOARDTYPES --select-if-one)

                gum confirm --negative="Pick defaults" --affirmative="Custom value" --default=0 "Vid/Pid options:" \
                && export VIDPID=$(gum input --placeholder="YourValue") \
                || export VIDPID=$(gum choose $VIDPIDVALS --select-if-one)

                gum confirm --negative="Disable" --affirmative="Enable" --default=0 "Select eddsa support option:" \
                && export EDDSASUPPORT="true" \
                || export EDDSASUPPORT="false"

                gum confirm --negative="Disable" --affirmative="Enable" --default=0 "Select delayed boot option:" \
                && export DELAYEDBOOT=true \
                || export DELAYEDBOOT=false

                NIX_CONF_DIR=/var/empty \
                # gum spin --title="Builting firmware..." -- \
                nix --option standbox-paths $KEYDIRPATH \
                 --extra-experimental-features 'nix-command flakes' \
                 $NIXPATHS $NIXCONF -L build --impure --expr \
                '(builtins.getFlake "${self.outPath}").packages.$''\{builtins.currentSystem}.pico-fido2.override
                 {
                     picoBoard = "'$BOARDTYPE'";
                     vidPid = "'$VIDPID'";
                     delayedBoot = '$DELAYEDBOOT';
                     eddsaSupport = '$EDDSASUPPORT';
                }'
                # secureBootKey = "'$KEYPATH'" ;
            fi
          '')

          (writeShellScriptBin "enter-pin" ''
            gum style --border="normal" --padding "1 2" --margin 1 "WARNING! PLEASE BE CAREFUL! Enter pin:"
            KEYPIN=$(gum input --placeholder="PIN")
          '')
        ];

        picker-scripts = [
          (writeShellScriptBin "generate-public-pem" ''
            openssl ec -in $KEYPATH -pubout -out ${tui.envvars.aux.KEYDIRPATH}/public.pem
          '')
          (writeShellScriptBin "picotool-set-otp-keys" ''
            pico-fido-tool otp load ${tui.envvars.aux.KEYDIRPATH}/otp.json
            pico-fido-tool otp set OTP_DATA_CRIT1.DEBUG_DISABLE 1
            pico-fido-tool otp set OTP_DATA_BOOT_FLAGS1.KEY_INVALID 0xe
            pico-fido-tool otp set OTP_DATA_CRIT1.GLITCH_DETECTOR_ENABLE 1
            pico-fido-tool otp set OTP_DATA_CRIT1.GLITCH_DETECTOR_SENS 3
          '')
          (writeShellScriptBin "picotool-seal" ''
            picotool seal result/*.uf2 test.uf2 $KEYPATH --sign --hash
          '')
          (writeShellScriptBin "disable-leds" ''
            pico-fido-tool -p $KEYPIN phy led_dimmable disable
            pico-fido-tool -p $KEYPIN phy led_brightness 1
          '')         
        ];
          
        };
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
            DESCRIPTION = "Wizard shell";
            TUI_HOOK = mapVar tui.scripts.picker-scripts;
            TUI_DEPLOY = 1;
            TUI_EXIT = 1;
            KEYDIRPATH = "keys";
            BOARDTYPES = "
              0xcb_helios
              adafruit_feather_rp2040
              adafruit_feather_rp2040_adalogger
              adafruit_feather_rp2040_usb_host
              adafruit_feather_rp2350
              adafruit_fruit_jam
              adafruit_itsybitsy_rp2040
              adafruit_kb2040
              adafruit_macropad_rp2040
              adafruit_qtpy_rp2040
              adafruit_trinkey_qt2040
              amethyst_fpga
              archi
              arduino_nano_rp2040_connect
              cytron_maker_pi_rp2040
              datanoisetv_rp2040_dsp
              datanoisetv_rp2350_dsp
              defcon32_badge
              eelectronicparts_picomini_16mb
              eelectronicparts_picomini_2mb
              eelectronicparts_picomini_4mb
              eelectronicparts_picomini_8mb
              eetree_gamekit_rp2040
              garatronic_pybstick26_rp2040
              gen4_rp2350_24
              gen4_rp2350_24ct
              gen4_rp2350_24t
              gen4_rp2350_28
              gen4_rp2350_28ct
              gen4_rp2350_28t
              gen4_rp2350_32
              gen4_rp2350_32ct
              gen4_rp2350_32t
              gen4_rp2350_35
              gen4_rp2350_35ct
              gen4_rp2350_35t
              hellbender_0001
              hellbender_2350A_devboard
              ilabs_challenger_rp2350_bconnect
              ilabs_challenger_rp2350_wifi_ble
              ilabs_opendec02
              machdyne_werkzeug
              melopero_perpetuo_rp2350_lora
              melopero_shake_rp2040
              metrotech_xerxes_rp2040
              net8086_usb_interposer
              nullbits_bit_c_pro
              olimex_rp2350_xl
              olimex_rp2350_xxl
              phyx_rick_tny_rp2350
              pi-plates_micropi
              pico
              pico2
              pico2_w
              pico_w
              pimoroni_badger2040
              pimoroni_interstate75
              pimoroni_keybow2040
              pimoroni_motor2040
              pimoroni_pga2040
              pimoroni_pga2350
              pimoroni_pico_plus2_rp2350
              pimoroni_pico_plus2_w_rp2350
              pimoroni_picolipo_16mb
              pimoroni_picolipo_4mb
              pimoroni_picosystem
              pimoroni_plasma2040
              pimoroni_plasma2350
              pimoroni_servo2040
              pimoroni_tiny2040
              pimoroni_tiny2040_2mb
              pimoroni_tiny2350
              pololu_3pi_2040_robot
              pololu_zumo_2040_robot
              seeed_xiao_rp2040
              seeed_xiao_rp2350
              solderparty_rp2040_stamp
              solderparty_rp2040_stamp_carrier
              solderparty_rp2040_stamp_round_carrier
              solderparty_rp2350_stamp
              solderparty_rp2350_stamp_xl
              sparkfun_iotnode_lorawan_rp2350
              sparkfun_iotredboard_rp2350
              sparkfun_micromod
              sparkfun_promicro
              sparkfun_promicro_rp2350
              sparkfun_thingplus
              sparkfun_thingplus_rp2350
              sparkfun_xrp_controller
              switchscience_picossci2_conta_base
              switchscience_picossci2_dev_board
              switchscience_picossci2_micro
              switchscience_picossci2_rp2350_breakout
              switchscience_picossci2_tiny
              tinycircuits_thumby_color_rp2350
              uugear_wittypi5_hat_plus
              vgaboard
              waveshare_pico_cam_a
              waveshare_rp2040_ble
              waveshare_rp2040_eth
              waveshare_rp2040_geek
              waveshare_rp2040_lcd_0.96
              waveshare_rp2040_lcd_1.28
              waveshare_rp2040_matrix
              waveshare_rp2040_one
              waveshare_rp2040_pizero
              waveshare_rp2040_plus_16mb
              waveshare_rp2040_plus_4mb
              waveshare_rp2040_power_management_hat_b
              waveshare_rp2040_tiny
              waveshare_rp2040_touch_lcd_1.28
              waveshare_rp2040_zero
              waveshare_rp2350_eth
              waveshare_rp2350_geek
              waveshare_rp2350_lcd_0.96
              waveshare_rp2350_lcd_1.28
              waveshare_rp2350_one
              waveshare_rp2350_plus_16mb
              waveshare_rp2350_plus_4mb
              waveshare_rp2350_tiny
              waveshare_rp2350_touch_lcd_1.28
              waveshare_rp2350_usb_a
              waveshare_rp2350_zero
              weact_studio_rp2040_16mb
              weact_studio_rp2040_2mb
              weact_studio_rp2040_4mb
              weact_studio_rp2040_8mb
              weact_studio_rp2350b_core
              wiznet_w5100s_evb_pico
              wiznet_w5100s_evb_pico2
            ";
            VIDPIDVALS = "
              NitroHSM
              NitroFIDO2
              NitroStart
              NitroPro
              Nitro3
              Yubikey5
              YubikeyNeo
              YubiHSM
              Gnuk
              GnuPG
            ";
          };
        };
        hook = {
          shellHook = ''
            clear
            trap "clear" EXIT
            gum style --padding "1 2" --margin 1 \
             "Hello! Welcome to $DESCRIPTION environment.
             To start wizard type 'wizard-start'!
             To start picker type 'wizard-picker'"
          '';
        };
        main = with tui; ({
           packages = packages ++ scripts.service-scripts;
         } // envvars.gum // envvars.aux // hook
        );
      };


    in

    {
      devShells = {
        core = pkgs.mkShellNoCC (recursiveMerge [
          tui.main
        ]);
        default = config.devShells.core;
      };
    };
}
