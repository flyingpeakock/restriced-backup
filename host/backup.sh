#!/bin/zsh

mydir=${0:a:h}
btrfs subvolume show / > /dev/null 2>&1 && $mydir/backup-btrfs.sh || $mydir/backup-rsync.sh

