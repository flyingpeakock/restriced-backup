# Restricted Backup
This is a modified version of [rrsync](https://github.com/WayneD/rsync/blob/master/support/rrsync). I have enabled the ability to decrypt and mount a specific luks encrypted drive.I have also allowed receiving btrfs snapshots as well as the creation of new btrfs snapshots

## Usage
All commands are run the from the host machine and ssh is used to interact with the script
- Decrypt and mount `cat backup.key | ssh $user@$ip open $HOST`
- Unmount and encrypt `ssh $user@$ip close $HOST`
- rsync `rsync ... ssh  $user@$ip` use regular rsync command
- Create a snapshot `ssh $user@$ip snapshot $HOST`
- Recieve a btrfs snapshot `btrfs send snapshot | ssh $user@$ip btrfs $HOST receive $subvolume`
- Get parent snapshot for sending incremental snapshot `ssh $user@$ip btrfs receive $HOST parent`
- Update the script `ssh $user@$ip update [$gitdir]`

## Limitations
- The backup drive must be btrfs formatted
- The only subvolumes that get sent with btrfs are '/' and '/home'

## Setup

### On backup drive
The backup drive must be formated with btrfs filesystem. The layout of the subvolumes is unimportant however once mounted all the hostnames of the devices you wish to backup should be present on the root of the backup device. You must therefore create a subvolume for every host that will backup to this drive in the root of the drive as well as a snapshots subvolume to store snapshots created from rsync backups. The snapshots directory can be omitted if only btrfs snapshots are sent and rsync is never used.

The directory structure will be different for devices backed up with rsync or with btrfs. Both can be used in conjunction.

#### btrfs
```
backup drive root
                  \ $hostname
                             \ root
                                    \ # contains root subvolume
                             \ home
                                   \ # contains home subvolume
                          
```

#### rsync
```
backup drive root
                 \ $hostname
                            \ # root of backup containing everything from rsync
                \ snapshots
                            \ $hostname
                                       \ root
                                             \ # contains root subvolume
                                       \ home
                                             \ # contains home subvolume
```

Btrfs subvolumes and their parent directories must be created, the rest are created automatically. It is up to you to decide what should be a directory and what should be a subvolume, snapshots are by definition subvolumes.

### On server
The server is the machine that will store the backups on the external drive.

restricted-backup.py is the script that does most of the main work however there is some setup required.

- Create a user with a home directory optionally in /var
- Give the user permission to run `restricted-backup.py` as sudo passwordless and enable editing the environment in sudo. Add to sudoers file: `username ALL=(root) NOPASSWD:SETENV: /path/to/restricted-backup.py`
- Configure sshd for the user to force a command. Add the following to the sshd_config file
```
Match User Username
    ForceCommand sudo -E /var/remote-backup/restricted-backup.py -wo -no-lock /path/to/mounted/backup
    PasswordAuthentication no

```
- Add the ssh-keys of the machines that you want to backup to $HOME/.ssh/authorized_keys

### On host
Setup on the host is optional. It is possible to run manual backups by running commands directly to the server using ssh.

- Create a symlink of backup.service and backup.timer to /etc/systemd/system
- Create a symlink of all the .sh files in host to /usr/bin
- Enable backup.timer
