---
title: Privacy Policy
permalink: /privacy.html
---

# Kovira Privacy Policy

**Effective date:** 2026-05-05
**Last updated:** 2026-05-05

## The short version

Kovira does not collect, transmit, or share any personal data. Your ledger
lives on your phone. The only network feature is the optional Google
Drive backup that you explicitly enable, and that backup goes to **your**
Google Drive in **your** Google account — not to any server operated by
me or anyone else.

There are no analytics, no crash reporters that phone home, no ad SDKs,
and no third-party trackers of any kind in this app.

If you uninstall Kovira, all on-device data is removed by Android. There
is no cloud account to delete because there is no cloud account.

## Who this policy applies to

This policy covers the **Kovira** Android application (package name
`com.glosper.kovira`) distributed through Google Play and as sideload
APKs from this repository. It is published by **Tousif Shahriar / Glosper
Studio** ("we", "us", "the developer") as the sole maintainer.

Contact for privacy questions: **glosper.dev@gmail.com**.

## Data we collect

**None.** The app does not transmit any personal data, identifiers,
device information, advertising IDs, location, contacts, photos, or any
other information about you to the developer or to any third party.

We do not have a server. We have no way to receive your data even if we
wanted to.

## Data stored on your device

The app stores the following on your phone, in a local SQLite database
inside the app's private storage area, accessible only to Kovira:

- Income source names, balances, and icons that you create.
- Categories that you create.
- Ledger entries (income, expenses, transfers, dues) that you record.
- Bill, recurring-income, and transfer templates that you create.
- Goal targets and contributions that you record.
- Monthly budget limits that you set.
- Your chosen theme (light, dark, system) and number-format preferences.
- A flag indicating whether you've completed the welcome flow.
- Per-feature flags marking which assisted-tutorial tips you've already
  seen.
- If you enable encrypted backups, the backup passphrase you set,
  stored in Android `SharedPreferences` so the same device can produce
  silent backups without re-prompting. This passphrase never leaves
  your device.

This data is not transmitted anywhere. Other apps cannot read it. If
you uninstall Kovira, Android removes this data along with the app.

## Optional Google Drive backup

Kovira offers an optional backup feature that uploads an encrypted copy
of your ledger to **your own** Google Drive, into the application data
folder Google Drive provides (`drive.file` scope — Kovira can only see
files it created itself; it cannot read your other Drive files).

When you choose to enable this feature:

- You are prompted to sign in with a Google account of your choosing.
  This sign-in is handled by Google's official Google Sign-In SDK; the
  authentication flow is between you and Google.
- The backup file is encrypted **on your device** with **your backup
  passphrase** before upload, using **AES-256-CBC** with a key derived
  via **PBKDF2-HMAC-SHA256** (100,000 iterations, per-backup random
  salt and IV). Without your passphrase, the encrypted file is
  unreadable, including by Google.
- The encrypted file is uploaded directly from your device to your
  Google Drive over an HTTPS connection. It is not routed through any
  server operated by us.
- We do not receive a copy of the file. We do not receive your Google
  account email or any other identifier from this flow.

If you never enable this feature, the app makes no network connections
related to backup.

You can revoke Kovira's access to your Google Drive at any time from
your Google account at <https://myaccount.google.com/permissions>.

## Permissions Kovira requests

Each Android permission is requested only for the specific user-facing
feature listed below. Kovira does not use any permission for any other
purpose.

| Permission | Used for | When requested |
|---|---|---|
| `INTERNET` | Uploading or downloading the encrypted backup to/from your Google Drive | At install time (declared in manifest); only used after you tap the Drive backup option |
| `POST_NOTIFICATIONS` | Showing reminders for recurring income, recurring transfers, and bills you set up | First time you create or schedule a reminder |
| `SCHEDULE_EXACT_ALARM` | Firing those reminders on the exact day you chose | When the first reminder is scheduled; falls back to inexact alarms if not granted |

You can deny or revoke any of these from Android **Settings → Apps →
Kovira → Permissions** at any time. The app continues to function for
features that don't require the revoked permission (e.g., revoking
notifications disables reminders only).

## Encryption

Backups created by Kovira are encrypted on-device before any upload or
file write:

- **Cipher:** AES-256-CBC
- **Key derivation:** PBKDF2-HMAC-SHA256, 100,000 iterations
- **Salt:** 16 random bytes per backup, generated with a CSPRNG
- **IV:** 16 random bytes per backup, generated with a CSPRNG
- **Authentication:** envelope JSON includes the format version and
  parameters; decryption fails fast on tamper

The same passphrase reproduces the AES key on any device, which is what
makes backups portable across phones and reinstalls. **If you lose the
passphrase, the backup cannot be recovered.** This is a property of
strong encryption — there is no master key, no recovery flow, and no
back door.

## Children's privacy

Kovira is not directed at children under 13 (or the equivalent minimum
age in your jurisdiction). We do not knowingly collect personal
information from children. Since we collect no personal information from
anyone, this is structural, not a policy promise.

## Account and data deletion

There is no account to delete because Kovira does not have user
accounts. To delete all your Kovira data, **uninstall the app** from
your Android device. Android removes the app's local storage as part of
the uninstall.

If you have used the optional Google Drive backup, you can delete that
file from your Google Drive at <https://drive.google.com> — search for
`kovira_backup.enc`. Revoking Kovira's access at
<https://myaccount.google.com/permissions> additionally prevents any
future Drive activity by the app.

## Third parties

The only third party Kovira interacts with is **Google**, and only when
you opt into the Drive backup feature. Specifically:

- **Google Sign-In** (Google LLC) — for the OAuth authentication flow
  to obtain Drive access. See Google's privacy policy at
  <https://policies.google.com/privacy>.
- **Google Drive API** (Google LLC) — for uploading and downloading the
  encrypted backup file to/from your own Drive. Same policy applies.

Kovira does not use any other third-party SDKs, APIs, advertising
networks, analytics services, or attribution services.

## International data transfers

Because Kovira does not transmit personal data, there are no
international data transfers performed by the app. If you use the
optional Drive backup, transfer occurs between your device and Google's
servers under Google's own data-handling terms.

## Changes to this policy

If this policy changes materially in a future version of Kovira, the
**Effective date** at the top of this document will be updated, the
update will be summarised in the GitHub repository's release notes, and
where appropriate the change will be reflected in the Google Play
listing's "What's new" section. Continued use of the app after such an
update constitutes acceptance of the revised policy.

## Contact

For privacy questions or concerns about this policy:

**Email:** glosper.dev@gmail.com
**Repository:** <https://github.com/Thypsos/Kovira>

If your concern is urgent or relates to a security vulnerability,
please include "SECURITY" in the email subject line.
