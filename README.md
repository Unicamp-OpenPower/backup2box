# Back up Linux to Box

This script backs up directories of your choice to a [Box](https://www.box.com/) account. It does not perform any kind of deduplication of data already backed up, so it suits better accounts with unlimited storage and environments with a good internet connection. On the other hand, it will not require another service subscription; and uses *tar*, therefore not depending on any proprietary software, which could be discontinued, to recover your files.

# Setting It Up

## 1. Install the *cadaver* WebDAV client.

Ubuntu/Debian: `sudo apt-get install cadaver`

Fedora/CentOS: `sudo yum install cadaver`

## 2. Set your Box username and password in environment variables

`export ENV_BOX_USERNAME='user@example.com'`

`export ENV_BOX_PASSWORD='passw0rd'`

For convenience, add these lines to your `~/.bashrc`

## 3. Change the variables at the beginning of the backup.sh file.

`BACKUP_DESTINATION`: Path to the Box folder where the backups will be placed, not beginning or ending with a slash. Use `\⋅` (backslash + space) instead of space when necessary. The files will not be placed directly on the folder. A folder will be created matching the hostname, and inside of it, a folder for each day.

`DIRS_TO_BACK_UP`: List of local directories to back up. Should not end with a slash. If the path contains a whitespace, white within quotes (single or double). A wildcard asterisk may be used and will be expanded by bash, but note that files not contained in a directory will not be backed up (e.g. if choosing to back up `/etc/*`, only directories inside `/etc` will be backed up, not individual files). Backing up `/home` will create a single tar, while `/home/*` will create a tar for each directory inside `/home`

`MAX_FILE_SIZE`: Box limits the size of a single file according to your plan. The script is set to a 5GB limit. If yours is different, change it appropriately:

250MB - 262144000

2GB - 2147483648

Files larger than 5GB will be split. To merge them, simply use `cat`. For example: `cat backup-home-hostname-2018-01-01.tar.gz.part* > backup-home-hostname-2018-01-01.tar.gz`

## 4. Maybe install *expect*

Some versions of *cadaver* do not recognize a wildcard certificate, which is used by Box, and you will see a message like this:

> WARNING: Untrusted server certificate presented for '\*.box.com':
>
> Certificate was issued to hostname '\*.box.com' rather than 'dav.box.com'
>
> This connection could have been intercepted.
>
> Issued to: Box, Inc., Redwood City, California, US
>
> Issued by: GeoTrust Inc., US

This is known to happen when running *cadaver* on Ubuntu 14.04. To check whether or not this bug is present in your version, simply run `cadaver https://dav.box.com/dav`. If the warning is not shown, no changes are required. If it is, simply install *expect*, comment out the line 75 and uncomment the line 81. This way, the certificate will be automatically accepted.

To install *expect*:

Ubuntu/Debian: `sudo apt-get install expect`

Fedora/CentOS: `sudo yum install expect`

## 5. Run it

It is highly advisable to run it as root, since a regular user won't have permissions to read all the files in the system, possibly resulting in incomplete backups.

    sudo ./backup.sh

## 6. Schedule it

To back up your system regularly and automatically, you can schedule this script on crontab.

When scheduling, use the root crontab (`sudo crontab -e`) and set the username and passsword for Box before running. For example, to run it every day at midnight:

`0 0 * * * export ENV_BOX_USERNAME='user@example.com' ; export ENV_BOX_PASSWORD='passw0rd' ; /path/to/script/backup2box/backup.sh`

