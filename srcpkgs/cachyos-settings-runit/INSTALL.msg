========================================================================
 cachyos-settings-runit  —  installed
========================================================================

CachyOS-style performance tuning (sysctl / udev / THP / limits / zram),
ported to runit. Everything below works on its own; ananicy-cpp is
OPTIONAL and installed separately (see the last section).

------------------------------------------------------------------------
 1. Apply the tuning
------------------------------------------------------------------------
sysctl, udev, modprobe and limits.d files take effect on next boot.
To apply now without rebooting:

  sudo xbps-reconfigure -f cachyos-settings-runit
  sudo sysctl --system
  sudo udevadm control --reload && sudo udevadm trigger

------------------------------------------------------------------------
 2. Enable the runit services you want
------------------------------------------------------------------------
THP boot tuning (shipped by THIS package):
  sudo ln -s /etc/sv/cachyos-boot-tune /var/service/

Compressed zram swap (needs the 'zramen' package, a hard dep):
  sudo ln -s /etc/sv/zramen /var/service/

------------------------------------------------------------------------
 3. Verify
------------------------------------------------------------------------
  sysctl vm.swappiness vm.max_map_count net.ipv4.tcp_keepalive_time
  cat /sys/kernel/mm/transparent_hugepage/enabled
  cat /sys/block/nvme0n1/queue/scheduler      # adjust device name
  ulimit -r                                    # rtprio for audio group
  zramctl

------------------------------------------------------------------------
 4. (OPTIONAL) ananicy-cpp — per-app nice/io auto-tuning
------------------------------------------------------------------------
NOT required and NOT a dependency. The tuning above is fully functional
without it. ananicy-cpp is not in Void's official repos, so build it
from a community template first, then wire it up:

  # a) build ananicy-cpp (from a Void box with void-packages):
  #    see github.com/prostitutionofthesoul/ananicy-cpp-void-template

  # b) fetch the CachyOS rule set into /etc/ananicy.d/ :
  sudo cachyos-fetch-ananicy-rules

  # c) enable the daemon (service action is 'start', not 'run'):
  sudo ln -s /etc/sv/ananicy-cpp /var/service/
  sudo sv restart ananicy-cpp

========================================================================
