# 11 — Subscription

The subscription pays for the hosted VPN service or for unlocking VPN seats, not for the software: ThinForge itself is free software under the GPL-3.0-or-later.

ThinForge manages clients **without a subscription, without limit** and with its full feature set — deployments, delta updates and snapshot management included. The only thing that requires a subscription is **activating VPN clients**: a signed subscription file defines how many VPN clients may be activated at the same time (VPN seats). Without a valid subscription no VPN client can be activated.

## Terms

| Term | Meaning |
|---|---|
| **VPN seat** | A VPN client that is assigned to a device and activated. Deactivating it frees the seat again. |
| **No subscription** | No subscription file installed. Client management unlimited, 0 VPN seats. |
| **Active** | Valid subscription file, expiry date today or in the future. Seats = `max_vpn_clients` from the file. |
| **Expired** | Expiry date has passed. There is no grace period: new VPN clients can no longer be activated, existing ones keep running. |

## View the status

Menu → **Settings** → tab **Subscription** (admins only, reading included).

The status card shows:

- **Subscription data** (subscriber, **Subscription number**, **Expires**).
- **Used VPN seats** against the limit ("X of Y VPN clients in use") as a progress bar while the subscription is valid (an expired subscription frees no seats any more; the bar is then missing) — color-coded:
  - blue below 90 %,
  - orange from 90 %,
  - red as soon as the limit is reached.
- **Banner** if the subscription has expired.

Without a subscription the card only shows the notice that client management is unlimited and a subscription is only needed for VPN clients — that is not an error but the default state of many installations.

## Upload a subscription file

The vendor gives you a `.7z` archive that contains `license.json` and `license.json.minisig`. Archive password and signature check are handled internally; you just keep the file at hand.

1. Card **Upload subscription** → field **Subscription file (*.7z)** → pick the file.
2. **Upload and activate**.
3. The server checks signature and content. Possible error messages:
   - "Not a valid subscription file" (`bundle_not_7z`) — the file is not a 7z archive (e.g. wrong format).
   - "Subscription file does not match this server build" (`bundle_wrong_password`) — the 7z password does not match the backend build (probably a file for a different version).
   - "Subscription file incomplete" (`bundle_missing_files`) — the archive does not contain both required files.
   - "Subscription file signature invalid" (`signature_invalid`) — the minisign signature is invalid; often a copying problem or a tampered file.
   - "Subscription file version no longer supported" (`license_version_unsupported`) — old file without VPN seats; have a new (v2) subscription file issued.
   - "Subscription file content corrupted" (`payload_malformed`) — the JSON schema does not match.
   - "Subscription file cannot be processed" (`license_invalid`) — any other failure, for example a file larger than 1 MiB (real subscription files are a few kilobytes).
4. On success the card updates right away; the new limit applies immediately.

## Remove the subscription

**Remove subscription** (only visible while a subscription is installed; no confirmation prompt). The file is deleted from the server; the installation then has 0 VPN seats. VPN clients that are already connected are not disconnected — the cap only applies at the next activation.

## Behavior at the limit

- **Activating a VPN client** without a valid subscription or without a free seat → the server refuses; if the quota is full, the message names the seats in use and the maximum. **Activate entire group** checks device by device and stops at the first device without a free seat; the devices activated up to then stay activated, but the message does not say how many. [13 — VPN](13-vpn.md) describes the activation itself.
- **Creating clients, CSV import, deployments, updates** → independent of the subscription.
- **Existing VPN clients** are never deactivated — not even after the subscription has expired or been removed.

## Renewing the subscription

Request a new subscription file from the vendor in good time before the expiry date. Simply upload the new file over the old one — the server replaces the existing file atomically, without a restart.

## Next steps

- Admin tools around users, TLS and signing: [09 — Settings](09-settings.md).
- Backup: see [09 — Settings → Backup & Restore](09-settings.md#backup--restore) — the system backup also contains the subscription file.
