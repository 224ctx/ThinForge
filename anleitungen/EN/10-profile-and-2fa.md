# 10 — Profile & Two-Factor Authentication

Every signed-in user reaches their **profile** through the user menu at the top right. There you can change your own password, see your role and — if not active yet — set up **two-factor authentication (TOTP)**.

Admins can additionally reset passwords and 2FA seeds for other people in [09 — Settings → Users](09-settings.md#tab-users--roles); for other admin accounts this only works via **Edit** with a new password.

## Open the profile

- Click the account icon at the top right (the menu shows username and role) → **Profile**
- Direct URL: `/profile`

The view consists of three cards: **Account Information** (username, email, role), **Change Password**, **Two-Factor Authentication (2FA)**.

## Change your own password

Card **Change Password**:

1. Enter the current password.
2. Enter the new password (at least 8 characters).
3. Repeat it in the confirmation field — it must match exactly.
4. Click **Change Password**.

On success the fields are cleared and the message "Password changed successfully" appears as a snackbar. For security reasons every **other** session of your account ends — in other browsers or on other computers you have to sign in again with the new password. The session in which you changed the password stays signed in.

If the change fails, the card names the reason — for example "Current password is incorrect.", a new password that is too short, a server that cannot be reached or too many requests; the new value is not applied then. (Until the update of 2026-09-30 the card said "current password is incorrect" for every failure.)

## Enable two-factor authentication

TOTP adds a time-based 6-digit code from an authenticator app (e.g. Aegis, FreeOTP, Google Authenticator) to the account. The server generates a secret for it and shows it as a QR code.

Steps:

1. Card **Two-Factor Authentication (2FA)** → **Enable 2FA**; the card **Set Up 2FA** appears below.
2. The server delivers QR code + secret (manual key, Base32). Scan the QR code with the authenticator app **or** type in the alphanumeric secret by hand (e.g. if the app cannot scan QR codes). Until the update of 2026-10-01 only a broken image appeared instead of the QR code; manual entry was the only way then.
3. **Next** → type the 6-digit code from the app into the input field.
4. **Activate 2FA** confirms the code.

After successful activation the card shows the status **Enabled** (green chip), and the next login asks for the 6-digit code in addition to the password.

If activation fails, the card names the reason — a wrong code, an expired setup (then start again with **Enable 2FA**), a server that cannot be reached or too many requests. (Until the update of 2026-09-30 the card said "invalid code" for every failure.)

> **Tip:** Store the secret string or a screenshot of the QR code **once** in a safe place (password manager, encrypted container), so that setting it up on a new device remains possible if the phone is lost. The app does not show the secret again later.

## Disable 2FA

- Card **Two-Factor Authentication (2FA)** → **Disable 2FA**.
- A dialog asks for the current password **and** a valid current TOTP code.
- After confirmation the second factor is removed.
- If it fails, the dialog names the reason: wrong password, wrong code, or a server or network error; the second factor then stays active.

If the code is no longer available (e.g. lost smartphone), an admin has to reset the user's TOTP seed in the settings `/settings?tab=users` — see [09 — Settings → Reset TOTP](09-settings.md#reset-totp). For an admin account the server refuses that; there another admin sets a new password via **Edit**, which turns off 2FA as well.

## Forgot password

The link **Forgot password?** appears on the sign-in page as soon as the server can send email — that is, when the **email channel** under Settings → Alerts is switched on, names an SMTP host and — if an SMTP username is set — has a password stored and either **Use TLS/STARTTLS** (or port 465) or **Allow sign-in without encryption** checked ([09 — Settings → Alerts](09-settings.md#tab-alerts)). If the username has no password (since the update of 2026-10-16) or neither encryption nor that permission is set (since the update of 2026-10-18), the sign-in page does not offer the link — no mail would go out through the channel. The alert messages go out through the same channel.

1. Click **Forgot password?** and enter the account's email address — exactly as it is stored in the account.
2. The page always answers the same way: "If an account with this email address exists, a link is on its way." It deliberately does not reveal whether the account exists.
3. The email goes to the address stored in the account. Its link is valid for **15 minutes** and works **once**; it leads to **Set new password** (at least 8 characters).

Good to know:

- At most **one email per account per minute** goes out. A second request within that minute sends nothing; the link already sent stays valid.
- Only the **newest** link counts: requesting a new one after more than a minute invalidates the older one.
- A **deactivated** account gets no link, and a link issued earlier cannot be redeemed after the account has been deactivated.
- As with a reset by an admin, the new password turns off an active 2FA and ends every existing session of the account.
- Every request for an existing account appears in the audit log as **Password reset by email requested** — with source IP and outcome, in the entry's raw data as `reason`: `sent`, `throttled`, `inactive` (account deactivated), `smtp_unavailable` (no mail delivery), `failed`. Requests for unknown addresses leave no trace.
- The link always points to the server's name from setup (step "Server Identity"): `https://hostname.domain`, without a domain `https://hostname`; if none is stored, to the server address from the configuration (`THINOS_SERVER_URL`, default `https://thinforge-server`). The name must resolve on the management network — it is the same name the TLS certificate carries. Since the update of 2026-10-03 the address the request came in on no longer matters.

Without email delivery the way via an admin remains — see [09 — Settings → Reset password](09-settings.md#reset-password). An active 2FA is turned off in the process, and every existing session of the account ends.

## Worth knowing

- **Role chip**: The colored chip in the first card shows Administrator (red), Operator (orange), Viewer (neutral). Roles are assigned by an admin; users cannot promote themselves.
- **Session duration**: access token 15 min, refresh token as long as the configured session duration without activity (default 7 days, [09 — Settings → General](09-settings.md#tab-general)). The UI refreshes transparently; once the refresh token has expired it redirects to `/login`.
- **Logout**: user menu → **Logout**. On the server the cookies are deleted and the access and refresh tokens are put on the Redis blacklist. If Redis is disturbed at that moment, an error message appears: the browser is signed out anyway, but the two tokens then remain valid until they expire (audit entry `logout` with `revoked: false`).

## Next steps

- Admin tasks around users: [09 — Settings](09-settings.md#tab-users--roles).
