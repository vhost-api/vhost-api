#!/bin/sh
PERCENT="$1"
USER="$2"
cat << EOF | /usr/lib/dovecot/dovecot-lda -d "$USER" -o "plugin/quota=maildir:User quota:noenforcing"
From: postmaster@example.com
Subject: Quota Warnung - Quota warning

Dear user,

Your mailbox is now $PERCENT% full.

Please note, that you won't be able to receive new emails when it's at 100%.

EOF
