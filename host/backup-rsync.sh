#!/bin/zsh

keyfile="$1"
remote="$2"
user="$3"

die() {
    echo "$*"
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

if [ "$error" != "" ]; then
    die $error
fi

# Decrypting the drive before
cat /etc/backup.key | ssh $user@$remote open $HOST

rsync -aAXHSp --delete -e ssh --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found","/home/*/.thumbnails/*","/home/*/Downloads/*","/home/*/.cache/mozilla/*","/home/*/.local/share/Trash/*","/home/*/Vbox","/home/*/Documents/archiso/build/*","/home/*/Documents/archiso/work"} / $user@$remote:/$HOST

ssh $user@$remote snapshot $HOST

# Encrypt drive when done
ssh $user@$remote close $HOST
