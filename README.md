offline-zfs-backup
==================

This script works in tandem with a script like https://github.com/adaugherity/zfs-backup
which performs automatic incremental snapshot send-receive to a server which is not always running.

This script uses WOL to wake up the machine, do some preliminary checks, invoke the backup script, and poweroff the machine once again.

Setup
=====

1. Setup a script to perform incremental backup such as [zfs-backup](https://github.com/adaugherity/zfs-backup).
2. Setup your receiving server to wake via WOL.   
This includes BIOS setup, and running: ```ethtool -s eth0 wol g``` after startup (```rc.local``` is a good place).
3. Add the MAC address of the receiver, its IP address (if static), the login information, and the path to the script to run, into this script.
4. Optionally add a sendmail command or similar to warn if the pool is degraded.
5. Optionally setup ```cron``` to run this script on a schedule, such as:
```0 8 * * *	root	/tank/storage/Scripts/run-zfs-backup.sh >> /var/log/run-zfs-backup.log```
