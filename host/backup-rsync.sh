#!/bin/zsh

keyfile="$1"
remote="$2"
user="$3"

# Decrypting the drive before
cat /etc/backup.key | ssh $user@$remote open $HOST

rsync -aAXHSp --delete -e ssh --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found","/home/*/.thumbnails/*","/home/*/Downloads/*","/home/*/.cache/mozilla/*","/home/*/.local/share/Trash/*","/home/*/Vbox","/home/*/Documents/archiso/build/*","/home/*/Documents/archiso/work"} / $user@$remote:/$HOST

ssh $user@$remote snapshot $HOST

# Encrypt drive when done
ssh $user@$remote close $HOST
