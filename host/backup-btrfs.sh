#!/bin/zsh

keyfile="$1"
remote="$2"
user="$3"
snapshots="$4"
snapshotlim=$(expr "$5"+1)
date=$(date --iso-8601)

die() {
    >&2 echo "$*"
    exit 1
}

append_new_line() {
    if [ "$1" = "" ]; then
        echo $2
    else
        echo $1
        echo $2
    fi
}

error=""

if [ "$keyfile" = "" ]; then
    error=$(append_new_line "$error" "No keyfile provided")
fi
if [ "$remote" = "" ]; then
    error=$(append_new_line "$error" "No ssh target provided")
fi
if [ "$user" = "" ]; then
    error=$(append_new_line "$error" "No ssh user provided")
fi
if [ "$snapshots" = "" ]; then
    error=$(append_new_line "$error" "No local snapshots directory provided")
fi
if [ "$snapshotlim" = "" ]; then
    error=$(append_new_line "$error" "No limits on the amount of snapshots to keep")
fi

if [ "$error" != "" ]; then
    die $error
fi

# Create snapshots of root and home subvolumes
create_snapshot() {
    # Only keeping one snapshot per day
    if [ ! -d $3/$1 ]; then
        btrfs subvolume snapshot -r $2 $3/$1
    fi
}

# Remove all but latest 21 snapshots
remove_snapshot() {
    OLDFILES=$(ls -r $1 | tail -n "$snapshotlim")
    for file in $OLDFILES; do
        btrfs subvolume delete $1/$file
    done
}

# Send snapshot to remote
send_snapshot() {
    # parent=$(ssh $user@$remote sudo ls $2/$HOST/$1 | tail -n 1)
    parent=$(ssh $user@$remote btrfs $HOST parent)
    if [ -z $parent ] || [ ! -d $snapshots/$1/$parent ]; then
        # Parent does not exist, do not send incremental snapshot
        btrfs send $snapshots/$1/$date | ssh $user@$remote btrfs $HOST receive $1
    elif [ ! $parent = $date ]; then
        btrfs send -p $snapshots/$1/$parent $snapshots/$1/$date | ssh $user@$remote btrfs $HOST receive $1
    else
        printf "Snapshot $1/$date already exists on $remote\n"
    fi
}

create_snapshot $date / $snapshots/root
create_snapshot $date /home $snapshots/home

remove_snapshot $snapshots/root
remove_snapshot $snapshots/home

# Checking if remote is online
ping -c 1 $remote > /dev/null 2>&1 || exit 0

# Decrypting the drive before
# cat /etc/backup.key | ssh $user@$remote sudo decrypt.sh
cat $keyfile | ssh $user@$remote open $HOST

send_snapshot root 
send_snapshot home 

# Encrypt drive when done
ssh $user@$remote close $HOST
