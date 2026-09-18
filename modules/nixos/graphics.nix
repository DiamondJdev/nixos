# GPU stack and gaming. Radeon RX 7800 XT (RDNA3, amdgpu).
{ pkgs, ... }:
{
  hardware.graphics = {
    enable = true;
    # Plan §6.7: 32-bit userspace GL/Vulkan is required by Proton and by a
    # large fraction of the native Linux Steam catalogue. Losing this is a
    # silent, confusing failure mode (games launch to a black window), so
    # it is called out rather than left implicit.
    enable32Bit = true;
  };

  hardware.amdgpu.opencl.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  # Plan §45: gamemode lets a game request a governor/scheduler change and,
  # crucially, *reverts it when the process dies* — including on a crash.
  # That reversibility is exactly what the plan asks for and is why the
  # effect toggles hang off gamemode hooks rather than a bare script.
  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    mangohud
    heroic
  ];
}
