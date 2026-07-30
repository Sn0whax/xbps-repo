cachyos-settings-runit installed.

sysctl / udev / modprobe / limits are applied automatically on next boot
(or: sudo xbps-reconfigure -f cachyos-settings-runit ; sudo udevadm control --reload).

Enable the runit services:
  ln -s /etc/sv/cachyos-boot-tune /var/service/     # THP tuning at boot
  ln -s /etc/sv/zramen            /var/service/     # compressed swap
  ln -s /etc/sv/ananicy-cpp       /var/service/     # per-app nice/io tuning

Pull the CachyOS ananicy rule set (needs git):
  sudo cachyos-fetch-ananicy-rules
  sudo sv restart ananicy-cpp

Verify:
  sysctl vm.swappiness vm.max_map_count net.ipv4.tcp_keepalive_time
  cat /sys/kernel/mm/transparent_hugepage/enabled
  cat /sys/block/nvme0n1/queue/scheduler
