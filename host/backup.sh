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
            ;;
        ?)
            echo "Usage: $(basename $0) -k KEYFILE -r REMOTE -u USER -s SNAPSHOTS -u NUMBER"
            echo
            echo "Run a backup to a machine configured for restricted-backup.py"
            echo
            echo "Options:"
            echo "  -k KEYFILE     Keyfile to unlock backup drive"
            echo "  -r REMOTE      IP or hostname to the server"
            echo "  -u USER        Username to connect to the server with"
            echo "  -s SNAPSHOTS   Location of local snapshots directory"
            echo "                 Only needed if you are running BTRFS locally"
            echo "  -u NUMBER      Number of snapshots to keep in local directory"
            echo "                 Only needed if you are running BTRFS locally"
            echo
            echo "For more information or submitting bugs:"
            echo "https://github.com/flyingpeakock/restricted-backup"
            exit 0
            ;;
    esac
done

mydir=${0:a:h}
btrfs subvolume show / > /dev/null 2>&1 && $mydir/backup-btrfs.sh "$keyfile" "$remote" "$user" "$snapshotdir" "$snapshotlim" || $mydir/backup-rsync.sh "$keyfile" "$remote" "$user"

