# Onboard NIC: Realtek RTL8125 2.5GbE (PCI 10ec:8125 rev 0c, enp8s0)
#
# This machine has a long history of ethernet link instability. The switches
# at the top of this file exist so the remaining hypotheses can be A/B tested
# by flipping one boolean and rebuilding, rather than by hand-editing the
# config each time.
#
# ── HISTORY ─────────────────────────────────────────────────────────────
#
# 1. Original fault: the in-kernel r8169 driver link-flapped on this chip and
#    downshifted to 100Mbps every 60-90s, which was the real cause of
#    SteamVR's "Host Machine stopped responding" (error 450) disconnects —
#    confirmed by dmesg timestamps lining up with the SteamVR log. Fixed at
#    the time by blacklisting r8169 in favour of Realtek's out-of-tree r8125.
#
# 2. Current fault (still open): the link flaps again, but this is NOT a
#    return of that bug. Measured under r8125 9.016.01:
#      - 58 carrier changes in 2h19m, drops of ~4s, irregular (5s-700s apart)
#      - every re-negotiation returns at the FULL 2500Mb/s, never 100Mbps,
#        so the old signature does not match
#      - no PCIe AER errors, no driver resets, no Tx timeouts in the log
#      - present in the previous boot too, so not caused by recent changes
#
# 3. Ruled out — EEE (802.3az). ethtool showed EEE enabled and advertised on
#    100/1000/2500baseT while the link partner advertised none, which is a
#    classic RTL8125 flap cause. Disabling it made no difference: EEE now
#    reports "disabled" and the flap rate did not improve (it rose from 24
#    changes/1h43m to 58/2h19m). The setting is kept off anyway since it is
#    harmless and removes a variable, but it is not the fault.
#
# ── REMAINING HYPOTHESES ────────────────────────────────────────────────
#
# A. Physical layer marginal at 2.5G. 2.5GBASE-T is far more sensitive to
#    cable quality and crosstalk than 1000BASE-T; Cat5e that is perfectly
#    stable at 1G can be marginal at 2.5G. Test with `pinTo1Gbit = true`
#    below: if the flapping stops at 1G, this is cabling or the switch port,
#    not software, and no amount of driver tuning will fix it.
#
# B. The out-of-tree r8125 driver is itself the problem now. The blacklist in
#    (1) was added against a much older kernel. This kernel (6.18.45) ships
#    an r8169 that explicitly claims this chip
#    (alias pci:v000010ECd00008125) and has had substantial RTL8125 work
#    since. Test with `useOutOfTreeDriver = false`.
#
# Test A first: it is non-destructive, needs no reboot to try by hand, and
# its result determines whether B is even worth running.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  ##########################################################################
  ## A/B switches — flip one at a time, rebuild, then watch
  ##   cat /sys/class/net/enp8s0/carrier_changes
  ##########################################################################

  # true  = Realtek out-of-tree r8125 (taints kernel; current fault present)
  # false = in-kernel r8169 shipped with the running kernel
  useOutOfTreeDriver = true;

  # Advertise only 1000baseT/Full, dropping 2.5G from auto-negotiation.
  # This is the decisive test for hypothesis A.
  pinTo1Gbit = false;

  # Keep 802.3az off. Ruled out as the cause, but removing the variable
  # costs nothing and the link partner does not support it anyway.
  disableEEE = true;

  interface = "enp8s0";
in
{
  ## Driver selection #######################################################
  boot.blacklistedKernelModules = lib.optional useOutOfTreeDriver "r8169";
  boot.extraModulePackages = lib.optional useOutOfTreeDriver config.boot.kernelPackages.r8125;
  boot.kernelModules = lib.optional useOutOfTreeDriver "r8125";

  # Module parameters only take effect when the module loads, which is why
  # the ethtool unit below also exists.
  boot.extraModprobeConfig = lib.optionalString (useOutOfTreeDriver && disableEEE) ''
    options r8125 eee_enable=0
  '';

  ## Link tuning ############################################################
  # Applied with ethtool so it takes hold on `nixos-rebuild switch` rather
  # than only after a reboot, and survives a driver reload.
  systemd.services.nic-link-tuning = {
    description = "Link tuning for ${interface} (RTL8125 flap workaround)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-pre.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    # Every step fails soft: this is optional tuning and must never be able
    # to block the boot if the interface is renamed or absent.
    script = ''
      if [ ! -e /sys/class/net/${interface} ]; then
        echo "${interface} not present, nothing to tune"
        exit 0
      fi

      ${lib.optionalString disableEEE ''
        ${pkgs.ethtool}/bin/ethtool --set-eee ${interface} eee off || true
      ''}

      ${lib.optionalString pinTo1Gbit ''
        # autoneg stays ON: 1000BASE-T requires auto-negotiation by spec, so
        # this restricts what is advertised rather than force-setting a link
        # rate, which would be non-compliant and can fail to train at all.
        ${pkgs.ethtool}/bin/ethtool -s ${interface} \
          speed 1000 duplex full autoneg on || true
      ''}
    '';
  };

  environment.systemPackages = [ pkgs.ethtool ];
}
