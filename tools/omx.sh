#!/bin/bash
# omx.sh '<remote command>' : run a read-only command on omarchy, retry when the Wi-Fi link drops
for i in 1 2 3 4 5 6 7 8 9 10; do
  OUT=$(rtk proxy ssh -o ConnectTimeout=8 -o ServerAliveInterval=5 -o ServerAliveCountMax=3 omarchy "$1" 2>&1); RC=$?
  if [ $RC -ne 255 ]; then printf '%s\n' "$OUT"; exit $RC; fi
  sleep 6
done
echo "omx: omarchy not reachable after 10 tries"; exit 255
