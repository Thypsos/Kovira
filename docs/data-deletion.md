---
title: Data Deletion
permalink: /data-deletion.html
---

# Kovira Data Deletion

Kovira is an offline-first app. There is no Kovira-side account or
server, so there is no developer-held data to request deletion of.

## How to delete all your Kovira data

### 1. Delete on-device data

Uninstall Kovira from your Android device:

- Settings → Apps → Kovira → Uninstall

Android removes all of Kovira's local data (transactions, settings,
templates, goals, the encryption passphrase) as part of the uninstall.

### 2. Delete your Google Drive backup (if used)

If you enabled Google Drive backup, an encrypted file
(`kovira_backup.enc`) is stored in your own Google Drive in the
application data folder.

To delete it:

- Open <https://drive.google.com>
- Search for: `kovira_backup.enc`
- Delete the file

Then empty Drive's Trash to fully remove it.

### 3. Revoke Drive access

To prevent any future Drive activity by Kovira, revoke its access:

- Open <https://myaccount.google.com/permissions>
- Find Kovira in the list
- Click Remove access

## Need help?

Email **glosper.dev@gmail.com** with the subject line "Data Deletion
Request" and describe what you need help with.

Because Kovira does not collect or store any data on developer-operated
servers, there is no data on our side to delete. We will respond to
your email to help you with the steps above if needed.
