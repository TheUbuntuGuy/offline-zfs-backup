#!/bin/bash
#
# ZFS Incremental Backup Init Script
# Version 0.0.1
# Copyright 2016 Mark Furneaux, Romaco Canada
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

WOL_MAC="aa:bb:cc:dd:ee"
WOL_IP="192.168.30.145"
REM_LOGIN="root@darwin"
ZFS_BACKUP_SCRIPT="/tank/storage/Scripts/zfs-backup.sh"
POOL_NAME="tank"

echo ""
echo "Romaco ZFS Offline Backup Script v0.0.1 Starting..."
echo "Start time: $(date)"
echo ""

# ZoL sometimes deadlocks if sending and scrubbing simultaneously
SCRUBBING=$(zpool status $POOL_NAME | grep "scrub in progress" | wc -l)

if [ $SCRUBBING -ne 0 ]; then
	echo "WARNING: Pool is scrubbing, aborting backup"
	exit 3
fi

# wake up backup server (3 times beacause I don't trust WOL)
echo "Waking up backup server..."
wakeonlan $WOL_MAC
wakeonlan $WOL_MAC
wakeonlan -i $WOL_IP $WOL_MAC
echo ""

# give the server some time to boot
echo "Waiting 2 minutes for server to boot..."
sleep 120

# check if it's done booting
echo "Checking if server is up..."
ssh -n $REM_LOGIN "uptime"
STAT=$?
echo ""

# if it's not ready, try again 3 times before giving up
RETRIES=3
until [ $STAT -eq 0 -o $RETRIES -eq 0 ]; do
	echo "Server not ready. Trying again in another 30 seconds..."
	let RETRIES-=1
	sleep 30
	ssh -n $REM_LOGIN "uptime"
	STAT=$?
	echo ""
done

if [ $RETRIES -eq 0 ]; then
	echo "ERROR: Backup server not online, giving up"
	exit 1
fi

echo "Server is up"

# check if the remote pool is healthy
echo "Checking health of remote pool..."
ssh -n $REM_LOGIN "zpool status -x btank"
STAT=$?
echo ""

# notify and abort if there is a pool problem
if [ $STAT -ne 0 ]; then
	echo "ERROR: Pool not healthy, aborting"
	echo "Problem with pool detected. Sending alert email..."
	# TODO call your own sendmail program/script here
	# shut down the backup server
	echo "Powering off backup server..."
	ssh -n $REM_LOGIN "poweroff"
	exit 2
fi

# run the backup and log the output
echo "All good, running backup..."
$ZFS_BACKUP_SCRIPT

if [ $? -eq 0 ]; then
	echo "Backup complete"
else
	echo "ERROR: Backup script returned non-zero exit code: $?"
	# TODO call your own sendmail program/script here
fi

echo "Preparing to poweroff server..."
sleep 30

# shut down the backup server
echo "Powering off backup server..."
ssh -n $REM_LOGIN "poweroff"
echo "End time: $(date)"
echo "Backup process complete. Exiting"
