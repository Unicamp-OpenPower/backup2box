#!/bin/bash

: '
Licensed under the Apache License, Version 2.0 (the “License”);
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an “AS IS” BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
'

########################## CHANGE HERE ##########################

BACKUP_DESTINATION='Backup'
DIRS_TO_BACK_UP=(/home/* /etc /var)
MAX_FILE_SIZE=5368709120

#################################################################

BOX_USERNAME=$ENV_BOX_USERNAME
BOX_PASSWORD=$ENV_BOX_PASSWORD

if [[ "$EUID" -ne 0 ]]; then
	echo
	echo "WARNING: Be careful when not running as root. You will likely not be able to backup most of your system's directories."
	echo
fi

hash cadaver >/dev/null 2>&1
if [[ $? -ne 0 ]]; then
	echo "This script requires Cadaver. Please install it before proceeding."
	exit
fi

TMP_DIR=$(mktemp -d)
cd $TMP_DIR
DATE=$(date +%F)
for DIR in "${DIRS_TO_BACK_UP[@]}"; do
	if [[ -d "$DIR" ]]; then
		DASH_DIR=${DIR////-}
		DASH_DIR=${DASH_DIR/ /-}
		tar --exclude $TMP_DIR -czpf $TMP_DIR/backup$DASH_DIR-$HOSTNAME-$DATE.tar.gz "$DIR"
		if [[ `stat -c%s $TMP_DIR/backup$DASH_DIR-$HOSTNAME-$DATE.tar.gz` -gt $MAX_FILE_SIZE ]]; then
			split -d -b $MAX_FILE_SIZE $TMP_DIR/backup$DASH_DIR-$HOSTNAME-$DATE.tar.gz $TMP_DIR/backup$DASH_DIR-$HOSTNAME-$DATE.tar.gz.part
			rm $TMP_DIR/backup$DASH_DIR-$HOSTNAME-$DATE.tar.gz
		fi
	fi
done

CADAVERRC=$(mktemp)
echo "open https://dav.box.com/dav" > $CADAVERRC
OIFS=$IFS;
IFS="/";
BACKUP_DESTINATION=($BACKUP_DESTINATION);
for DIR in "${BACKUP_DESTINATION[@]}"; do
	echo "mkcol $DIR" >> "$CADAVERRC"
	echo "cd $DIR" >> "$CADAVERRC"
done
IFS=$OIFS;
echo "mkcol $HOSTNAME" >> $CADAVERRC
echo "cd $HOSTNAME" >> $CADAVERRC
echo "mkcol $DATE" >> $CADAVERRC
echo "cd $DATE" >> $CADAVERRC
echo "mput *" >> $CADAVERRC
echo "quit" >> $CADAVERRC

echo "machine dav.box.com" > $HOME/.netrc
echo "login $BOX_USERNAME" >> $HOME/.netrc
echo "password $BOX_PASSWORD" >> $HOME/.netrc


cadaver --rcfile=$CADAVERRC

# If your cadaver version does not recognize wildcard certificates, comment out
# the above line, and uncomment the below one. You will also need to install
# expect.

#expect -c "set timeout -1; spawn cadaver --rcfile=$CADAVERRC; expect \"Do you wish to accept the certificate? (y/n)\"; send \"y\r\"; expect eof"

rm -rf $TMP_DIR $CADAVERRC $HOME/.netrc
