# Audio, Bluetooth and controllers.
{ pkgs, ... }:
{
  ## Audio — plan §39 ######################################################
  # PipeWire only. Plan §39 explicitly forbids running a second, competing
  # audio server, so PulseAudio is disabled rather than left at its default.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  ## Bluetooth — plan §40 ##################################################
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General.Experimental = true; # battery level reporting
  };
  services.blueman.enable = true;

  ## Controllers ###########################################################
  hardware.xpadneo.enable = true; # Xbox wireless/Bluetooth controllers

  environment.systemPackages = with pkgs; [
    pavucontrol
    playerctl
    brightnessctl
  ];
}
