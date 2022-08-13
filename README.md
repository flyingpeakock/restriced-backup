# Restricted Backup
This is a modified version of [rrsync](https://github.com/WayneD/rsync/blob/master/support/rrsync). I have enabled the ability to decrypt and mount a specific luks encrypted drive.I have also allowed receiving btrfs snapshots as well as the creation of new btrfs snapshots

## Usage
All commands are run the from the host machine and ssh is used to interact with the script
- Decrypt and mount `cat backup.key | ssh $user@$ip open $HOST`
- Unmount and encrypt `ssh $user@$ip close $HOST`
- rsync `rsync ... ssh  $user@$ip`
- Create a snapshot `ssh $user@$ip snapshot $HOST`
- Recieve a btrfs snapshot `btrfs send snapshot | ssh $user@$ip btrfs $HOST receive $subvolume`
- Get parent snapshot for incremental send `ssh $user@$ip btrfs $HOST parent`
- Update the script `ssh $user@$ip update [$gitdir]`

## Limitations
- The backup drive must be btrfs formatted
- The only subvolumes that get send with btrfs are '/' and '/home'

## Setup

### On backup drive
The backup drive must be formated with btrfs filesystem. The layout of the subvolumes is unimportant however once mounted everything should have the structure `/mnt/backup/$HOSTNAME/`. You must then create a directory/subvolume for every host that will backup to this drive in the root of the drive as well as a snapshots directory/subvolume to store snapshots created from rsync backups.

### On server
The server is the machine that will store the backups on the external drive.

### On host
