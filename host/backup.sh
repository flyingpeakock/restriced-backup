#!/bin/zsh

while getopts ':k:r:u:s:n:' OPTION; do
    case "$OPTION" in
        k)
            keyfile=$OPTARG
            ;;
        r)
            remote="$OPTARG"
            ;;
        u)
            user="$OPTARG"
            ;;
        s)
            snapshotdir="$OPTARG"
            ;;
        n)
            snapshotlim="$OPTARG"
        ?)
            echo "Usage: $(basename $0) [-k keyfile] [-r remote] [-u user] [-s snapshot directory] [-n number of snapshots to keep]"
            echo "-s and -n only necessary if local machine uses btrfs snapshots for backups"
            exit 0
            ;;
    esac
done

mydir=${0:a:h}
btrfs subvolume show / > /dev/null 2>&1 && $mydir/backup-btrfs.sh "$keyfile" "$remote" "$user" "$snapshotdir" "$snapshotlim" || $mydir/backup-rsync.sh "$keyfile" "$remote" "$user"

