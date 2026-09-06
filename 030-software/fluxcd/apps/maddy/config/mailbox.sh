#!/usr/bin/env sh

MADDY_CONFIG_PATH=${MADDY_CONFIG_PATH:-/config/maddy.conf}

set -e

account_name=$1
original_rcpt_to=$2
username=$(echo "$account_name" | cut -d "@" -f1)
mbox=$(echo "$original_rcpt_to" | cut -d "@" -f1 | cut -d "+" -f2 | cut -d "." -f2 | awk '{print tolower($0)}')

# Skip mailbox creation if mailbox == account name
if [ "$username" == "$mbox" ]; then
  exit 0
fi

needle=$(maddy --config $MADDY_CONFIG_PATH imap-mboxes list $account_name | grep $mbox | awk '{print $1}')

# Put messages directly inside their mailbox
if [ "$needle" != "$mbox" ]; then
# Create mailbox if does not exists
  maddy --config $MADDY_CONFIG_PATH imap-mboxes create $account_name $mbox && \
  echo "$mbox" && \
  echo "\Recent"
else
  echo "$mbox" && \
  echo "\Recent"
fi

# # Create mailbox if does not exists
# if [ "$needle" != "$mbox" ]; then
#   maddy --config $MADDY_CONFIG_PATH imap-mboxes create $account_name $mbox
# fi
