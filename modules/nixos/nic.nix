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

  # Log the conditions at each carrier change. Diagnostic only.
  logFlaps = true;
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


  ## Flap diagnostics #######################################################
  # Every hypothesis so far has died on the same problem: the flaps cannot be
  # reproduced on demand, and by the time they are noticed the conditions
  # that produced them are gone. Two candidate causes were each plausible and
  # each turned out to be unfalsifiable after the fact:
  #
  #   - "it flaps under load"  — the link was stable for 50 min while idle at
  #     2.5G, then flapped continuously later, but there is no historical
  #     record of the throughput at either time.
  #   - "the wifi is involved" — wlp9s0 reassociates every ~5m20s all boot
  #     long (deauth reason 6, CLASS2_FRAME_FROM_NONAUTH), which is a real
  #     fault in its own right, but it was cycling during the quiet ethernet
  #     period too, so it does not correlate 1:1.
  #
  # So instead of guessing again, this records the conditions AT the moment
  # of each carrier change. One line per flap in the journal, with the
  # throughput over the preceding interval, the negotiated speed, and the
  # wifi state — enough to settle load-correlation and wifi-correlation from
  # a single subsequent occurrence.
  #
  #   journalctl -t nic-flap -b
  #
  # Set to false once the cause is found; it is a diagnostic, not a feature.
  systemd.services.nic-flap-log = lib.mkIf logFlaps {
    description = "Log ${interface} carrier changes with context";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-pre.target" ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = 5;
      SyslogIdentifier = "nic-flap";
    };
    script = ''
      dev=/sys/class/net/${interface}
      [ -e "$dev" ] || exit 0

      last=$(cat "$dev/carrier_changes")
      lastTx=$(cat "$dev/statistics/tx_bytes")
      lastRx=$(cat "$dev/statistics/rx_bytes")
      lastT=$(date +%s)

      echo "watching ${interface}: baseline $last carrier changes"

      while true; do
        sleep 2
        now=$(cat "$dev/carrier_changes" 2>/dev/null) || continue
        tx=$(cat "$dev/statistics/tx_bytes")
        rx=$(cat "$dev/statistics/rx_bytes")
        t=$(date +%s)

        if [ "$now" != "$last" ]; then
          secs=$(( t - lastT )); [ "$secs" -gt 0 ] || secs=1
          txbps=$(( (tx - lastTx) * 8 / secs / 1000000 ))
          rxbps=$(( (rx - lastRx) * 8 / secs / 1000000 ))
          speed=$(cat "$dev/speed" 2>/dev/null || echo '?')
          carrier=$(cat "$dev/carrier" 2>/dev/null || echo '?')

          # Wifi context: associated BSSID, or "down".
          wifi=down
          if [ -e /sys/class/net/wlp9s0/operstate ] &&
             [ "$(cat /sys/class/net/wlp9s0/operstate)" = "up" ]; then
            wifi=$(${pkgs.iw}/bin/iw dev wlp9s0 link 2>/dev/null \
                     | ${pkgs.gnugrep}/bin/grep -oE 'Connected to [0-9a-f:]+' \
                     | ${pkgs.gnused}/bin/sed 's/Connected to //') || wifi=up
            [ -n "$wifi" ] || wifi=up
          fi

          echo "FLAP $last->$now carrier=$carrier speed=''${speed}Mb/s tx=''${txbps}Mbit/s rx=''${rxbps}Mbit/s wifi=$wifi"
          last=$now
        fi

        lastTx=$tx; lastRx=$rx; lastT=$t
      done
    '';
  };
  environment.systemPackages = [ pkgs.ethtool ];
}
