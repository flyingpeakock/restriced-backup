#!/bin/zsh

remote=heimdall.asgard
user=remote-backup
date=$(date --iso-8601)
snapshots=/.snapshots
backup_drive=/dev/sda

# Create snapshots of root and home subvolumes
create_snapshot() {
    # Only keeping one snapshot per day
    if [ ! -d $3/$1 ]; then
        btrfs subvolume snapshot -r $2 $3/$1
    fi
}

# Remove all but latest 21 snapshots
remove_snapshot() {
    OLDFILES=$(ls -r $1 | tail -n +22)
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

# Crash with message
fail() {
    # TODO: make sure drive is unmounted and encrypted
    1>&2 echo $1
    exit 1
}

create_snapshot $date / $snapshots/root
create_snapshot $date /home $snapshots/home

remove_snapshot $snapshots/root
remove_snapshot $snapshots/home

# Checking if remote is online
ping -c 1 $remote > /dev/null 2>&1 || exit 0

# Decrypting the drive before
# cat /etc/backup.key | ssh $user@$remote sudo decrypt.sh
cat /etc/backup.key | ssh $user@$remote open $HOST || fail "Unable to decrypt backup drive"

send_snapshot root 
send_snapshot home 

# Encrypt drive when done
ssh $user@$remote close $HOST
