# ThinForge Changelog

## 2026-07-22

- **Cloning VM console: the mouse points and clicks where you see it** — In the Cloning VM's browser console the pointer was shown offset, so clicks did not land where the cursor appeared. The virtual machine now uses an absolute pointing device, so the visible cursor and the actual click point match exactly; the embedded console software (noVNC) was updated at the same time. *(Cloning VM)*

- **Updated container base (security and maintenance update)** — The base images of all services were bumped to current versions (including Alpine 3.24, Rust 1.97, Go 1.26), pulling in current security and bug fixes of the underlying system components with no impact on usage. *(all services)*

## 2026-07-21

- **Devices with automatic login no longer prompt for a password on wake** — On devices with automatic login, the screen still demanded a password after the screensaver or power-saving mode kicked in. First-run setup now disables the screen lock to match automatic login; the screensaver and power saving stay active, only the password prompt on wake is gone. *(Tools-ISO)*

## 2026-07-19

- **Changelog in English and in a compact format** — The changelog (click on the version number) now appears in the language of the interface; a full English version of the entire history is available. At the same time, the entries in both languages have been condensed to a compact short form; the detailed earlier versions remain available in the project history. *(backend, management interface)*

- **Service status: management interface no longer wrongly shown as "unhealthy"** — Since the switch to a hardened, minimal runtime image, the container health check reported the management interface as permanently "unhealthy", because the old check relied on a shell that this image deliberately doesn't include. The health check now runs through a tiny dedicated check component built into the image. Status is reported correctly again, without loosening the image's hardening. *(management interface, deploy repo)*

- **Deployments now only pull tested, versioned container images** — Deployment now uses a two-channel model: development builds live in the registry under a separate development channel, while production deployments pull fixed, year-month-day versioned builds that are only released after passing tests — the previous "latest build" reference now also always points to the most recently tested build. Nothing changes in the usual update workflow for existing installations, and rolling back to an earlier build is always possible via the version history, since all builds remain in the registry. A deployment can no longer accidentally pull an untested in-progress build. *(deploy repo)*

- **Recover locked-out clients with one click: "Reset to install token"** — If a client re-announced itself with the generic install token even though it was already registered with its own device token (for example after a reinstall outside a regular rollout), the server rejected its heartbeats for security reasons — the client then appeared permanently offline with no obvious cause. The client list now explicitly shows this state as **"Install token detected!"**, with a new action **Reset to install token**: after a confirmation prompt it discards the stale device registration, so the install token is accepted again and the client re-enrolls automatically on its next heartbeat — no reinstall and no manual database work required. *(server services, management interface)*

- **Shutdown no longer hangs on the power-off screen (outdated Agent)** — When an older Agent lacking the newer update command was paired with a newer service configuration, the update call issued during shutdown could accidentally start the Agent's background daemon, which the system then waited on in vain for up to ten minutes. The Agent now fails fast on unknown calls with an error message instead of falling back into the daemon, so shutdown completes without delay even when the Agent and service configuration versions are mismatched. *(Agent)*

## 2026-07-18

- **First-run setup no longer shows a misleading warning about the playbook service** — Completing first-run setup used to show a warning about the playbook service (Semaphore), even though that service currently isn't part of the installation at all. Setup now detects this and skips the step without warning, including when changing the admin password. **Security-relevant:** on every one of these failed attempts, a temporary file with plaintext credentials was previously left behind in the data directory — it is no longer written, and any leftover file from earlier runs is now removed automatically on the next setup run or admin password change. *(server services)*

- **Deleting a client now also revokes its VPN access** — If a client was deleted without first disabling its VPN, the associated VPN access remained in place while no longer being visible in management. Deleting a client now automatically removes its VPN access as well; if VPN management happens to be unreachable, deletion is no longer blocked by this and the event is logged instead. The license display also no longer shows a misleading usage line when there is no valid license. *(server services, management interface)*

## 2026-07-17

- **New license model: full feature set for all clients, license now covers only VPN clients** — The former distinction between light and full clients is gone for good: delta updates, snapshots, and rollback are now available to every client, and the number of managed clients is no longer capped. Licensing now applies to VPN client activation instead — without a valid license no new VPN clients can be activated, and with a license it sets the maximum number of simultaneously active VPN clients; VPN clients already active keep running unchanged if the license expires, and there is no longer a grace period. **Important:** license files in the old format are invalid as of this update and are rejected with a clear error message — a new license file is required for VPN client activation, and the worker additionally needs an updated compose configuration with the license directory mounted. *(server services, management interface, Agent)*

## 2026-07-13

- **ThinForge is now open source (GPL-3.0-or-later)** — All software originating from ThinForge — server services, management interface, Agent, and tooling — is now licensed under the GNU General Public License version 3 (or, at your option, any later version). The LICENSE file now contains the full GPLv3 text; NOTICE explains the licensing situation, including the third-party components Partclone and EZIO that remain under GPL v2. Operation, feature scope, and the existing maintenance and VPN offerings are unchanged — what's new is that the source code is openly viewable, auditable, and reusable under the terms of the GPL. *(server services, management interface, Agent, Tools-ISO)*

## 2026-06-23

- **Consistent gray tone for expanded detail panels** — Expanded detail panels and some overview surfaces had a near-white background in dark mode that stood out unpleasantly. They now use the same design-matching gray tone everywhere, in both dark and light mode. *(management interface)*

- **Session duration now actually takes effect** — The Session Duration setting previously had no effect: sessions expired after seven days of inactivity regardless of the configured value, and restarting the computer didn't end the logged-in session. The configured value now genuinely governs the session as a sliding window — after the chosen duration without activity, a fresh login is required, while active use keeps extending the window. The change applies to new logins; existing sessions pick it up on their next automatic token refresh. *(server services, management interface)*

## 2026-06-22

- **Devices marked "In stock" no longer skew alerts, reports, or license counts** — Devices with the "In stock" status are now handled consistently everywhere: they no longer trigger dashboard warnings, an already-raised alert is automatically closed once a device is put into stock, and they no longer count toward the fleet, utilization, lifecycle, VPN, and availability figures in reports. Inventory overviews now list them as a separate "In stock" block, and dashboard tiles show the active fleet excluding stock while reporting the stock count separately. License counting was already correct and has now been wired to the same central filter rule; the daily availability trend is recorded cleanly from this update onward, while already-recorded days remain unchanged. *(server services, management interface)*

## 2026-06-19

- **Dashboard: direct links to the matching reports** — Dashboard metric tiles now get a small chart icon in the top-right corner that opens the matching report directly (e.g. Storage → Storage report, Client Status → Availability, License → License, Active Alerts → Incidents, Rollouts → Deployments, Activity → Tasks, Compliance → Compliance). The existing links (e.g. to settings, groups, or rollouts) remain alongside it. *(management interface)*

## 2026-06-18

- **Reports: internal rework, improved responsiveness** — The reports section was restructured internally, with the same content, tabs, and charts as before. Noticeable improvements: the Refresh button now specifically reloads the currently open report, the Storage report no longer blocks the server while scanning disks, and an update runs cleanly through even when the database holds legacy duplicate values (no more restart loop). *(server services, management interface)*

- **Reports: fleet availability as a daily trend** — The reports section gets a new Availability tab with a time-range picker (7/30/90 days): current fleet (online/offline/error/total), online-rate history as a chart, breakdown by last-contact time, and a list of devices that repeatedly go offline. The daily trend builds up from the day of this update onward, since a daily snapshot is only captured from now on — there is no retroactive data; the "last contact" breakdown and the chronic-offline list, however, are available immediately. *(server services, management interface)*

- **Reports: storage/capacity overview + VPN/LAN connectivity coverage** — Two new overview tabs: Storage shows the occupied image volume, disk utilization as a percentage (highlighted from 85%), a forecast for when storage will run out, and the largest consumers by folder category; VPN shows a connectivity snapshot — active and cloud connections, errors, sealed TPM modules, and coverage per VPN group. Neither overview needs a time-range picker and both load on first open. *(server services, management interface)*

- **Reports: license utilization + lifecycle/expiry — visible to all roles** — Two new tabs: License shows a seat forecast with usage, utilization percentage, license status, and days remaining until expiry, plus the history of device enrollments; Lifecycle shows upcoming expirations of certificates and device warranties grouped by remaining time. The license report deliberately shows only aggregated figures with no sensitive details, so it's also visible to read-only accounts. *(server services, management interface)*

## 2026-06-17

- **Reports: three more time-based views** — Three additional tabs with a time-range picker (7/30/90 days, grouped by day or week): Updates shows delta-update success rate, signature errors, average retries, and download rate; Tasks shows throughput and error rate of device tasks by task type; DHCP shows network address allocation over time. Updates and Tasks can be exported as CSV. *(server services, management interface)*

- **Reports: three new time-based views** — Three further tabs with a time-range picker and CSV export: Incidents shows the trend of new incidents plus acknowledgment and resolution times per incident type; Activity shows SSH command activity over time with error rate and the most active devices; Deployments shows rollout success rate with completion history and duration figures. *(server services, management interface)*

- **Reports section back and expanded** — The **Reports** menu item (Compliance and Usage tabs) is reachable in navigation again. Compliance now also shows the distribution of Agent versions across the fleet, flagging outdated or never-checked-in devices, plus the health of scheduled background tasks. Usage now also shows per-group hardware utilization (CPU/RAM/disk as a traffic-light table flagging tight devices) and the distribution of devices across groups and installed image versions. All views can be printed. *(server services, management interface)*

## 2026-06-12

- **Device updates adapt to fluctuating bandwidth (home office/VPN/Wi-Fi)** — Download throttling for OS updates now measures line quality directly on the active update connection instead of against a pre-collected reference value. This fixes two problems: after a location change, an update could unnecessarily stay stuck at minimum speed even though the line was free, and on weak connections the update throttled too late, which could disrupt concurrent work sessions. Updates now make better use of available bandwidth and automatically back off as soon as the line is needed elsewhere — including handling Wi-Fi fluctuations without needless permanent throttling. *(Agent)*

- **More reliable device actions and rollouts** — Several rare bugs were fixed: device commands such as reboot could run twice under unlucky timing, a staged rollout could stall if the selected image wasn't finished building yet, and cancelling a rollout could wrongly mark a device that was just starting as cancelled. These flows are now hardened. *(server services)*

- **Device updates no longer lose the rollback image** — In rare cases, automatic cleanup of old system states could delete the currently running state, causing the next update to fail and requiring a full reinstall. The running state is now protected, and deleting a state also removes its associated home data, leaving no orphaned leftovers. *(Agent)*

- **Cancellation during the first update phase now displays correctly** — If an update clone was cancelled during its first phase, the interface incorrectly reported "cancelled" and got stuck. Progress now keeps advancing visibly until the running phase ends cleanly. *(server services)*

- **Certificate exchange never leaves a mismatched key pair behind** — When uploading a custom TLS certificate, a failure in the final step could leave the certificate and key inconsistent. If the exchange now fails, it automatically rolls back to the previous, working pair. *(server services)*

- **Network address is no longer accidentally removed** — When re-setting the server address, a similar existing address could be misidentified, potentially leaving the network interface without an address. Address detection is now exact. *(server services)*

- **Meaningful error messages in the management interface** — The interface used to show only a generic notice for many errors, even when, say, the server connection was down. Error messages now name the actual cause — server unreachable, timeout, missing permission, resource not found, and others — in the configured language, without repeating every second during a connectivity outage. Activating an in-stock device against the license limit is now also rejected with a clear message instead of silently failing. *(server services)*

- **Agent: update signature is now enforced before applying** — When applying an OS update on the client, signature verification was silently skipped in one edge case — a missing signature file — instead of rejecting the update. **Security-relevant:** the check now always applies, and update manifest data is additionally validated strictly against its expected shape, both of which prevent tampered update data from being applied. *(Agent)*

- **Agent update never leaves a device without an Agent** — During Agent updates, the running Agent binary used to be removed before the new one had fully transferred — a transfer failure could have left the device without an Agent at all. The new file is now fully transferred and verified before it replaces the old one; if anything fails, the working version is kept in place. *(server services)*

- **Image recovery on NVMe/eMMC devices** — On devices with NVMe or eMMC storage, creating the data partition used to fail because the device name was derived incorrectly. SATA, NVMe, and eMMC disks are now detected correctly. *(Tools-ISO)*

- **Image preparation aborts on a missing data partition** — If the data partition couldn't be mounted, installation used to continue anyway and write Agent data to the wrong location, which was then lost after the first update. Installation now aborts with a clear message instead of continuing in a broken state. *(Tools-ISO)*

- **Clone errors are now reliably reported** — When creating a clone, a failure on one partition could silently abort the operation without flagging it as an error — such failures are now detected and reported together with the affected partition. Restoring raw disk images was also fixed, as it previously failed to find its files. *(Tools-ISO)*

- **Agent upload can no longer destroy the Agent binary** — An accidentally empty or invalid Agent binary upload used to overwrite the working version before it was validated. Uploads are now checked for content and file type first and only applied if valid. *(server services)*

- **Agent update for individual devices no longer stops unrelated updates** — Starting an Agent update for selected devices or a group used to cancel every running Agent update fleet-wide. Now only the devices actually targeted are affected. *(server services)*

- **Batch SSH commands now respect the configured timeout** — When running a command on multiple devices at once, the specified timeout was ignored in favor of a fixed 30 seconds, causing longer-running commands such as package updates to abort prematurely. The configured timeout is now actually used. *(server services)*

- **Concurrent clone/restore operations no longer interfere with each other** — If two cloning operations were started almost simultaneously, e.g. via a double click, both could start and corrupt each other's data. The single-operation guard now works reliably, and cancelling during the first phase of an update clone is now honestly reported and actually honored. *(server services)*

- **Server stays reachable after brief Docker hiccups** — During a brief hiccup of the container runtime while saving network configuration, the server could lose the correctly configured addresses and become unreachable for clients, despite reporting "saved". Address resolution now falls back to the stored configuration in this case. *(server services)*

- **Network address is validated before being applied** — When setting the rollout network address, invalid addresses used to be accepted first and the old address removed, potentially leaving the network interface without an address. Addresses are now validated up front, and the new one is set before the old one is removed. *(server services)*

- **NTP access restriction survives editing** — Editing the time servers used to accidentally open the time service to the entire network instead of keeping it restricted to the rollout subnet. The restriction set during setup now persists. *(server services)*

- **BitTorrent distribution now reports errors correctly** — If adding a partition failed during a BitTorrent restore, the operation was still reported as successful even though a partition wasn't written. Such failures are now detected and the operation is reported as failed. *(server services)*

- **Tasks no longer run multiple times after a worker outage** — If the background worker went down temporarily, a pending task got re-queued on every device contact and later ran many times over. Tasks are now queued only once. *(server services)*

- **ThinVPN: more robust module and router management** — Duplicate VPN module names, or ones colliding with internal names, are now rejected instead of producing a permanently unstable configuration. With multiple devices sharing a name, VPN assignment is no longer guessed incorrectly, and a manually created second network router is no longer accidentally overwritten. *(server services)*

- **Errors are no longer silently swallowed** — In several places, internal errors were ignored and actions were wrongly reported as successful. Fixed, among others: a brief database hiccup no longer wipes the stored SMTP password when saving alert channels, an interrupted ISO upload no longer leaves behind an incomplete file that's still selectable, service monitoring now honestly reports a database outage as "degraded" instead of "ok", and failed NFS shares, time-service restarts, playbook imports, and an incomplete factory reset are now surfaced clearly instead of being swallowed. *(server services)*

- **NTP server input is now validated** — When saving time server settings, invalid entries — empty or containing disallowed characters — are now rejected instead of writing a broken time-service configuration. *(server services)*

- **Audit log now captures logins/logouts and admin actions** — The audit log used to be effectively empty: logins, logouts, failed login attempts, password and 2FA changes, user management, and license/signing-key actions were not recorded. **Security-relevant:** these events now land in the audit log; a factory reset is additionally written to the server log, since it clears the audit log itself. *(server services)*

- **Password reset now ends existing sessions** — If a user's password was changed via user management, that user's existing sessions used to remain valid — a previously stolen credential kept working. **Security-relevant:** existing sessions are now terminated and two-factor login is reset. *(server services)*

- **Minimum password length is now enforced everywhere** — The 8-character minimum previously applied only when users changed their own password; resetting or creating/editing users could still set empty or very short passwords. This is now checked in every path. *(server services)*

- **Hardening of the login interface** — **Security-relevant:** the logout endpoint is now rate-limited and only accepts valid session tokens, and the login endpoints reject oversized requests. This prevents a device on the network from burdening the server with mass or oversized requests. *(server services)*

- **Image capture: manipulation of a pending job prevented** — **Security-relevant:** a device on the network used to be able to disrupt another device's pending image-capture job by resetting its network boot configuration before the access token was checked. The token check now happens first. *(server services)*

- **ThinVPN: module port forwards now apply only to their own host** — **Security-relevant:** for optional ThinVPN host modules, forwarded ports used to accidentally apply to the entire target group instead of just the host of the relevant module. Forwards are now scoped exactly to their own module host; existing configurations are corrected automatically on the next sync. *(server services)*

- **Image distribution: a device's status report can no longer disrupt other devices** — **Security-relevant:** via the public completion callback of an image distribution, a device on the network used to be able to mark another registered device "offline" and revoke its file access without a valid access token. These actions now require a valid token tied to the running distribution. *(server services)*

- **Staged image distributions are now fully tracked** — In staged rollouts, completion of individual machines wasn't recorded internally: stage statistics stayed stuck on "distributing", and the failure-rate safety brake could never trigger; a badly timed status report from a machine could also silently defuse its pending reinstall. Rollout stages now use the same proven machinery as single distributions, with correct statistics and a working failure brake. *(server services)*

- **Incident notifications work again** — The periodic check of alert rules (e.g. client offline, disk full) was disabled by a placeholder and never actually ran. It now runs every five minutes. *(server services)*

- **Maintenance windows now genuinely suppress alerts** — Maintenance windows scoped to "all machines" (the default) as well as recurring windows (daily/weekly/monthly) were previously ignored during alert suppression — notifications still fired despite scheduled maintenance. Both are now evaluated correctly, including in the active indicator on the windows list. *(server services)*

- **ThinVPN log no longer grows without bound** — VPN event ingestion re-stored the same events on every poll, causing the log table to grow indefinitely. Events are now uniquely identified and stored only once. *(server services)*

- **Client TPM status is now saved** — The TPM status reported by the client — present or sealed — used to be silently lost on save because the required database fields were missing. It is now saved reliably. *(server services)*

- **"In stock" flag is now applied when creating a client** — The In-stock toggle in the creation form used to be discarded on save; the flag had to be set afterward. It's now applied directly when the client is created. *(server services)*

- **Agent: backup states are now managed correctly** — The Agent now reliably keeps exactly two backup states — the current and the previous one — along with their associated home data. Previously, faulty sorting could cause the wrong states to be deleted, and an unsuitable state could be chosen for recovery in an error case. *(Agent)*

- **Multi-step OS updates no longer get stuck** — When a client had to go through several update steps in sequence, e.g. via an intermediate version, the chain could stall after the first step because the next step never received download clearance. Only chains without combined updates were affected; this is now fixed. *(server services)*

- **Setup wizard validates input and reports partial failures** — The wizard no longer accepts invalid input — such as too short an administrator password, invalid network addresses, or an invalid certificate lifetime — rejecting it with a clear error before saving. If a sub-step fails at the end, e.g. generating the certificate, this is now shown at the end of the wizard instead of vanishing behind a success message. *(server services)*

- **Scheduled distributions also work in the release deployment** — In the shipped variant of the services, the background worker was missing some mappings and settings it needs to activate scheduled distributions, and DHCP/PXE monitoring there still used a less informative check. Both are now aligned with the development variant. *(server services)*

- **Factory reset no longer bricks the server** — After a factory reset, the server could get stuck in an error loop on next restart because an internal management table was cleared along with everything else; ThinVPN management also couldn't be set up again afterward. Both are fixed — the reset now leaves a clean state for the setup wizard. *(server services)*

- **Certificate upload can no longer take down the web interface** — When uploading a custom TLS certificate, the existing certificate used to be replaced before the files were validated — a broken or mismatched key then made the web interface unreachable. Certificates and keys are now fully validated, including that the certificate and key match, before being applied; on failure the existing certificate stays active and the upload is rejected with a clear error. *(server services)*

- **Cancelled distributions no longer start new installations** — If a staged rollout was cancelled, affected machines remained flagged for reinstall anyway and got re-imaged on their next boot. A cancellation now reliably excludes machines that haven't started yet from the distribution, including any scheduled reboots, while installations already in progress finish undisturbed. *(server services)*

- **DHCP/PXE service reliably survives server restarts** — If, after a server restart, the rollout network interface came up only after the container runtime, the DHCP/PXE service failed to start and stayed down permanently. It now automatically waits for the network interface and binds as soon as it becomes available; a permanently missing or misconfigured interface is additionally flagged as faulty in service monitoring. *(server services)*

- **Name resolution for "thinforge-server" no longer points to a wrong address** — If network or DNS settings were saved while the rollout interface happened to be unavailable, the internal DNS entry "thinforge-server" could end up permanently pointing to a wrong address — clients would then have been unable to reach the server. Saving now uses the stored rollout address or rejects the change with a clear error message. *(server services)*

- **Notification dialogs on client machines appear reliably again** — Messages the Agent shows on the logged-in user's screen — such as the reboot countdown after an OS update or an active remote-support session notice — stopped appearing in certain login situations, because the Agent accidentally targeted an already logged-out screen session and silently dropped the message. The Agent now reliably picks the actually active session of the logged-in user. *(Agent)*

- **Image preparation: per-user sudo rights selectable** — When completing a base install via the Tools-ISO, a selection list now lets you choose which local users get sudo rights; the selection is validated and stored cleanly. The selected user is also set up for automatic login — if no one is selected, nothing is granted. *(Tools-ISO)*

- **Desktop wallpaper is now applied reliably** — The ThinForge wallpaper is now correctly applied and takes effect immediately at login on XFCE desktops under Debian 13 too; previously, the preset system wallpaper could persist in some configurations. *(Tools-ISO)*

- **Image preparation: unneeded programs are removed** — When completing a base install, preinstalled programs not needed for thin client operation — including LibreOffice, various XFCE accessory apps, and terminal emulators — are now automatically removed and the package cache cleared. The desktop environment itself remains fully intact, resulting in leaner images. *(Tools-ISO)*

- **VDI clients (Citrix / Parallels / Omnissa Horizon) can be integrated** — VDI clients can now be provided via a folder on the Tools-ISO; their installation is offered as an option when completing image preparation. *(Tools-ISO)*

- **New feature: upload VDI client packages via the web interface** — The Cloning area gets a new "VDI Clients" tab for uploading installer packages for Citrix Workspace App, Parallels Client, and Omnissa Horizon Client. The packages are automatically pulled into the Tools-ISO the next time the cloning VM starts, making them available during image preparation; previously the files had to be placed on the server manually, which was especially awkward for Omnissa since its download requires logging in with the vendor. *(server services)*

- **Device hardware inventory is captured again** — Hardware data gathered via inventory queries — CPU, RAM, manufacturer, model, serial number, BIOS, disks — was being queried but not saved; the corresponding fields stayed empty. It is now parsed and stored against the device. *(server services)*

- **Distributions are now reliably recognized as complete** — If a device's final completion report was lost, e.g. due to a reboot just before it could be sent, a distribution stayed stuck as "active" indefinitely. A reconciliation pass now detects distributions where every device is already done and closes them out. *(server services)*

- **Restore now validates every selected backup** — If validation failed for one file among several selected backup files, restore could still proceed using unvalidated files. It's now blocked until every selected file has been validated successfully. *(server services)*

- **Saving an update no longer accidentally creates a new base** — If the "Save Clone" dialog failed to load the VM's state on open, it used to silently fall back to base mode — the operator could unknowingly create a new base image instead of an update. A clear error is now shown instead, and saving stays locked. *(server services)*

- **Progress display no longer hangs on brief hiccups** — A single brief polling error during a clone/restore operation used to leave the display permanently stuck on "running". The refresh now only stops after several consecutive failures. *(server services)*

- **Login and uploads in the web interface are more robust** — A failed login again shows the specific error message instead of silently bouncing the user back to the login page, and a file upload no longer needlessly ends a valid session. *(server services)*

- **English labels for time server settings** — The English-language time server settings used to show internal placeholders instead of the actual text. The missing translations have been added. *(server services)*
## 2026-06-02

- **OS updates are now reliably retried after a license upgrade** — An OS update (delta) held back while a thin client ran in restricted mode (no valid license) is now applied automatically once a valid license is installed. Previously, the update could stay permanently blocked with a "failed too often" message, because failed attempts from before the license was applied were wrongly counted toward the retry limit. *(Agent)*

- **Status ping now reaches VPN clients too** — Clicking a device's status in the clients overview checks reachability with a ping. For clients connected via ThinVPN, this ping was being blocked by the VPN firewall, so they showed up as offline even though they weren't. A new VPN rule now specifically allows the server to ping these clients. *(Server services)*

- **Consistent bilingual support (German/English)** — Server error messages and previously hard-coded German interface text now follow the selected language. The provisioning scripts (Tools-ISO) now output their messages consistently in English, and the language of the on-screen dialogs on client machines (e.g. restart countdown) can be set from the server. *(Server services, agent)*

## 2026-06-01

- **Client authentication hardened (per-client tokens)** — Each thin client now gets its own authentication token after first contact instead of sharing one. A single compromised client can no longer send messages on behalf of other clients. If a client is redeployed, the server automatically reissues its token on next contact. *(Server services)*

- **Clients overview: rejected logins are now visible** — If a client can no longer authenticate with a valid token, it is now flagged red as "token rejected" in the clients overview instead of just showing offline, so the problem is immediately noticeable. *(Server services)*

- **New "Reissue token" action per client** — A new authentication token can now be issued for a single client from the clients overview; the client picks it up on next contact without affecting other clients. *(Server services)*

- **VPN setup: removed non-functional "Guide" link** — On the VPN page (shown while ThinVPN is not yet set up), the "Guide" button was removed, since it pointed to a documentation page that didn't exist yet. *(Server services)*

- **Security hardening of update and certificate distribution** — When distributing OS updates (deltas), the download is now strictly bound to the exact update a client was authorized for — a client can no longer fetch someone else's update files. Trusted certificates uploaded by an operator are now signed before being pushed to clients and cryptographically verified by the client, and the remote-management controls were hardened against tampered input. *(Server services, agent)*

## 2026-05-31

- **Vulnerability report now prioritized by real urgency** — Remaining (reachable) vulnerabilities in the report are now sorted by exploitation likelihood and fixability: known actively exploited flaws (CISA "Known Exploited") are listed first and flagged, followed by risk score, and each entry shows whether a fix is already available. This makes it obvious at a glance what to address first; the assessment of individual vulnerabilities itself is unchanged. *(Server services)*

- **Vulnerability report: services reachable via VPN are now flagged separately as "External"** — Services reachable from outside the local network via ThinVPN now get their own, highest reachability tier "External" in the vulnerability report (own icon, sorted at the top), instead of being lumped in with "LAN" as before. This tier only applies when VPN is actually set up; without it, the ceiling remains "LAN". The assessment of individual vulnerabilities is unchanged — the new tier just makes clearer which components carry the largest attack surface and should be prioritized. *(Server services)*

## 2026-05-30

- **Image/clone deletion blocked while a rollout is in progress** — An image or clone can no longer be deleted while a rollout still uses it; the delete attempt is now rejected with a message instead of disrupting the running rollout. *(Server services)*

- **More reliable login during brief network hiccups** — Login and session restoration now handle short connection drops more robustly: a transient error while loading the profile no longer incorrectly reports "logged out", and a retried request no longer triggers a duplicate token refresh. *(Server services, management interface)*

- **Usability improvements in the management interface** — In the cloning-VM configuration dialog, input fields are no longer overwritten every 10 seconds by the automatic status poll. A manually triggered reachability check ("ping") result now only briefly overrides the real device status instead of permanently, and a previously exported device list can again be imported without errors when the interface language is set to English. *(Server services, management interface)*

- **Correct version numbers past the 100th capture per day** — When many image snapshots are created under the same name on a single day, the daily counter now continues correctly past 100 instead of potentially wrapping around. Affects only installations with very frequent captures. *(Server services)*

- **Wake-on-LAN sent over the correct network interface** — On servers with multiple network interfaces, the wake signal is now sent specifically over the rollout network interface instead of whichever one the OS happened to pick. *(Server services)*

- **Additional internal hardening** — Additional validation against invalid input (DNS settings, file/path values, CSV export) plus minor fixes to internal task processing. No visible change in operation. *(Server services)*

- **Administrators can no longer reset another administrator's security credentials** — Resetting a user's two-factor login (TOTP) now behaves the same way as resetting a password: accounts with the Administrator role are exempt, and an administrator's own account must be changed through the regular self-service paths. This means one administrator can no longer strip another administrator's second security factor. *(Server services)*

- **Stability and hardening (batch of fixes from an internal code review)** — Several rare failure situations are now handled cleanly instead of failing silently: a device with no assigned address is now skipped cleanly during a rollout instead of hanging, a rollout's abort threshold is now calculated only from devices that have actually finished, an image transfer can no longer accidentally start twice, and VPN setup no longer aborts on a brief hiccup but retries. Several possible crashes on unusual output were also caught. Purely defensive changes with no change in normal behavior. *(Server services)*

- **Agent more stable during update preparation** — If preparing a device update unexpectedly fails, it can no longer bring down the running agent; the agent keeps checking in with the server as normal. The agent also validates the version string more strictly before cleaning up old snapshots. *(Agent)*

- **Update rollout: starting it is now enough — no separate "release" step needed** — Starting (activating) an update rollout now automatically releases the associated delta update for delivery; assigned devices then pull it on next contact. Previously, a started rollout could remain ineffective if the delta hadn't been manually released beforehand, leaving devices with nothing to download. *(Server services)*

- **Additional hardening of scripts executed on devices** — The maintenance and setup scripts that the agent runs with elevated privileges are now also cryptographically signed and verified against the trusted signing key before every execution — the same protection already applied to the agent software and update packages. Previously, only the encrypted connection protected these scripts in transit; a tampered script is now detected and refused. *(Server services, agent)*

- **Image distribution: a device's read access ends immediately once it finishes** — When rolling out an image to multiple devices, read access to the image storage (NFS) used to stay open for all participating devices until the entire rollout finished. It is now revoked per device as soon as that specific device is done, without disrupting the other, still-running devices. Tighter access with no change to the rollout flow itself. *(Server services)*

- **Upgrading very old data fails clearly instead of looping on restart** — If the server starts against a very old data directory (from a version predating the VPN feature), the database migration step used to abort with an internal error and the service would loop-restart. This case is now detected and the step ends with a clear message and instructions (the data directory must be freshly initialized). A direct in-place upgrade from such old states is deliberately not supported — the supported path is a fresh initialization. Affects only very old installations. *(Server services)*

- **License seats are now assigned consistently and stably** — Assignment of "Full" license seats to devices was inconsistent in certain cases: active (online) devices could incorrectly be downgraded to "Light" while offline/retired devices kept blocking a paid seat, and individual devices could flip back and forth between "Full" and "Light". The rule is now consistent: devices booked as stock don't count toward the license, and all remaining devices share seats stably (the oldest keep their seat when oversubscribed). *(Server services)*

- **Vulnerability report: a real vulnerability in a reachable container is no longer hidden by an isolated container** — If the same vulnerability (CVE) was classified as "not affected" in an isolated container, it used to also disappear from the report for a LAN-reachable container running the same image — the report could falsely show "passed" even though a real, critical vulnerability was present there. The "not affected" classification now applies only to the exact container it's true for; the vulnerability continues to show up correctly for every other reachable container. *(Server services)*

## 2026-05-29

- **Concurrent image captures no longer interfere with each other** — If two or more devices were started for an image capture at the same time, the write share for images could get displaced between them — the first device to finish could revoke write access from the others still capturing, causing them to fail. The write share is now reliably kept open for all captures in progress and only closed once the last one finishes. *(Server services)*

- **License tier enforced more reliably on devices** — Devices now cryptographically verify the stored license at startup, including its expiry date. A tampered or expired "Full" marking now automatically falls back to "Light" — even without a connection to the server. *(Agent)*

- **Downloading an ISO by URL: better protection against internal targets** — When downloading an ISO from a given web address, every redirect is now re-checked to confirm the target isn't an internal/private address. Previously, certain redirect chains and address notations could bypass this check. Server-side hardening only. *(Server services)*

- **2FA: re-running setup no longer accidentally disables existing 2FA** — Re-opening 2FA setup used to immediately disable an already-active 2FA, before a new code was even confirmed — an abandoned setup attempt left the account without 2FA. Existing 2FA now stays active until a new code has been successfully confirmed. *(Server services)*

- **Changing password now signs out existing sessions** — After a password change or reset, all previously issued sessions for the account are now invalidated — including on other devices or in other browsers; the user then signs in once with the new password. Previously, old sessions remained valid until they expired naturally. *(Server services)*

- **VPN "Disconnect & delete": a failed cleanup is now reported as an error** — If deletion on the VPN server failed during "Disconnect & delete" for a VPN client (e.g. the VPN service was briefly unreachable), ThinForge used to still report "done" even though the device still had VPN access. Such a failure is now shown as an error and the operation can be retried. *(Server services)*

- **Remote desktop: session limit and idle timeout now actually take effect** — The "maximum concurrent sessions per device" and "idle timeout" settings were previously not enforced. Excess parallel remote-desktop sessions to the same device are now rejected, and a session with no activity is automatically ended once the idle timeout expires (an actively used session is left alone). *(Server services)*

- **License limit enforced more reliably** — The license's device limit could be bypassed two ways: by later switching a device from "stock" to "active", or through several exactly simultaneous VPN activations. Both paths are now correctly checked against the limit. *(Server services)*

- **Remote access restricted to administrators and operators** — The built-in device terminal and remote-desktop control can now only be opened by accounts with the Administrator or Operator role. Read-only accounts (the default for newly created users), as well as already logged-out or disabled accounts, are now reliably rejected. This brings these direct-access paths under the same permission check as other device actions. *(Server services)*

- **Vulnerability report shows local vulnerabilities completely again** — Vulnerabilities exploitable only locally or from the directly adjacent network could, in certain circumstances, be incorrectly classified as "not affected" and hidden from the report, making it falsely show "passed". This classification was corrected — such vulnerabilities appear correctly in the report again. *(Server services)*

- **System restore now reports database failures as failures** — If the database portion of a system backup failed to restore, the restore process used to still report "success". Such a failure is now clearly reported as a failure, and the database portion is either fully restored or not restored at all — no half-restored state. *(Server services)*

- **Broken clone states can no longer be rolled out** — A clone marked as broken (e.g. after a faulty version was withdrawn) can no longer be selected for a new rollout, preventing the defect from spreading to further devices. *(Server services)*

- **More stability for update downloads and remote commands** — Several internal safeguards prevent an aborted update download or an unresponsive device from permanently tying up server resources: a timeout for remote commands, clean termination of interrupted downloads, and lower memory usage for large ISO and backup operations. *(Server services)*

- **VPN tab: refresh buttons show a loading animation again** — In the "Configuration", "Resources" and "Groups" sections of the VPN tab, clicking the refresh icon didn't spin a loading indicator even though data was actually being reloaded in the background. The icon now shows the loading state consistently, matching the other refresh buttons. Display-only fix — the loaded data was always current. *(Management interface)*

## 2026-05-28

- **Internal server code cleanup** — Extensive simplification and removal of unused backend code, with no change in behavior or features. No operational impact. *(Server services)*

- **Upload certificates for clients (e.g. for Citrix)** — The "Clients" area now has a new "Certificates" tab. Trusted certificates (CA or server certificate, as PEM or DER files) can be uploaded there — either for all devices or targeted at a specific group. Devices automatically install the assigned certificates into their system certificate store, so, for example, the Citrix Workspace app trusts a self-signed server without manual setup on each device. If a certificate is deleted again in the interface, devices remove it too on their next sync. *(Server services, agent)*

- **VPN: reconciliation and "Disconnect & delete" now work more reliably** — Several internal improvements to automatic VPN configuration reconciliation. The server entry is now correctly matched to the right device even when multiple entries on the VPN service share the same name (the actually connected one wins). Duplicate access rules left over from an aborted operation are now automatically cleaned up on the next reconciliation. "Disconnect & delete" now reliably removes resources and routing even when the VPN network mapping was internally ambiguous, so no leftovers remain that would block deleting groups. *(Server services)*

- **VPN: changing the local gateway no longer triggers an incorrect reconciliation of the server entry** — Reconciliation used to try to switch the ThinForge server's VPN entry (and its DNS record) to the gateway address whenever the local network's gateway changed. That was wrong: the gateway is the network's router, not the ThinForge server. The server entry is now based on the server's actual address on the local network (preferring the configured "server IP", otherwise the real network interface address) — the gateway is deliberately no longer used for this. If no server address can be determined, the operation now aborts with a message instead of guessing. *(Server services)*

- **VPN: two default access rules now target the group instead of the server directly** — The two rules that let VPN clients reach the ThinForge server (name resolution/DNS and access to the management interface) now target the "thinforgeTarget" group instead of the server entry directly. This group covers the server via both its VPN address and its local network address, so access works either way — and the drift previously shown in the "Configuration" tab for these two rules is gone. *(Server services)*

## 2026-05-26

- **VPN: "Disconnect" is now "Disconnect & delete" and cleans up fully** — The button in the VPN configuration area was renamed, and clicking it now first removes every object the ThinForge server created on the VPN service (access rules, resources, routing, DNS entry, server peer, groups) before deleting the connection locally. Previously, leftovers could remain — for example, groups that couldn't be removed because access rules still referenced them. *(Server services, management interface)*

- **VPN: three default access rules are now centrally managed** — The ThinForge server now creates three default access rules itself and keeps them in the desired state, matching the actual configuration on the VPN service: DNS resolution and management-interface access from devices to the server, plus remote maintenance (SSH) from the server to devices. This keeps these rules consistent even after setup is re-run. *(Server services)*

- **VPN area fully bilingual (German/English)** — The entire VPN area (overview, devices, configuration, groups, tasks, and all related setup/activation/disconnect dialogs) now follows the language switcher and is fully available in German and English, instead of being hard-coded to German. Unused leftovers from the earlier VPN technology were also removed as part of this, with no change to visible functionality. *(Server services, management interface)*

- **VPN: minor usability improvements** — When activating VPN for a device or an entire group, the "Clients" group is now preselected. In the configuration area, the button to apply the desired state is now labeled "Apply config" (previously "Reconcile now"). *(Management interface)*

- **VPN "Local resources": targeted host shares now take effect immediately** — The former "Host access modules" area is now called "Local resources" (created via "New resource") and bundles a target device with the allowed services/ports, e.g. for remote maintenance of a specific device. New: creating or deleting one now immediately applies (or removes) the corresponding rule on the VPN service — the previous separate "Reconcile now" step is no longer needed for this. The access rule created on the VPN service gets a clear, descriptive name from resource name, protocol and port (e.g. "w22 TCP 5900") and grants VPN clients access to the target device. *(Server services, management interface)*

## 2026-05-25

- **VPN network configuration is now centrally managed and automatically reconciled with the VPN service** — The ThinForge server now sets up the VPN structure (network, server peer, DNS and access rules) itself and automatically keeps it in the desired state. The new "Configuration" tab in the VPN area shows the actual state, flags drift, and offers a button to re-apply the desired state; targeted host access can also be defined there as reusable modules — a target device plus allowed services/ports — which are automatically applied to the VPN service during reconciliation. The former "Target networks" area is removed; the new model takes over its job. *(Server services, management interface)*

- **Fix: devices with active VPN show "VPN" instead of "LAN" again in the device list (Agent v2.14.14)** — For devices reporting their status over the VPN connection, the device list incorrectly showed "LAN" as the connection path. The cause was an internal name mismatch for the VPN network interface, which made the actual-path detection fail silently and always fall back to "LAN". This is fixed — the connection path is detected and shown correctly again. Takes effect once a device has picked up the new agent version and reconnected to VPN once afterward (toggle VPN off and on once on the device); newly set-up devices are correct immediately. *(Agent)*

- **VPN clients now reliably keep their VPN service in the desired state — and never turn it off on their own again** — Whether a device should have VPN enabled is now stored persistently on the device itself: on activation, it remembers "VPN on" and from then on ensures on every boot that the VPN service is running (even after a restart or system update); on deactivation, it remembers "VPN off" and keeps the service stopped. The previous automatic shutdown while on the local network is removed — a device now only turns off its VPN service on explicit instruction, never on its own. *(Agent)*

- **VPN area: a device now shows "installed" only once it has actually confirmed VPN setup** — Previously, the status jumped straight to "installed" right after activation, even though the device hadn't actually completed VPN setup yet (this could happen, for example, if an older entry for the same device still existed on the VPN server). The list now shows "installing" first and only moves to a confirmed state once the device itself reports back that the VPN service is set up — after that, "paused" (set up, connection currently off, e.g. while on the local network) or "active" (connected). If setup fails (for now) — e.g. because the device currently can't reach the VPN server — the status stays "installing"; details and the option to retry are in the "Tasks" sub-tab. *(Server services, agent)*

## 2026-05-24

- **Newly installed devices route the VPN tunnel through the relay server from the start and disable IPv6 in the tunnel** — During initial installation via the Tools-ISO, the VPN service is now configured from the start so the tunnel always routes through the relay server (instead of first negotiating a direct connection, which is unreliable behind some firewalls) and so IPv6 is disabled inside the tunnel. Previously, the relay-forced setting was only applied once the device logged into VPN; now it's already in place from installation onward. No visible behavior change — it just makes the VPN connection more robust. *(Tools-ISO)*

- **The server's VPN mesh service now uses the official NetBird image and stays current more easily** — The VPN mesh service on the ThinForge server used to run from a custom-built image with an older NetBird version baked in, requiring a rebuild to update. It now pulls the official NetBird image directly, so a simple image update always brings the latest version. Behavior is unchanged. Note for updating an existing installation: the mesh service must be re-registered once afterward (in the VPN area, save the connection configuration once). *(Network services)*

## 2026-05-23

- **Fix: VPN now genuinely comes back up on its own after a system update (Agent v2.14.11)** — The automatic VPN reconnection after an update, introduced in the previous version, didn't actually work: an internal check looked for the VPN credentials in the wrong location and skipped re-enabling the service. Devices that already had VPN activated now turn their VPN service back on by themselves after an update, once they've picked up the new agent version. *(Agent)*

- **VPN area: devices grouped, correct status, and background activation** — The device list in the VPN area is now organized by the groups enabled for VPN: each group is a collapsible heading showing device count and how many are activated; expanding it shows individual devices and lets you activate VPN for them — individually, or via "Activate entire group" for all not-yet-activated devices in a group at once. Devices never activated for VPN now correctly show "not activated" instead of incorrectly showing "installed". The two refresh buttons now pull the current state directly from the VPN server (top: everything; device list: devices only). Activation now runs as a background task: a new "Tasks" sub-tab shows the ongoing activations per device with status and any errors (with retry). *(Server services, management interface)*
## 2026-05-22

- **Devices automatically reconnect to the VPN after a system update (Agent v2.14.10)** — After a system update the VPN service was initially disabled, because the fresh image ships with it off by default; previously the connection only came back once the server told the device to reconnect. The device now re-enables its own VPN service on first boot after the update, provided it was previously enrolled — enrollment survives the update. Devices without VPN are unaffected. *(Agent)*

- **Devices now report status every 10 seconds instead of 60 (Agent v2.14.8)** — The reporting interval was shortened so that online/offline status and device info in the dashboard refresh much faster. Devices keep the constant 10-second cadence even during transient connectivity issues instead of automatically slowing down. The interval remains centrally configurable in the agent settings. *(Agent)*

- **Devices keep their name and VPN enrollment after an update — without an extra reboot (Agent v2.14.7)** — The correct device name is now written directly into the new image during a system update, so the device is already correctly named on first boot after the update (previously an extra automatic reboot was required for that). VPN enrollment likewise survives the update, and the triggering command is followed exactly (reboot reboots, shutdown shuts down). *(Agent)*

- **Devices reboot once automatically after a name change (Agent v2.14.6)** — Whenever the agent sets or changes the device name — on first boot of a freshly rolled-out device, when moving from the template VM to real hardware, or when the name had to be corrected — the device now reboots once immediately without confirmation, so the new name takes effect everywhere (previously services and login sessions could still use the old name). A guard prevents repeated reboots if something keeps resetting the name on every boot. *(Agent)*

- **Core server services now start independently of the VPN and remote-support services** — The central service no longer waits for VPN and remote support to report "ready" during startup — if either optional add-on service is down, the core still comes up normally instead of waiting. A regular full-system startup still brings up both as before; a targeted start of only the core service, however, no longer starts them automatically. *(Server services, deploy repo)*

- **Setup wizard: new defaults for domain, DHCP range, and redirect timer** — The default domain is now thinforge.lan instead of thinforge.org, the DHCP address range now starts at the tenth network address instead of the 100th (leaving the addresses before it free for static assignments), and the automatic redirect to the login page now waits 15 seconds instead of 10 so the web server has safely picked up its freshly issued certificate. Existing installations are unaffected — the defaults only apply to fresh setups and remain freely overridable in the wizard. *(Backend, management interface)*

- **VPN is now its own top-level menu item, between "Cloning" and "Network"** — The VPN area used to be a sub-item under "Network"; it's now one level up, directly in the main navigation. Nothing changes functionally — same VPN management as before, just one click closer. "Network" keeps its remaining tabs (Local network, DHCP/DNSMASQ, DNS, PXE). *(Management interface)*

- **VPN tab: connection status and active-client count now come from the ThinVPN mesh server instead of device self-reporting** — The server now polls mesh status directly every minute; a device counts as "connected" in the VPN tab only if that poll reported it connected within the last 3 minutes, otherwise "disconnected". Previously the server's view and the device's self-report could disagree; this status source affects only the VPN tab — general device online/offline status is unchanged. *(Backend, management interface)*

- **VPN: devices now correctly report whether they're on LAN or VPN, and activated devices route through the relay by default** — The overview used to always show "LAN", even for devices actually connected over VPN, because the required location check was never configured server-side. The server now tells every VPN-activated device how to check its location: it regularly checks whether it can reach the server directly on the local network, secured via the server certificate fingerprint (so an attacker on the local network can't trick the device into disabling its VPN with a spoofed server). Devices now reliably report "LAN" or "VPN" back, so a device on the local network disables its tunnel and a remote device keeps it up; newly activated devices are also now set to always route their VPN tunnel through the relay instead of first negotiating a direct connection, which is unreliable behind some firewalls. *(Backend, Agent)*

## 2026-05-21

- **VPN tab: new "installing" status after activation** — Previously a device's status jumped straight to "installed" the moment you clicked "Activate", even though the device hadn't actually applied the VPN configuration yet. The table now shows "installing" (blue) first and only switches to "active" (green, and "installed" is now green too) once the device reports a successful VPN sign-in on its next status sync — the status now reflects the device's actual report, not just the click. A device stuck on "installing" for a while hasn't completed enrollment yet. *(Backend, management interface)*

- **Internal consolidation of the database schema into a single initial file** — The previously separate schema pieces are now merged into a single file that's applied on a fresh database. Purely internal cleanup with no functional impact — the resulting schema is verifiably identical. *(Backend)*

- **Web server network separation tightened: the admin interface is now reachable only from the management network** — The web server serves the client LAN, the VPN tunnel, and the management network with a separate, tightly scoped path list each, instead of one blanket allowlist. From the client LAN and over VPN, only the paths a device actually needs are reachable (heartbeat, self-update, certificate/token recovery, delta downloads) — the admin API and the management interface are invisible from those networks (404), even behind login. Conversely, the same device-only paths are now blocked from the management network (403), so an attacker there can no longer trigger forged heartbeats or delta downloads even with a valid heartbeat token. *(Backend)*

- **VPN tab: new "Target networks" and "Groups" sections, plus group selection when activating** — Under "Target networks" you can define subnets a VPN client should reach through the tunnel (CIDR, routing peer, group access); the ThinForge server is automatically set up as the routing peer for its own LAN. Under "Groups" you can create your own groups, and a dialog now lets you pick the target group when activating a device instead of always using the built-in default group. Operators see both read-only; creating or editing remains admin-only. *(Backend, management interface)*

- **VPN mesh backend (ThinVPN container) updated to version 0.71.3** — The local server-peer container was still on the year-old 0.30.0 while endpoint devices already ran 0.71.2; this version gap occasionally caused subtle sync glitches on route updates. Both sides now run in sync. *(Server services, deploy repo)*

- **Agent v2.14.2/v2.14.3: explicit heartbeat processing order and a hard timeout on joining the VPN** — Processing of the heartbeat response now runs in four clear phases (config sync → license → update → VPN) instead of an organically grown order, and the agent now actively waits up to 15s for the VPN daemon socket and cleanly aborts a stuck join attempt after 60s instead of blocking indefinitely. Previously a device could appear "stuck" to the server for minutes while it was really just looping internal retries. *(Agent)*

- **VPN: remote devices automatically get the local DNS server, and disconnecting now fully removes all VPN objects** — Once the VPN management connection is set up, remote devices are automatically assigned the ThinForge server as DNS server for the local zone (split DNS), provided a local domain is set in the DNS setup. Conversely, disconnecting the VPN connection on the server now also removes all automatically created objects (server peer, LAN route, DNS entry, ThinForge groups, activated client devices) — no more orphaned leftovers. *(Backend, management interface)*

- **VPN: the server DNS name "thinforge-server" is now decoupled from the DHCP gateway** — The DNS entry used to point at the DHCP-configured gateway address; if the gateway differed from the actual server IP, the name resolved to nothing and devices could no longer reach the server. The entry is now derived from the IP the server actually binds to on the rollout interface, and the same applies to the web server listener. *(Backend)*

## 2026-05-20

- **VPN overhauled from the ground up — more secure, easier to operate** — The previous VPN integration was replaced with an end-to-end encrypted solution; the management server itself can no longer see the content of VPN packets. Instead of the old sub-tabs, there's now a clear setup wizard (URL + token, test connection) followed by a single device table with Activate/Deactivate; activation keys no longer expire, and devices automatically switch the tunnel on or off based on location, with no user action needed. License limits are still enforced at activation. Existing clone images on endpoint devices need to be updated once for the new VPN solution to reach them. *(Backend, management interface, Agent)*

## 2026-05-19

- **License status now catches up automatically after expiry (previously only on server restart)** — If the server process ran past the license expiry date, the internally cached license status stayed frozen at startup and newly assigned devices kept being marked Full even though the license had actually expired. The server now re-checks license status hourly in the background and reconciles device tier assignment accordingly — transitions Licensed → grace period → Free now take effect within an hour without a restart; the 60-day grace-period behavior itself is unchanged. *(Backend)*

- **New dashboard card "License" — status at a glance** — The card shows a color status chip (Licensed green / grace period orange / expired red / Free gray), the license holder, remaining days until expiry (or days into the grace period), and device usage as a bar that turns yellow above 90% and red at 100%. Clicking through leads directly to Settings → License; the card is visible by default and, like all dashboard cards, can be hidden or resized. *(Management interface)*

## 2026-05-18

- **Client list now shows a "Current IP" column** — Between status and installed version, a new column shows the IP address each device is currently reachable at, with a small icon indicating local network (LAN) or VPN tunnel connectivity. VPN-only devices (e.g. remote workers) show their WireGuard address, LAN devices their local IP; the column updates automatically on the next heartbeat, and devices with no current connection are grayed out. *(Management interface)*

- **VPN devices are now reliably marked "online" even without a regular heartbeat** — The background reconciliation meant to update the online status of VPN-only devices from their fresh WireGuard handshake was failing on a database error because the column format and the value passed didn't match — affected devices stayed stuck on "offline" even with a confirmed live tunnel, and the error also aborted checks for the remaining devices in the same run. The value is now passed in the correct format and the reconciliation runs cleanly. *(Backend)*

- **Signature errors on delta updates now show in red in the Updates tab** — When a client reports an invalid delta signature, the backend correctly marked the rollout as permanently failed internally, but the overview only showed a gray chip with no text. The status now shows in red with the plain-text label "Invalid signature". *(Management interface)*

- **Agent applies delta updates again** — The agent was refusing to download delta updates entirely, because a leftover pre-check kept looking for a shell script that had long since been replaced by the built-in apply logic, and blocked the download when it wasn't found. That pre-check is now removed; the agent downloads deltas again and applies them on shutdown as intended. *(Agent)*

- **The license limit is now reliably enforced, even under simultaneous first-time enrollments** — If several devices enrolled for the first time at the same moment, a race condition in seat allocation could mark more devices as Full than the license actually allowed. Allocation now runs under an exclusive lock; in addition, the backend now cleans up tier distribution on startup, license upload, and license deletion (excess Full seats are downgraded to Light, with the oldest devices keeping priority) — so a license downgrade also takes effect immediately instead of only after many heartbeats. *(Backend)*

- **Vulnerability exception list cleaned up after today's bulk update** — Following the library updates (see next entry), the curated list of accepted vulnerabilities was refreshed: 24 entries that no longer apply were removed, 12 were trimmed down to their remaining CVEs, and a new block was added for findings in the third-party guacamole/guacd container (which sits on an end-of-life Alpine 3.18 base). The list is bind-mounted into the backend, so a backend restart is enough. *(Backend)*

- **Bulk update of all container libraries — many known vulnerabilities disappear at once** — The reverse proxy and database were bumped to their latest stable releases, the self-built containers moved from Alpine 3.22 to 3.23 (fresh SQLite, QEMU/OVMF, GLib, and OpenSSL versions), and the bundled Docker CLI moved to version 29.5 with a fixed Go runtime — together removing over 30 previously accepted CVE exceptions. What couldn't be fixed: the third-party guacamole/guacd container has sat on an old Alpine base without an upstream update since June 2025; the remaining findings there only affect the internal container network, with no LAN exposure. *(Backend, management interface, server services, deploy repo)*

- **Vulnerability scoring now correctly recognizes containers with a "vendor/name" image label** — All 84 findings for the guacamole/guacd container were landing in "needs manual review", because the naming heuristic that matches CVEs against container reachability couldn't find a match for the "vendor/name:version" form in the container list. A direct lookup built from the compose file's declared container images now takes priority; those findings flow through the normal reachability filter again, and two falsely red-flagged critical findings disappear. *(Backend)*

- **Security scan overview no longer lists containers twice** — The same ThinForge containers appeared twice in the scan overview — once under their short name and once under the full registry path — because both names point at the same image ID after an image pull, and the scan checked each separately. The scan now deduplicates by internal image ID before running; scoring and acceptance status stay the same, only the overview gets shorter. *(Backend)*

## 2026-05-17

- **Restoring large data backups now touches the disk once instead of three times** — During a restore, a multi-gigabyte data backup used to sit on disk up to three times at once (the upload, the unpacked intermediate copy, and the final location) — a 50 GB backup briefly needed 150 GB free. The archive is now streamed straight through the unpacker during upload and lands directly at its target location, which is atomically activated by rename at the end; space requirements drop to a single backup's size and the restore runs noticeably faster. *(Backend)*

- **Data backup restore now also registers restored deltas in the overview** — Delta files were being written back to disk correctly during a restore, but didn't show up in the delta overview, because that view reads from the database and the matching records were missing (especially after a data-only restore without a matching system backup). The restore now scans the delta folder at the end and backfills missing records without overwriting existing ones. *(Backend)*

- **Maximum backup file size for restores raised from 60 to 120 GB** — The reverse proxy and backend now allow backup uploads up to 120 GB — preparation for data backups with larger clone inventories. *(Backend)*

- **Uploading large backup files during a restore no longer aborts mid-upload** — The backend used to buffer the entire uploaded file in memory before writing it to disk — with a multi-gigabyte file that was enough to silently kill the connection on memory-constrained machines, and a separate, smaller per-field size limit in the underlying multipart library could reject the upload too. File content is now streamed straight to disk during upload; backups in the tens-of-gigabytes range can now be restored reliably. *(Backend)*

- **Backup restore now accepts multiple files at once and shows upload progress** — The system backup and the data backup (clones/deltas) can now be uploaded together in one step; each file gets its own progress card, followed by validation details. The actual restore order is enforced (data first, system second, since the latter restarts the backend); the server-side upload limit was also raised from the 10 MiB default to 60 GB. *(Backend, management interface)*

- **VPN configuration is visible in the interface again after a restore** — After a system backup restore, the VPN settings area stayed empty even though the WireGuard container was running with the right config — the settings live in the ThinForge settings table, which is deliberately excluded from the backup (it holds host-specific values). The backup now writes a separate file containing just the VPN settings, which the restore writes back before the WireGuard container starts — this only works if *both* sides (source and target) run the new backend version. *(Backend)*

- **System backup restore now resets private key permissions correctly** — Sensitive key files (SSH provisioning key, signing key, crypto salt, heartbeat token) were ending up world-readable on the target machine after a restore, because the restore carried over the archive's mode bits — SSH connections from the backend to managed devices (terminal, remote desktop, provisioning) then failed with "permissions too open". The restore now enforces the restrictive mode on every key file explicitly; already-affected boxes need either a repeat restore run or a manual permissions fix. *(Backend)*

- **Backup remembers the source server's DNS name, and restore adds it on the new server too** — After moving a ThinForge server to a new host, already rolled-out devices lost the ability to resolve the server under its old hostname. The system backup now stores the source box's self-referencing hostnames and, on restore, adds them to DNS alongside the new box's own entries — existing devices need no changes; this only works if both sides run the new backend version. *(Backend)*

- **Creating a client now also writes the PXE boot configuration** — When creating a client (via the dialog or CSV import), only the DHCP reservation was written, not the per-device PXE boot configuration — on first boot this produced a 404 when fetching the boot file and the device fell back to the firmware menu instead of starting. Both creation paths now write the PXE configuration with the correct "boot from disk" default directly. *(Backend)*

- **System backup restore now cleans up old DHCP/PXE reservations and assigns fresh values** — Restoring onto a server with a different network topology left stale IP reservations and outdated PXE boot files in place — the DHCP server silently dropped requests from restored devices, and even after that was fixed, devices still fell back to the firmware menu on PXE boot because their boot files were missing or stale. The restore now runs the same per-client provisioning path as manual client creation (old values removed, fresh IP assigned, new PXE config written); the DHCP "Reset leases" button now also clears the old reservations. *(Backend)*

- **"Export keys" button removed from the Backup tab** — The standalone security-key export was an emergency tool for the old backup architecture; since the new system backup already includes every key (encryption, signing, SSH host keys, WireGuard, TLS, license), the separate export became redundant — the tile and its backend endpoint have been removed. *(Backend, management interface)*

- **Setup wizard completion is now idempotent — no more lockout after an aborted prior attempt** — If a previous wizard run aborted between creating the admin user and the final save, retrying with the same account used to fail on a uniqueness conflict and required manual intervention. Wizard completion now cleans up leftover user data itself before creating the admin user — safe, since the wizard is only reachable before setup is complete anyway. *(Backend)*

- **New system backup format v4.0: portable data only, no more host-bound config** — The system backup now contains only what actually makes sense to carry over to a new server box (cryptographic keys, WireGuard config, TLS certificate, license, and a cleaned set of core database records) — reverse-proxy, DNS, and other host-specific configuration, including the source server's network IPs, are **no longer included**. **Important:** old v2.0/v3.0 backups are now rejected with a clear error message; a fresh v4.0 backup must be taken on the source system before a migration. On a new server, the regular setup wizard (network, TLS, admin account) runs first, and only afterward is the backup restored under Settings → Backup & Restore — the wizard itself no longer has a restore step. *(Backend, management interface)*

- **Backend can no longer overwrite the central host configuration file (security)** — The backend container previously had write access to the host's central configuration file, because restoring a backup needed to update the encryption key stored inside it — meaning a compromised container could also have altered the other secrets stored there. The encryption key now lives in its own file the container is allowed to write; the host configuration is mounted read-only. Existing systems migrate automatically on first start, no action needed. *(Backend)*

- **Setup wizard can be completed end-to-end again after a system backup restore** — A restore was inadvertently bringing back the "setup complete" flag too, so the backend rejected every further wizard action from the next step onward — right when the operator needed to adjust network values for the new server. The flag is now explicitly cleared after a restore and set again normally at the end of the wizard. *(Backend)*

- **Caddy now tolerates IP changes from a backup restore without making the interface unreachable** — If the new server's network topology differed from the backup's, the reverse proxy would try to bind a non-existent IP and go down entirely — leaving the management interface completely unreachable from outside (a lockout). Every IP is now checked against the addresses actually bound on the host before binding; missing bindings are skipped with a log warning, and as a fallback the management interface listens on all interfaces so the setup wizard stays reachable. *(Backend)*

- **System backup restore no longer fails with a "resource busy" error on the host configuration file** — If the encryption key differed between the backup and the target server, the restore aborted at the end with an internal error, because the old update pattern (write a temp file, then rename it into place) is refused by Linux on a file that's bind-mounted into a container. The new content is now written directly into the file without renaming — the restore now runs through to completion. *(Backend)*

- **Backup restore accepts the selected file again in both the setup wizard and the Backup tab** — After picking a file, neither the validation view nor the restore button appeared — caused by a behavior change in the underlying file-picker component that two code paths hadn't been updated for yet. Both paths now show the validation display (version, creation date, contents, size) and the restore button again as intended. *(Management interface)*

- **Setup wizard redirects to backup restore after setup is already complete** — Opening the setup wizard URL directly after setup was already complete let you pick a file in the "restore system backup" area, but no import button ever appeared, because the backend rejects all wizard actions in that state without the frontend making that clear. The wizard now redirects straight to the dashboard with a message pointing to the regular restore path under Settings → Backup & Restore, which works for both system and data backups. A factory reset still correctly lands back in the fresh wizard. *(Management interface)*

- **Data backups (clones + deltas) can be downloaded again** — The download button used to load the entire archive into the browser tab's memory before saving it — fine for system backups (hundreds of megabytes), but multi-gigabyte data backups blew past the browser's tab memory limit and the download just hung. The button now triggers a normal browser download with the native "save as" dialog instead, writing straight to disk without holding the whole file in memory; system backup downloads now go through the same path too. *(Management interface)*

- **BitTorrent cache now cleans itself up after deleted clones** — Leftover slices from the cache could accumulate if the backend restarted between the two deletion steps, or if a clone was removed directly on the filesystem instead of through the interface — such leftovers built up unnoticed and could reach tens of gigabytes. Deletion order was reversed (cache first), and a one-time reconciliation on backend startup now detects and removes orphaned cache directories automatically. *(Backend)*

## 2026-05-16

- **Agent v2.9.0: the remote-session indicator is now managed by the agent itself** — The "Remote session active" status box on the client screen is now drawn by the agent binary itself instead of a shell script; behavior (position, size, draggability, automatic disappearance) stays the same. Future improvements to the indicator can now ship via a normal agent self-update instead of requiring every client to be re-provisioned. *(Agent)*

- **Cloning VM startup works again (hotfix for today's services-panel reshuffle)** — After today's refactor moved Caddy, thinVPN, and Guacamole into the "Network" group in the services panel, starting the cloning VM broke, failing with an "invalid compose project" error — caused by a Docker Compose 2.x validation rule that today's original change had overlooked. A small backend fix restores starting, stopping, and building the cloner image for the cloning VM. *(Backend)*

- **Remote Desktop: the session indicator on the client is now reliably shown** — The previous system notification was often barely visible or not visible at all, depending on desktop configuration. A draggable box now appears in the top right showing "Remote session active" for the whole session and disappearing automatically at the end — newly provisioned clients get this automatically, existing clients need to re-run the remote-desktop provisioning once. *(Agent)*

- **Services panel: Caddy, thinVPN, and Guacamole now sort under "Network"** — Purely a display reorganization in the Settings services panel; runtime behavior is unchanged. *(Backend)*

- **Services panel: the Guacamole card now shows the correct status** — The Guacamole container was incorrectly shown as "not found" due to an internal name-matching issue, even though it was running normally. It now shows correctly with status, uptime, and control buttons. *(Backend)*

- **Agent v2.8.1: follow-up fix to the self-heal mechanism** — During live testing of the previously rolled-out VPN self-heal, an automatic TPM reset accidentally deleted the freshly issued tunnel configuration, leaving the agent stuck in an endless retry loop. Clients on v2.8.0 are retried by the backend without lasting harm until they're bumped to v2.8.1 via self-update — no manual action needed. *(Agent)*

- **VPN self-heal: tunnels now repair themselves automatically after key drift** — The server can now tell a client, over the heartbeat, to discard its TPM-sealed VPN key and re-enroll. This resolves two previously manual issues automatically: a device that was deactivated and reactivated but stayed stuck on its old key, and key drift between server and client after internal server maintenance — downtime is now capped at one heartbeat interval. This requires Agent v2.8.0 or newer; the manual reset script on the client is now only an emergency tool. *(Backend, Agent)*

## 2026-05-15

- **Agent v2.7.2: VPN self-healing now works on more Linux variants** — The TPM tunnel now also works on distributions with different binary paths (Ubuntu 24.04+, Arch with the /usr merge), and leftover tunnel configurations are now reliably cleaned up on agent startup. *(Agent)*

- **Agent: VPN route updates now reliably reach TPM clients** — Changes to routed networks in the VPN tab were being written to the wrong config file on TPM-sealed clients, so they never reached the running tunnel; a tunnel restart could also get stuck in a restart loop. The agent now reliably detects the active configuration, cleans up leftover interfaces, and automatically repairs typical drift states on startup; a manual emergency reset remains available for clients already stuck. Rollout: 24h on a test client first, then broadly via self-update. *(Agent)*

- **VPN: route sync failures are now visible** — If the VPS was unreachable while saving VPN routes, this used to only be logged, and the locally saved values silently drifted from the VPS's state. A yellow warning now appears instead: "network routes saved locally, but VPS sync failed." A permanently grayed-out "VPS Sync" button when the VPS was unreachable was replaced with a red alert and a refresh option. *(Management interface)*

- **Remote Desktop: Guacamole bumped to version 1.6.0** — The Guacamole daemon that brokers remote desktop sessions now runs 1.6.0 instead of 1.5.5, with no change to how it's used. Installations without internet access need to fetch the new container image manually once and copy it to the server. *(Server services, deploy repo)*

- **System backup: TLS certificates are now fully included** — The system backup wasn't packing configuration directories recursively, so subfolders were missing from the archive — after a restore this meant the reverse proxy's TLS certificates were missing and had to be reissued, and any explicitly configured custom server certificates would have been lost. Backup and restore now both recurse into subfolders. **Note:** backups created before this update still don't contain the certificate subfolders — anyone relying on an older backup should take a fresh one right away. *(Backend)*

- **Security scan panel: removed an unnecessary hint text** — A technical note about internal scripting and rebuild triggers was removed from below the severity chips in the vulnerability scan panel; not needed operationally, and the panel now looks cleaner. *(Management interface)*

- **Updates tab: progress bar for merge operations is readable again** — The progress bar for merged deltas used to wrap long labels onto two lines and clip them top and bottom, making the status effectively unreadable. The layout now fixed: the bar adapts to the column width, text stays on one line and truncates with "…" when needed. *(Management interface)*

- **Reboot prompt on clients: the "Restart now" button appears again** — When the agent announces a pending reboot to the logged-in user, the default dialog was missing the "Restart now" button — only "Cancel" showed, due to a behavior difference between the two dialog tools ThinForge uses; existing clients always hit the restricted path. Both buttons are now visible in the default dialog (static "in 15 minutes" text); newly installed clients additionally get the nicer tool with a live countdown pre-installed. Existing clients receive the corrected script automatically via heartbeat sync — no agent rebuild needed. *(Agent)*

## 2026-05-14

- **Remote Desktop rebuilt on Apache Guacamole** — The remote-desktop feature (admin connects live to a client's screen), disabled since early May, has been rebuilt from the ground up on Apache Guacamole, an established open-source remote-session stack, replacing the previous in-house streaming mechanism. New: three quality presets (DSL/VDSL/LAN, switchable live during a session), a tray icon on the client indicating an active remote session, and two admins can view the same session simultaneously; Wayland sessions aren't supported yet and are rejected with a clear error. **Requirement:** installations without internet access need to fetch the Guacamole image manually once, and existing clients need to be re-provisioned once so the tools the new session mechanism needs are installed — without that, the system shows a clear error message; leftover packages from the previous solution can stay in place, they're no longer invoked. *(Backend, management interface, Agent)*

## 2026-05-13

- **Clone import: fixed "line name already taken" error on clean systems** — Every clone import attempt failed with "line name already taken," even on a system with no other clones and an empty database. The system was mistakenly comparing itself against its own temporary working directory and reporting a name collision there. Fixed — imports go through again. *(Backend)*
## 2026-05-12

- **Database: migrations merged back into a single file** — Two recently introduced migrations were folded back into the base migration, so the migrations directory holds a single file again. Fresh installs now run in one database transaction and can no longer end up in a half-migrated state. **Warning for running installations on the old migration series:** the backend will reject the migration check with a mismatch on next start; recovery requires manual intervention in the database's migration tracking table, or a wipe (dev setups only) — give advance notice to affected installations. *(server services)*

- **Agent: TLS connection self-heals after certificate errors in one round** — When TLS verification to the server failed, the internally cached certificate pool could go stale under certain conditions and the agent got stuck in an endless loop requiring a manual restart. The agent now unconditionally discards the cached pool after every recovery round — the next heartbeat rebuilds it from the current certificate file. *(Agent)*

- **Signing key rotation: correctly formatted pubkey gets signed** — After a signing key rotation, clients rejected the new key as invalidly signed even though everything was formally correct — the cause was a stray trailing newline in the signed key file. The generation and rotation scripts now normalize the file before signing, so new rotations are accepted cleanly by clients. *(server services)*

- **Signing key rotation: existing deltas get re-signed automatically** — Previously, signing key rotation only re-signed the agent binary and sidecar caches directly; existing update deltas stayed signed with the old key and were rejected by agents as invalid after rotation, so updates stopped coming through. Rotation now automatically re-signs all existing deltas with the new key as well; with very large delta counts this can take a few minutes. *(server services)*

- **TLS certificate rotation: reverse proxy reliably reloads** — After generating or uploading a new server TLS certificate, the reverse proxy was only "reloaded" — since the config file itself doesn't change, it never re-read the new certificate from disk. The HTTPS endpoint kept answering with the old certificate. Rotation now cleanly restarts the proxy container so the new certificate takes effect immediately. *(server services)*


## 2026-05-11

- **SSH key rotation now runs live across clients** — Rotating the SSH key used to manage clients previously required rebuilding the master image and re-provisioning every client. The new key is now signed and pushed to all online clients at the next heartbeat (default 60 s) — rotation runs live in production without touching individual clients. Security companion fix: an unused agent code path that would have accepted an unverified server-supplied SSH pubkey was removed; a certificate companion entry that previously stayed stale after a signing key rotation (forcing manual repair) is now refreshed automatically. *(Agent, server services)*


## 2026-05-10

- **Update chains: merged deltas now attributed to the correct line** — An automatically merged delta (e.g. v001→v003 instead of via v002) was incorrectly shown under "No line" instead of under its image name. The merged delta now inherits the line attribution from its source delta; existing entries were backfilled with a one-time database update. *(server services, management interface)*

- **Cloning section: internal cleanup** — Structural cleanup across the cloning tabs (Create VM, Captures, Clones, Deployments, Updates, Rollback): shared logic was centralized and display formats unified. No visible change in operation, no new features, no action needed — the only cosmetic change is that gigabyte sizes now show two decimal places instead of one. *(management interface)*

- **Defective marking for update versions now works reliably** — Versions that only exist as an update (delta) without their own baseline weren't consistently caught by the "mark as defective" function: they could still be selected as a target in the update assignment dialog, and rolling out through a defective intermediate version didn't force the automatic delta merge. Both are fixed — defective update versions are now hidden in the assignment dialog, and affected deltas are merged automatically. The required database schema extension runs automatically at the next backend start. *(server services, management interface)*

- **Rollback / defective marking: follow-up fixes from lab testing** — The first live test of the "mark version as defective" feature in a group rollback surfaced four problems: a 500 error from the rollback endpoint; the rollback *target* version being marked defective instead of the version being rolled away from (on a test client this deleted the needed snapshot and aborted the rollback with "not enough snapshots"); a rollback scoped to one group affecting clients in all groups; and defective marking landing only in the database, not in the on-disk clone metadata. All four are fixed — the correct version is marked, rollback stays strictly limited to selected clients, and database and clone metadata are updated in sync. *(server services)*

- **Update clones: line name now inherits reliably** — A newly created update clone (e.g. v003) showed up in the Clones tab incorrectly as "Base" instead of under its image line (e.g. Manjaro), because its internal line name was the generic "Update v…". The line's root clone name is now cleanly inherited down to the latest update, with an additional background safeguard. *(server services, management interface)*

- **Deleting a clone now cleans up its markers too** — Deleting a clone marked defective and immediately recreating it with the same version left the defective marker stuck in the database, which the new clone then wrongly inherited. Scheduled snapshot deletions for the version could also keep running and later delete a snapshot that was no longer actually obsolete. Both cleanups now run automatically as part of clone deletion. *(server services)*

- **Updates tab: deltas grouped by line** — The update chain and merged deltas used to sit in one flat list with the line name shown only as a small chip, making it hard to tell which delta belonged to which line when several lines ran in parallel (e.g. Manjaro + Debian). There's now one heading per line with its deltas underneath; legacy entries without a line name land under "No line" at the end. *(management interface)*

- **Agent: acknowledgements no longer lost on heartbeat failure** — When a client's heartbeat failed, already-completed acknowledgements (e.g. "this snapshot was deleted") were still removed from the buffer and lost. The buffer is now only cleared after a successful heartbeat — otherwise the acknowledgements are resent on the next attempt. *(Agent)*

- **New feature: cleanly remove defective versions during rollback** — The rollback dialog now has a "mark version as defective" checkbox (on by default). When enabled: the version is marked defective system-wide and disappears from the selection for new rollouts; running or scheduled rollouts targeting it are aborted and in-progress downloads stopped. Per client, the snapshot of the defective version is automatically deleted after a successful rollback — clients still running the defective version are skipped so a live system is never pulled out from under itself — and a new rollout path that would need to skip a defective intermediate version automatically forces a delta merge. This gives a clean "remove the version, remove all traces" path that previously had to be done by hand on every machine. *(server services, management interface)*

- **Backend: crash after rollout cancellation fixed** — Clicking "Cancel" on a running rollout could occasionally surface a generic "An error occurred" toast in the UI while a backend process crashed internally and other concurrent API calls failed. The cause was a race condition in the delta download stream and the live delta-merge progress stream; both are now robust against duplicate polling. Cancelling now works cleanly without disrupting concurrent requests. *(server services)*


## 2026-05-09

- **Cancelling a rollout now also stops the in-progress download on the client** — "Cancel" previously only set the status in the backend, but the agent kept downloading the delta chunk to the last byte anyway. The transfer can now be stopped directly mid-stream — cancellation takes effect within a fraction of a second and isn't retried. The "Delete" button for an assignment is additionally locked while at least one client is still downloading. *(Agent, management interface)*

- **Updates tab: all client actions now live in the assignment row** — The separate "Client status" section filtered out already-acknowledged clients, so actions like "restart all marked clients" didn't work for the main target group. That section is removed; the expanded assignment row now offers sortable columns, selection checkboxes, and per-client download progress (percent / Mbit/s / bytes). A "Restart / Shutdown" action bar appears as soon as at least one client is marked in an expanded assignment, and works across assignments. *(management interface)*

- **Image lines: duplicate names are caught early** — Two different image lines could previously share the same name, which risked version collisions in the background. When saving a new update or importing a clone, the name is now checked against all existing lines (case-insensitive, trimmed); on a collision the dialog stays open with a red hint. Import also gets a "Rename" field to override the name from the archive directly; existing duplicates are left untouched and must be resolved manually if needed. *(server services, management interface)*

- **Saving an update: visible progress in two clearly named steps** — The "Save update delta & create clone" dialog used to hang for minutes with no visible feedback. Now it shows a spinner with "checking layout" (10–15 s), then closes automatically and a progress bar appears in the "Create VM" tab with "Step 1/2: Generating delta" followed by "Step 2/2: Creating VM clone". Cancel is disabled during step 1 (delta generation can't be cleanly interrupted) and available in step 2. *(server services, management interface)*

- **Clone deletion now only cleans up its own line's delta** — Deleting a clone could, under certain circumstances, accidentally also remove a delta belonging to a *different* image line if both carried the same version number on the same day. The clone's line attribution is now the authoritative identifier — deltas from other lines are no longer deleted along with it. **Note:** already-deleted deltas cannot be reconstructed byte-for-byte — anyone affected can restore the associated clone and generate a new update against the next snapshot as a baseline marker. *(server services)*


## 2026-05-08

- **Update deltas: follow-up fixes around the new versioning logic** — Following the introduction of date-based versions, two follow-on bugs surfaced: a clone created via delta landed in the catalog with a nonsensical version number and was left orphaned on deletion because it never showed up in the confirmation list — version detection now works cleanly. Also, the deltas list in the Updates tab now shows the image line name in bold before the version arrow, so with several parallel lines it's immediately clear which delta belongs to which line. *(server services, management interface)*

- **VPN tab moved to the front of the network section, auto-refresh, more reliable NTP server discovery** — The VPN tab now sits first in the network area and auto-refreshes every 10 seconds, so TPM enrollment hints as well as handshake and traffic values stay current without a manual reload. The "Open Remote Desktop" button in client detail is temporarily hidden, and new clients no longer get the remote desktop dependencies installed automatically during setup. During client installation, the NTP server is now reliably sourced from the ThinForge server — previously, clients in NAT environments could accidentally end up pointing at an invalid address. *(server services, management interface)*

- **Image lines can be named, per-line version counter** — Saving a new image state (baseline) now requires an "Image name" field, letting multiple parallel image lines be distinguished. Each line has its own independent daily counter, so the same day no longer produces two colliding versions. In delta mode (no new root clone), the line name is inherited automatically from the base clone. *(server services, management interface)*

- **Cloning VM: snapshot names now use the date format** — The cloning VM's internal snapshot still used the old version scheme; it now follows the new date format consistent with the versioning change. Nothing changes for day-to-day operation. *(server services)*

- **Hotfix: heartbeats from the rollout network stopped arriving** — Prior reverse-proxy changes had accidentally detached the HTTPS listener from the rollout network — clients without a VPN tunnel on the rollout network all showed as offline even though they were running. The reverse proxy now has its own block dedicated to the rollout network that answers only the API; heartbeats arrive again. *(server services)*

- **Agent v2.6.6: internal efficiency cleanup** — Pure cleanup with no behavior change; existing agents pick it up automatically via self-update. Only noticeable as lower background CPU load and less network activity during an in-progress update download. No action needed. *(Agent)*


## 2026-05-07

- **Management interface no longer reachable over VPN (security)** — The HTTPS listener previously listened on all interfaces, so the management interface was also reachable over the VPN overlay even though the VPN is meant exclusively for agent heartbeats. The reverse proxy is now explicitly bound: full admin access only via the LAN management IP, while only the API is reachable over VPN. **Note for existing installations:** the listener configuration is rewritten automatically at the next backend restart; anyone who configured the stack differently by hand should remove old listener leftovers to avoid a port conflict. *(server services)*

- **Image versioning: switch to date format** — Image versions are now assigned by the system in the format "vYYYY.MM.DD-NNN", with a per-image-line daily counter that restarts at 001 each day — no more manual entry. The capture import dialog gets a new "Image name" field (with an optional description) to keep multiple parallel image lines cleanly separated. **Warning:** existing versions in the old format are marked "outdated" and no longer offered as an update target (they remain visible in version history); the schema change is not reversible, so a database backup should be taken before applying it. *(server services, management interface)*

- **Agent v2.6.4: recognizes the new date-based version format** — Older agents would not have recognized the new date-based version format and would have gotten "lost" by the update mechanism. As of v2.6.4 the agent understands both formats and sorts correctly between them. **Important:** before the first rollout in the new format, all target clients must be at least on v2.6.4 — self-update brings them up automatically, but for clients offline for a long time, check heartbeat status in the dashboard first. *(Agent)*

- **Agent v2.6.3: hotfix — the update actually reaches the client** — In the first end-to-end test of the new download path, the download completed cleanly but the update wasn't applied on the next reboot, because an associated metadata file wasn't downloaded along with it. The agent now pulls it automatically — updates are applied correctly on reboot. *(Agent)*

- **Agent v2.6.2: leaner heartbeat during download + crash detection** — The first live test surfaced three problems: the agent sent a "full" heartbeat during an in-progress update download — unnecessary CPU/IO load exactly when the client is already busy downloading; heartbeats stalled during the multi-minute download, leaving the progress bar empty in the UI; and if the client rebooted or crashed mid-download, the download slot stayed blocked for 15 minutes. Fixed: during a download the agent now sends lean heartbeats carrying only the essentials plus progress; if a download is interrupted by a crash or reboot, the backend detects it on the next heartbeat, frees the slot, and automatically starts a retry (retry count configurable, default 3) that resumes from the last downloaded byte instead of starting over. *(Agent, server services)*

- **Bandwidth control for delta updates** — With many clients pulling a large update at the same time, the internet uplink saturated and other users lost bandwidth — there was previously no limit or throttling. Delivery now runs over HTTPS instead of NFS with clean authentication and seamlessly resumable downloads; a globally configurable limit caps concurrent downloads at 10 by default. Each client also measures latency to the server during download and throttles itself automatically as the line saturates (default cap 10 Mbit/s per client, configurable, 0 = unlimited). The switch is mandatory — agents pull the required self-update automatically at the next heartbeat. *(Agent, server services, management interface)*

- **Backend can now ping / reach VPN clients via terminal directly** — The backend now reaches pure VPN clients (home office, no LAN path) directly for ping and terminal, without going through the VPN container. Firewall logic was extended so reply packets on backend-initiated connections pass through cleanly. **Security model unchanged:** new connections are still filtered; only replies to already-accepted connections pass — no filtering downgrade. *(server services)*

- **Database migrations now run automatically on container start** — New schema migrations previously had to be applied manually, which was untenable for on-site installations. The backend container now runs the migration check itself before every start, automatically detects existing schemas and evolves them cleanly; on failure the backend refuses to start, to avoid an inconsistent state. Updates now roll out through a normal pull-and-restart of the containers, with no manual database work. *(server services)*

- **VPN routes: safe live apply with rollback and status feedback** — When the list of networks routed over VPN is changed in the UI, the agent now checks before activating the new routes whether any of them cover the device's local home network; on a match it refuses and reports back — no self-lockout — and the logged-in user on the device gets a warning dialog. If the tunnel doesn't come back up after applying (no handshake), the agent automatically rolls back to the previous configuration and reports status "rolled_back". Every apply result is reported back on the next heartbeat and shown per client as a colored icon with tooltip in the VPN tab (red for a home-network conflict, orange for rollback or an apply error), so it's visible whether the change has landed across the whole fleet. *(Agent, management interface)*

- **VPN Clients tab: "last handshake" populates again** — The column showed "—" for every entry due to a date format mismatch coming from the central VPN API — the values were never parsed and stayed empty. Fixed — values populate correctly at the next minute-interval sync run. *(server services, management interface)*


## 2026-05-06

- **Terminal button now reaches pure VPN clients too (interim fix)** — The terminal button would hang or fail on connect, especially for pure VPN clients (home office), for two reasons: the VPN IP was passed to SSH with its prefix length attached and didn't resolve as a hostname, and the connection was established from the backend container, which has no path into the VPN network. As an interim fix, SSH now runs via the VPN container, which has direct access to all networks; a proper fix via bridge forwarding followed a day later. *(server services)*

- **Ping button reaches VPN clients again** — Analogous to the terminal problem, the ping button was unresponsive for pure VPN clients because the ICMP packet originated in the backend container, which has no forwarding to the VPN interface. Pings now run via the VPN container and reliably reach both LAN and VPN clients. *(server services)*

- **Agent v2.5.21: "VPN connected" indicator on the dashboard correct again** — Roaming clients incorrectly showed "connected (LAN)" instead of "connected (VPN)" on the dashboard even though the heartbeat went through the tunnel — caused by a separate route lookup that didn't reliably resolve the right answer with multiple server addresses (LAN + VPN) in play. The agent now determines the connection path directly from the connection actually used. *(Agent)*

- **Agent v2.5.20: displayed client IP now matches the actual heartbeat path** — When a client had two paths to the server (LAN and VPN) and one briefly failed, the IP address shown on the dashboard could diverge from the connection actually used. The agent now determines its IP using the same probing process as the heartbeat connection itself. *(Agent)*


## 2026-05-05

- **Agent now automatically reaches the server over LAN OR VPN** — In environments with both a LAN tunnel and a VPN tunnel active at once, the tunnel came up cleanly but the agent could only reach the server via the LAN address — roaming clients outside the LAN had no path at all. The server now hands the agent both addresses (LAN preferred, VPN as fallback); the agent tries the first with a 3 s timeout and automatically switches to the second if needed, within the 10-second heartbeat budget. Existing clients are migrated automatically at the next VPN redeploy; without a redeploy, the second server address can also be added manually. *(Agent, server services)*

- **Agent v2.5.18: security and robustness collective release** — An extensive code review (over 4000 lines running with root privileges) closed four security issues: a self-update signature check that would have accepted an agent binary signed incorrectly, since the check's exit code wasn't validated properly; a certificate-error recovery path that also processed unprotected server fields (SSH keys, tokens, VPN routes) within the narrow window, letting a LAN attacker inject values; a logged-in username that could be crafted to achieve command execution as root; and server-supplied values (filenames, SSH keys, VPN routes) flowing unchecked into root operations. All four are exploitable only via local compromise or a LAN attacker within a very narrow recovery window, and are non-critical on LAN-only deployments — closed as a precaution regardless. Additionally, critical files are now written atomically, TPM enrollment can no longer end up in an unrecoverable hybrid state, and heartbeats now use progressive backoff with jitter on server errors. *(Agent)*


## 2026-05-04

- **Dashboard: new "warranty already expired" tile** — The dashboard now has a fifth tile showing the count of devices whose warranty has already expired (red when greater than zero, otherwise gray). It complements the existing "warranty expiring soon" tile. *(management interface)*

- **Agent v2.5.17: version bump so self-update actually rolls out** — The self-update mechanism compares version numbers as text; after a hotfix tag change, the server and client binaries briefly carried the same version number despite different content, so self-update was skipped. With v2.5.17 the version is cleanly bumped and the update now rolls out to clients. *(Agent)*

- **Dashboard: "View all" in the alerts area opens the right tab** — The "View all" link under active alerts used to land on the default settings tab (user management) instead of the alerts tab. It now opens the correct tab directly. *(management interface)*

- **Agent hostname: cloning artifact silently replaced on first boot** — On every newly installed device, the hostname marker carried over from the cloning VM (based on QEMU's default MAC) triggered a "MAC changed" alert every 24 hours, requiring manual resolution in the dashboard every single time. The agent now recognizes this one-time transition from cloning artifact to real hardware and silently replaces the hostname without raising an alert — the actual identity protection (an alert still fires on a hostname change on already-provisioned hardware) remains fully intact. *(Agent)*


## 2026-05-03

- **Remote desktop: codec switched to H.264, with hardware acceleration where available** — The remote desktop transport codec is switched back to H.264, which delivers noticeably cleaner 1080p images than the previous codec on home-office VPN connections (~2 Mbit/s). The agent automatically picks the best available encoder per session (Intel/AMD hardware first, then NVIDIA hardware, falling back to software); tooling and drivers matching the distribution are installed during client provisioning. Result: lower CPU load on the client during remote control and noticeably smoother playback. Note: H.264 is patent-encumbered — on hardware paths the license is covered via the vendor, while the usual licensing terms apply to the software fallback. *(Agent)*

- **Info area: new "License" tab** — The info area now has a third tab, "License", with the bundled license texts (LICENSE, NOTICE, third-party licenses, written offer for source code provision), expandable per entry and usable without internet access. *(management interface)*

- **Info area: link to the website added** — The info tab now shows a website link to thinforge.org next to the email address, opening in a new tab. *(management interface)*

- **Agent: server TLS certificate now also updated in the client's system trust store** — After a server TLS certificate rotation, the agent previously only updated its own trust anchor; system tools on the client (e.g. browsers) kept distrusting the new certificate until a separate maintenance run caught up. The agent now also updates the system trust store after every certificate rotation (Arch/Manjaro, RHEL, Debian) — browsers and system tools trust the new certificate immediately. *(Agent)*
## 2026-05-02

- **Backup & restore restructured (system + data backup)** — Backups now split into two types: a small, synchronous system backup (database, configuration, VPN keys) and a large data backup that runs as a background job (clones and update deltas). Both can be created, downloaded, and deleted from the Backup tab; the setup wizard only accepts system backups. Restore is now cleanly split — files and database are restored atomically, live data is never deleted before the restore completes, then the affected containers restart in a fixed order. The delta directory is now included in backups for the first time; the previously disabled backup cards are usable again.
  *(Backend, management interface)*


## 2026-05-01

- **Saving updates: multi-subvolume layout is consolidated automatically** — Cloning VMs installed without the preparation step had home, cache, and log in separate Btrfs subvolumes, so updates only captured the main directory — for example, desktop shortcuts created on clients went missing. The system now detects this before taking a snapshot and offers a consolidation step in a dialog that merges the content and removes the separate subvolumes. The update then proceeds normally, and subsequent updates are complete.
  *(Backend, management interface)*

- **Agent: VPN address no longer triggers a "hardware MAC changed" alarm** — On some devices, the agent falsely raised a MAC-change alarm as soon as the VPN tunnel came up, because it mistook the VPN adapter for a physical network card. Hardware detection now asks the kernel directly and sorts physical NICs in a fixed order (wired before Wi-Fi), giving devices a stable identity. **Migration:** devices with multiple wired NICs will report a one-time MAC-changed alarm after the update, which needs to be resolved once in the dashboard; existing alarms from the old error class must also be marked resolved manually.
  *(Agent)*

- **Dashboard: internal error when displaying MAC-change alarms fixed** — When a client reported a MAC change, the dashboard call failed with an internal server error because the server didn't recognize the alarm category. Fixed — MAC changes now display correctly on the dashboard, as does the "version mismatch" alarm, which had the same issue.
  *(Backend, management interface)*


## 2026-04-29

- **Cloning VM: single shared root subvolume instead of split layouts** — Newly installed cloning VMs placed home, cache, and log in their own Btrfs subvolumes, so updates only captured the main directory and the home directory was missing on clients. The installation prep step now writes a single-root configuration so home, cache, and log live as normal directories inside the root subvolume and are captured with every update. **Migration:** cloning VMs installed with the old layout must be reinstalled once, or have their subvolumes merged manually; end clients pick up the fix automatically on their next update.
  *(Tools ISO)*

- **Cloning VM setup: agent binary now updates reliably** — Re-running the prep script on a VM with an already-running agent left the old agent version in place despite a success message, because the running file couldn't be overwritten and the error was silently swallowed. The new binary is now placed alongside and swapped in atomically, restarting the agent service if needed.
  *(Tools ISO)*

- **Tools ISO: agent binary now reliably comes from the current build** — Rebuilding the tools ISO could accidentally pick up an old, checked-in agent version instead of the freshly built one, so newly installed clients sometimes ran noticeably older versions. ISO creation now reliably uses the most recently built binary, including its signature and version file.
  *(Deploy repo)*

- **Client installation: data-partition size now comes entirely from the UI** — Installation scripts used to separately prompt the operator on-site for the data-partition size, even though it's already set in the "Create base HD" UI wizard. The duplicate prompt is removed; the partition script now detects the existing disk state itself and only creates what's missing, leaving existing data partitions untouched.
  *(Tools ISO, management interface)*

- **"Create base HD": distribution dropdown removed** — The wizard's distribution dropdown often didn't match the Btrfs layout the installer actually chose, causing snapshot creation to fail afterward. The field is removed; the system now automatically detects the root subvolume the installer created from the file structure after OS installation. If the disk state changes, detection reruns automatically — stuck installs self-heal on the next attempt.
  *(management interface, Backend)*

- **Version display shows the real version instead of "vdev"** — On freshly deployed servers, the header showed "vdev" instead of the actual date-based version, because the frontend build was missing the source it pulls the version number from. Fixed — the header shows the correct version again after the next frontend rebuild.
  *(management interface, Deploy repo)*

- **Release server: Compose path errors fixed (restart loops)** — On freshly rolled-out release servers, the backend and worker got stuck in a restart loop, the database had no schema, and the setup wizard hung — caused by three unadjusted path errors carried over from the developer Compose setup. Both affected Compose variants are fixed. **Note:** affected installations may need to remove an accidentally created phantom folder and reinitialize the database once before the next deploy.
  *(Deploy repo)*

- **Security audit of all container images, base images updated** — A comprehensive security audit of all container images uncovered critical vulnerabilities in older Docker tooling and Python packages. Fixed via a newer Rust toolchain and updated system packages in the backend image (fixable vulnerabilities reduced from 43 to 3, all critical hits gone), raised package versions in the cloning-VM and BT-seeder images, and freshly pulled external base images (Postgres, Redis, Caddy, Node, Alpine, Go). Remaining findings in build-only Python toolchain components aren't used at runtime and are documented as known and acceptable.
  *(Deploy repo)*

- **Debian clients: rollback entries in the bootloader work again** — Debian clients were missing snapshot entries in the bootloader menu, so rolling back to an earlier snapshot wasn't selectable there — caused by a formatting difference in the standard text tool between Debian and Arch/Manjaro. Fixed: snapshot entries reappear correctly in the bootloader menu starting with the next update.
  *(Agent)*

- **Agent self-update reliably pulls updates again** — Agent self-update was briefly blocked because requests were sent without an auth token and the server rejected them with 403 — visible only at debug log level. Affected clients stayed stuck on their install-time agent version. Self-update and reloading helper scripts now correctly send the heartbeat token. **Migration:** devices running a very old agent version need one manual push of the new binary, or re-provisioning; after that, self-update works independently again.
  *(Agent)*

- **Terminal and remote desktop recognize the login cookie again** — After the switch to cookie-based login, the terminal and remote-desktop dialogs stopped opening and reported "not authenticated." Both dialogs now reliably recognize the login cookie.
  *(management interface)*

- **Clone export: Btrfs layout info now travels with it** — Exporting a clone now writes its Btrfs layout information (distribution, root subvolume) into the archive. On restore, the system immediately finds the correct root subvolume, so the first update-save afterward runs without manual intervention. Older clones without this info still fall back to automatic detection.
  *(Backend)*

- **Single-root layout: follow-up fixes from code review** — Several cleanups around the switch to a single root subvolume: old helper files for the formerly separate subvolumes are now removed automatically on agent update, the delta re-signing script cleans up leftover old delta files, and the manual snapshot management script now also guards against accidentally deleting the active root subvolume on Debian clients. Outdated comments and configuration leftovers in the installation scripts were cleaned up.
  *(Agent, Tools ISO)*


## 2026-04-28

- **Cloning VM: correct layout per distribution, updates carry content again** — On Debian-based cloning VMs, a layout mismatch between the prepared disk and what the Debian installer actually created caused the system to produce nearly empty update files, even though hundreds of MB had been newly installed. Fixed with a distribution choice (Debian/Ubuntu/Mint/Other) in the "Create base HD" wizard that sets up the matching root subvolume, plus a unified root-subvolume model in the backend and agent where the home directory is captured automatically. Disk-size figures are now also consistently base-1024, so a disk created with 60 GB in the wizard now shows as 60 GB in the clone catalog too.
  *(Backend, management interface, Agent)*

- **VPN firewall: peer isolation now works reliably** — The "peer isolation" rule (VPN devices can't reach each other) was written in a form the firewall backend rejected; the error was silently swallowed, so the UI showed it as "on" even though VPN peers could still actually reach each other. The rule is now built cleanly from two separate entries and works as displayed. Firewall commands now also run strictly in sequence and abort immediately on error instead of silently swallowing it; rules are automatically reapplied after every container restart.
  *(Server services)*

- **VPN firewall: live log in the UI** — The VPN tab now has a "Firewall Live Log" showing time, action (accepted/dropped/peer isolation), rule, source, destination, protocol, and port. It refreshes every 5 seconds, with a pause button and manual refresh, letting you watch live which packets hit which rule.
  *(Server services, management interface)*

- **Firewall log: no more duplicate entries after tunnel restart** — After a VPN container restart, the entire old log buffer reappeared in the firewall log, causing entries to multiply. Fixed: the capture now only records new messages after startup, so each event appears exactly once.
  *(Server services)*

- **VPN settings: peer isolation can no longer be disabled** — The "peer isolation" toggle is removed from the VPN settings. The protection is now hardwired and can no longer be accidentally turned off.
  *(Server services, management interface)*

- **VPN: firewall enables automatically on tunnel import** — After importing a tunnel configuration, the firewall previously had to be turned on separately in the UI, or the tunnel ran unprotected. This now happens automatically — peer isolation and the live log are active immediately after the first tunnel import.
  *(Server services)*

- **Heartbeat token: controlled rotation and recovery behavior** — The heartbeat token an agent uses to authenticate to the server is now centrally validated; after a rotation, older tokens are still accepted for a configurable grace period (96 hours by default). The server sends the next valid token along with the heartbeat response, the agent persists it atomically, and a new recovery endpoint lets a token be fetched explicitly if needed. Internal agent endpoints are now consistently gated behind the token check — only the TLS certificate recovery endpoint stays deliberately open.
  *(Backend, Agent)*


## 2026-04-27

- **Scheduled BitTorrent deployments: status updates now arrive** — With the lead-time mechanism for scheduled deployments (the seeder starts up 10 minutes before the scheduled time), the server was discarding status messages from the seeder while the deployment wasn't yet "active" — so the UI kept showing "preparing" even though the seeder was already running. Status messages are now accepted during the lead-time phase too.
  *(Backend)*

- **Scheduled deployments: three-phase flow with lead time and Wake-on-LAN** — Scheduled deployments now automatically run in three phases: 10 minutes ahead, the seeder and torrent are prepared in the background; 1 minute ahead, PXE, NFS, and network preparations are activated; and at the scheduled time, Wake-on-LAN packets are sent — deliberately only after activation, so waking clients don't boot into the old boot target. In the dialog, "send Wake-on-LAN at start" is now a simple toggle instead of a lead-time field, and the worker now detects configuration errors at start instead of failing mid-run.
  *(Backend, management interface)*

- **Scheduled deployments: date and time clearly separated, always server timezone** — The scheduling dialog now has separate date and time pickers (24-hour format). Input is always interpreted in the server's timezone, regardless of where the browser runs, and a live hint shows the resulting UTC time — avoiding timezone mix-ups.
  *(management interface)*

- **Server setup: timezone now asked interactively, time sync ensured** — The setup script used to hard-set the Berlin timezone; it now asks interactively, validated against the Linux timezone list, suggesting the currently configured one. Automated setups without a terminal keep the existing timezone or can set it via an environment variable. Setup also enables automatic time synchronization if it isn't active yet — without correct time, the TLS connection to the agent can fail.
  *(Server services)*

- **Client installation: ISO scripts now found reliably, errors abort the install hard** — The tools ISO's follow-up script was sometimes not found depending on path or invocation method — the install appeared to complete but the result wasn't functional. The search now checks three locations (its own directory, mounted ISO paths, auto-mounting CD drives) and aborts with a clear message on failure. In addition, the installation now aborts hard if the data partition isn't mounted or isn't Btrfs — otherwise the token, certificate, and agent binary could end up on the root filesystem and get hidden by the real data mount on the next boot, leaving the agent starting without its saved state.
  *(Tools ISO)*

- **New diagnostic script for clients** — The tools ISO now includes a diagnostic script that thoroughly checks an installed client VM: mounts, agent binary, configuration, TLS certificate, tokens and permissions, update scripts, relevant systemd units, SSH setup, installed version, and a connectivity test to the server. It ends with a pass/warn/fail summary and a matching exit code for scripted use.
  *(Tools ISO)*


## 2026-04-26

- **Client installation: redundant layout check removed** — Alongside UI-driven disk preparation, the tools ISO had a second, redundant verification layer that could even trigger false errors in certain setups. It's removed — the UI is now the sole source of truth for the layout.
  *(Tools ISO)*

- **Cloning VM: disk-size display now matches the UI input** — The disk size entered in the wizard was calculated differently in the status panel — 60 GB entered showed up as 54 GB. Both now compute consistently, and the "enlarge" function applies the UI value correctly too.
  *(Backend, management interface)*

- **"Create base HD": disk preparation ran in the wrong location** — The wizard's disk preparation accidentally wrote into an empty container directory instead of the real data directory on the server — the wizard reported success, but nothing appeared in the clone area. Fixed: preparation now reliably writes to the storage directory. **Note:** affected "nothing there" states need to be cleaned up manually once and disk creation repeated.
  *(Backend)*

- **Cloning VM: no more accidental disk enlargement on container start** — If an existing disk was slightly smaller than expected when the cloning VM container started, it used to be enlarged automatically — but the partition table stayed unchanged, so the OS installer saw the disk as completely empty and suggested starting fresh. Automatic enlargement on start is removed; disks are now created exclusively through the UI wizard, and a missing disk now aborts the container with a clear error message.
  *(Server services)*

- **VPN firewall: peer isolation introduced as a fixed base rule** — New base rule: devices behind the VPN can no longer see each other (client-to-client traffic in the VPN overlay is blocked). The rule sits at the very front of the firewall chain, so a later, too-broad "allow" rule can't undermine the protection; the appliance itself remains reachable. A toggle in the VPN settings dialog (default on) was removed two days later — the protection has been hardwired ever since.
  *(Server services)*

- **New "Create base HD" wizard in the UI** — The cloning area now has a new wizard for partitioning and formatting the cloning VM's disk and setting up the required subvolumes directly from the UI — previously a manual step in the installer's rescue mode. Input is checked against sensible minimum sizes (system ≥ 4 GB, EFI ≥ 100 MB, data ≥ 1 GB).
  *(management interface, Backend)*

- **Vulnerability scan: overview and detail counts now match** — The overview cell for an image sometimes showed different numbers than its detail list, e.g. "12 critical" versus "1 critical (11 accepted)" in the detail view. Both now compute from the same source, and technical duplicates (the same vulnerability in the same package version at different paths in the image) are no longer counted multiple times — the numbers are consistent.
  *(Backend, management interface)*

- **Vulnerability scan: Postgres and Redis correctly classified again** — Vulnerability findings for the Postgres and Redis images were wrongly landing in the "needs assessment" bucket because the image name was derived incorrectly from the filename. The scan now reads the image name directly from the scan output; the affected CVEs are correctly classified on the next scan.
  *(Backend)*

- **Vulnerability scan: two findings recorded as known** — An availability finding in a telemetry library in the Caddy image (DoS via crafted headers) poses no data leak in LAN-only operation, only a potential availability loss; the fix awaits a Caddy upstream update. A gRPC finding in the BT-seeder image is a false positive, since it only affects the Go implementation, while the image contains the C++/Python variant.
  *(Deploy repo)*

- **Tools ISO: additional install path for Debian netinst** — The lean Debian netinst ISO now has its own companion script. Unlike the live variant, installation runs through the standard Debian installer, and the subvolumes are created manually during the prep step; the final step is identical to the live variant.
  *(Tools ISO)*


## 2026-04-25

- **Navigation: "License" and "Local Network" now appear in the sidebar** — Two tabs that already existed but were missing from the sidebar menu are now visible: Settings → "License" and Network → "Local Network". Clicking in the sidebar now reliably lands on the intended tab.
  *(management interface)*

- **Cloning console: reload button for the VM view** — The console view in the "Create VM" tab now has a small refresh button that establishes a fresh connection to the console — occasional blank console displays can now be fixed without a full VM restart.
  *(management interface)*

- **Clone list: clearer action label** — The "Restore" button in the clone list is now labeled "Restore to VM" — making it clear the target is the running cloning VM's disk, not a selected client.
  *(management interface)*

- **Frontend: stricter build pipeline, correct production image** — The frontend build now strictly checks all TypeScript errors before each new version; warnings accumulated over months were cleaned up in the process. The production Compose variant now builds the frontend image from the actual production path instead of the development path — previously, container restarts could rarely leave open browser tabs pointing at module URLs that no longer existed.
  *(Deploy repo, management interface)*

- **Saving updates: version suggestion now considers existing clones** — The version number suggested when saving an update used to come purely from the running VM's last snapshot — if the snapshot stack had been cleared but clones with old versions still existed, saving would fail with a version conflict. The suggestion now also considers existing clones and picks the next free number.
  *(Backend)*

- **Services panel: BT seeder and multicast senders now shown** — The services panel and Settings → Logs now list the BitTorrent seeder and all active multicast senders, dynamically depending on running deployments. This lets you check status and logs for these helper containers without going through the console.
  *(management interface, Server services)*

- **Reverse proxy: PXE paths only reachable on the client network** — The reverse proxy for PXE and clone-deploy paths on port 80 now explicitly binds only to the client-network IP configured in the setup wizard, instead of all network interfaces. PXE clients keep working as before, while the management network no longer sees anything on port 80 — admin access over HTTPS on port 443 remains unchanged.
  *(Server services)*

- **BitTorrent seeder now binds only to the client network** — The seeder container for BitTorrent deployments used to open its peer and tracker ports on all network interfaces; both now bind strictly to the client-network IP. If the client network is changed in the setup wizard, the seeder container is automatically recreated with the corrected IP.
  *(Server services)*

- **Deployments tab: newly created deployments appear immediately in the list** — Creating a BitTorrent deployment took a few seconds for torrent generation, during which the new entry was still missing from the list — the operator had to manually reload. The entry now appears immediately at the top of the list, with the refresh running in the background.
  *(management interface)*


## 2026-04-22

- **Agent heartbeat: the interval set in the UI now sticks** — The agent internally hardcoded a switch to a 120-second heartbeat interval after two successful heartbeats, overriding the UI setting — setting "every 10 seconds" in the UI would still revert to 120 seconds shortly after. That hardcoded logic is removed; the agent now permanently follows the server-configured value within sensible bounds (10-3600 seconds).
  *(Agent)*

- **BitTorrent deployments: multiple deployments possible in parallel** — The BT seeder now runs as a long-lived service that can offer multiple clone torrents at once — several BitTorrent deployments with different clones to different groups can now run in parallel without issue (multicast remains limited to one per server for protocol reasons). Once no BitTorrent deployment is active, the seeder stops automatically, so peer and tracker ports stay closed outside rollouts. Deployments of the same clone share the same swarm for faster repeat starts, and deleting a clone cleans up its associated cache.
  *(Server services, Backend)*

- **A single deployment can now target multiple groups at once** — The "create deployment" dialog has a new target mode, "multiple groups": the selected groups are combined into one client set and delivered as a single deployment — with multicast, the image is streamed only once no matter how many groups are attached. The deployment list shows one combined entry listing all involved group names.
  *(Backend, management interface)*

- **Deployments: no more ghost entries after activation failures** — If activating a deployment failed (e.g., because PXE setup wasn't possible), the entry used to remain marked "active" anyway, blocking later deployments. On failure, the entry is now cleanly removed and the cause shown in the UI; a failed restart likewise leaves the deployment in its previous state.
  *(Backend, management interface)*


## 2026-04-21

- **New licensing system** — ThinForge now supports a licensing system with a free tier of up to 50 active devices without a license key, at full functionality. License keys are uploaded as a signed, encrypted bundle in the new "Settings → Licensing" tab; if the device limit is exceeded, only new registrations are rejected (HTTP 403), while already-registered devices keep working unaffected. After a license expires, there's a 60-day grace period before falling back to the free tier; limit checks apply to both single device creation and CSV bulk import.
  *(Backend, management interface)*

- **Setup wizard no longer forces itself automatically** — The setup wizard used to be automatically forced on every page load whenever the backend reported it as incomplete — combined with the database persistence bug described below, this could unintentionally overwrite production data. The auto-redirect is removed; the wizard remains manually reachable.
  *(management interface)*

- **Dashboard: disk usage displays correctly again** — After the backend image switched to a leaner base, the dashboard showed disk usage as zero, because the internally used system command didn't support a certain option format there. Switched to a portable format — values display correctly again.
  *(Backend, management interface)*

- **Restoring clones: size display now matches the source** — When restoring a hardware-based base clone captured via the tools ISO, the target disk was wrongly defaulted to 60 GB even though the real size was in the clone's metadata — the resulting disk then didn't match the source's partition table. Both the UI display and the actual creation now use the real disk size from the clone first.
  *(Backend, management interface)*

- **Database persistence fixed (important)** — After a hard, cache-free rebuild or a volume cleanup, the database ended up empty and the setup wizard ran again, because Postgres data was landing in an anonymous, invisible Docker volume instead of the mounted data directory. Fixed: data now lives in a fixed, visible location in the data directory and survives container recreation. **Migration for existing installations:** data needs to be copied once from the old anonymous volume into the new directory, with Postgres ownership adjusted — without this step, a future hard rebuild risks data loss.
  *(Backend, Deploy repo)*

- **Security findings filtered more precisely by reachability** — The vulnerability overview now strictly distinguishes between "not affected" (a reachability filter, e.g., an isolated container) and "affected but marked accepted" (a deliberate decision, e.g., a pending fix). For each image and severity, the original count is shown struck through next to the actually relevant one, an icon indicates reachability (LAN/internal/isolated), and the detail popup breaks findings down by attack vector. The assessment is fully automated by the system.
  *(Backend, management interface)*


## 2026-04-20

- **Services panel now builds automatically from the Compose configuration** — Which containers appear in the services panel is now derived directly from the Compose configuration; display name, icon, and markers like "critical" come from labels on the container. New services now appear automatically once entered in the Compose file, with no backend code change required.
  *(Backend, Deploy repo)*

- **Security scan: container base images updated** — First preparation round for the broader vulnerability audit the following day: external image versions are now managed more flexibly, and critical Python libraries in the cloning-VM image were bumped to fixed versions. The list of permanently accepted, known findings was significantly expanded.
  *(Deploy repo)*

- **Backend container switched to a leaner base (Alpine)** — The backend container now runs on Alpine instead of Debian, cutting image size by about a third (691 MB to 497 MB). All other ThinForge containers use the same leaner base; nothing changes functionally.
  *(Deploy repo)*

- **Complete removal of the old Python backend** — The Python/FastAPI backend tree, which was still lingering in the repository, is finally removed, since the Rust successor has been the sole production stack for a long time. The old production Compose variant and a few dead scripts were removed along with it; operation and functionality remain unchanged.
  *(Deploy repo, Backend)*

- **Monitoring (Prometheus, Grafana) and Ansible runner (Semaphore) disabled** — Prometheus, Grafana, and Semaphore are now disabled in all Compose variants, since they weren't regularly used in production and the Semaphore image also carried many critical vulnerabilities that couldn't be fixed in-house. The data directories remain untouched, so reactivation is possible at any time.
  *(Deploy repo, Server services)*

- **Vulnerability scan: now triggered only via the UI, runs entirely in the backend** — The vulnerability scan now runs entirely from the backend, with no extra setup needed on the host. The only trigger is the "Run scan now" button in the security tab — this keeps scan data state consistent and simplifies fresh installs.
  *(Backend, management interface)*
## 2026-04-19

- **Storage cleanup: BitTorrent data and old scan results are cleaned up too** — The internal cleanup script now also removes orphaned BitTorrent helper data (which could grow to several GB after a database reset) and stray vulnerability-scan directories left over in the old project path. Neither was cleaned up automatically before. *(Server services)*

- **Container base: full move to Alpine 3.22** — All ThinForge containers (BitTorrent seeder, cloner, dnsmasq, multicast sender, cloning VM, plus Chrony/NFS/WireGuard) now run on the leaner Alpine 3.22 base — much smaller images (e.g. cloner 200→86 MB, multicast sender 138→25 MB, BT seeder ~700→242 MB), no functional change. The Go toolchain used to build the Agent was also updated, fixing all known Go standard-library vulnerabilities in the Agent binary. *(Server services, Agent)*

- **Vulnerability scan: data now lives in the central data directory** — Vulnerability-scan results now live in the central data directory instead of the project directory, matching the convention for runtime data. Starting a new scan now automatically cleans up old results, preventing the previously observed multi-GB growth; usage is unchanged. *(Backend, server services)*

- **Frontend: library updates (security)** — Several frontend libraries (including axios, vue, vuetify, the MDI font, pinia, vue-router, vue-i18n, jsbarcode, sass) were bumped to newer patch versions that fix known security issues. Larger version jumps are deliberately deferred to avoid extra testing effort. *(Management interface)*

- **Reverse-proxy configuration: a single source** — The reverse-proxy configuration could previously be written from three different places, two of which lacked the required PXE paths — running the setup wizard or regenerating the TLS certificate after a rebuild could silently install the broken variant, causing PXE clients to fail with "BOOT FAILED!". The configuration now comes from exactly one file in the repository, is reviewed like code, and is applied unchanged during setup; the setup wizard and certificate generation no longer write it themselves. The "remove certificate" button has been removed — TLS is now always on. *(Backend, management interface, server services)*

- **Deployments tab: BitTorrent preparation phase is now visible** — During a BitTorrent deployment, the status chip used to briefly jump to "active" while the seeder was still extracting data, creating torrents and starting trackers — causing UI flicker. The status now correctly shows "Preparing…" with an orange bar until the seeder is actually distributing, then switches to "Active". *(Management interface, backend)*

- **PXE delivery: via the central reverse proxy instead of a helper web server** — Delivery of PXE boot files (notably the ~400 MB boot filesystem image) previously ran through a small helper web server in the DNS/DHCP container that spawned a new process per connection — a real bottleneck with 100+ devices booting in parallel. The central reverse proxy now handles delivery efficiently and asynchronously with kernel optimizations and RAM caching (50 parallel requests in 35 ms in testing); the helper web server has been removed, and the DNS/DHCP container now only handles DHCP and TFTP. *(Server services)*

- **BitTorrent deployment: torrent files are now placed where clients can see them** — In the first successful end-to-end BitTorrent deployment, clients got a "404 not found" when fetching the torrent file because the seeder wrote it to a different directory than the one clients fetched from via the web server. The file is now also mirrored into the correct directory and automatically cleaned up again once the deployment finishes. *(Server services)*

- **Security: new SBOM download in the UI** — The security area now has a new "SBOM download" sub-tab that lists all existing scan runs with timestamps and offers the three standard software-bill-of-materials formats (Syft, CycloneDX, SPDX) per run — either as an individual file per container or as a complete archive. This makes it possible to generate software bills of materials without server access. *(Management interface, backend)*


## 2026-04-18

- **Agent v2.5.3: TLS certificate sync + reinstall improvements** — The Agent now regularly pulls the server's TLS certificate and updates its local trust store automatically, so certificate rotations take effect without re-provisioning every device. Reinstall tasks now also push the server certificate, signing key and heartbeat token alongside the Agent binary, so a freshly reinstalled Agent is immediately ready. Package installation was removed from the Agent's startup sequence, since a hanging provisioning script (e.g. without internet access) used to block the entire heartbeat loop; subprocess aborts also now reliably kill all child processes. *(Agent)*

- **Cloning VM: live progress display for cloning is back** — When creating a clone, the progress indicator used to sit at 0% for minutes and then jump straight to 100%, with no live feedback. The backend service now reads a status indicator during the operation and reports progress to the UI as a percentage, matching how restores already worked. *(Backend, management interface)*

- **DHCP/NFS authorization: now strictly IP-based, no token required** — Authentication for internal DHCP lease notifications now relies purely on network topology instead of the previous shared-secret token, which has been removed: the backend now listens only on loopback, the reverse proxy blocks the DHCP endpoint from outside access, and the DNS/DHCP container can only reach the backend via loopback — security now comes from the topology instead of token management. At the same time, the reverse proxy for PXE callbacks was fixed, so previously stuck multicast deployments work again. *(Backend, server services)*

- **Security audit: critical findings fixed** — Several critical findings from the internal security audit are now closed: the publicly reachable heartbeat-token endpoint (letting anyone on the LAN fetch the shared client token without authentication) has been removed — the Tools-ISO and clone images are the official provisioning sources; callback tokens for clone deployments are now checked strictly instead of treating empty/missing values as "no token needed" (403 without a valid token). Setup-wizard restore paths are locked down after setup completes and only run through the authenticated admin path, and the Agent now refuses to start if the server certificate or signing key is missing locally instead of silently accepting a value suggested by the server — trust anchors now come exclusively from the Tools-ISO or clone image. The backend and all admin tools are now reachable only via loopback or SSH tunnel, the changelog dialog is hardened against XSS, and the curl-based bootstrap mode has been removed. Requires a mandatory rebuild of the backend container, Agent binary, and Tools-ISO. *(Backend, Agent, management interface, deploy repo)*

- **Security audit: further hardening (follow-up bundle)** — Further hardening from the same audit (severity "high"): login/auth endpoints are now rate-limited (5 requests/second with a short burst allowance, currently still a shared LAN-wide quota behind the reverse proxy). Logged-out access tokens are now blacklisted immediately instead of remaining valid for up to 15 minutes after logout. The hardcoded default Semaphore admin password has been removed — a secure random password is generated the first time the environment is set up. NFS shares are now granted strictly per client IP instead of for the whole subnet (deny-by-default when no client IPs are known). *(Backend, server services)*

- **NFS shares now only appear at actual boot time** — NFS shares for pending tasks used to be created "just in case" across the entire subnet. Now each client gets a reserved DHCP IP as soon as it's created, and on every real DHCP lease event the backend checks whether a task (capture, deployment, update) is currently pending for that client and enables the matching share just-in-time for that single IP — no share is left open "on spec" anymore. Re-exporting the shares also no longer automatically force-restarts the container (which used to abort in-progress transfers); the error is now logged instead and the operator decides manually. *(Backend, server services)*


## 2026-04-17

- **BitTorrent data: its own subdirectory in storage** — BitTorrent helper data for clone distribution now lives in its own subfolder in the data directory instead of being mixed in with the PXE boot files. Cleaner separation, no change in usage. *(Server services)*

- **VPN remote: protection against accidentally deleting the main server** — The VPN remote-sync area had a "delete" button for every peer on the VPN server, including the server itself — clicking it would have severed the connection to itself. The delete button for the main server is now replaced with a shield icon and tooltip, and the backend additionally rejects any attempt to delete it. *(Management interface, backend)*

- **Navigation: "Automation" entry hidden from the sidebar** — The "Automation" entry in the sidebar is now hidden, matching the automation tab in the client view, which has been inactive for a while. The code remains in place for later reactivation. *(Management interface)*

- **Clients tab: refresh button in the filter row** — The client list's filter row now has a small refresh button at the far right for manually refreshing the list. Automatic background refresh continues to run unchanged. *(Management interface)*

- **Cloning tab: info hint about the optimized system** — The heading in the cloning tab now has an info icon with a tooltip noting that the system is optimized for Debian/Manjaro XFCE, and a minimal installation is recommended for production systems. *(Management interface)*

- **Agent heartbeat interval configurable centrally** — How often Agents check in with the server can now be set centrally in the Agent tab (range 10–3600 seconds). Devices automatically pick up the new value on their next heartbeat. *(Management interface, agent)*

- **Signing: "Sign" button in the Agent tab + rotation now covers the Agent binary** — The Agent tab now has a dedicated "Sign" button next to the upload button that signs only the Agent binary (label/color reflect the signature status). When the signing key is rotated, the Agent binary is now automatically re-signed as well — previously it could be left behind with a stale signature after a rotation, which would have made the Agent's self-update fail silently. The signature status view also now shows whether the Agent binary is present and which version it is. *(Management interface, backend)*

- **Device hostname on clients: unified "TF-<MAC>" format** — The Agent now consistently sets devices' OS hostname to "TF-<MAC>", derived from the physical LAN MAC address. The canonical name is stored in the device's data directory, survives updates, and is re-applied after every update; if the hardware MAC changes (e.g. a NIC swap), the stored name stays stable and the Agent raises a "MAC changed" alert. Devices with the old "PC-<MAC>" name are automatically renamed on the next schema update. *(Agent, backend)*

- **VPN: TPM-sealed WireGuard keys (first version)** — On devices with TPM 2.0, the private WireGuard key is now sealed inside the TPM — plaintext only exists briefly in RAM while the tunnel is being established, substantially improving protection of the VPN key against disk theft. The Agent handles sealing, unsealing, and installing the required TPM tools itself, driven via the heartbeat; devices without a TPM continue running with an unsealed key and are flagged with a warning icon in the UI. Deliberately out of scope for this first version: PCR binding and LUKS disk encryption. *(Agent, management interface)*

- **Security tab: new vulnerability-scan panel with a live trigger** — The security tab now offers a direct vulnerability scan in the UI: the number of findings by severity per container image, expandable into a CVE list with fix status and affected package (CVE IDs link to the NVD database). A "start scan" button triggers a new scan directly from the UI, shows progress, and automatically reloads the table when done; only one scan can run at a time. *(Management interface, backend)*

- **Database migrations consolidated** — Several incremental schema additions from recent days (invoice fields, TPM status fields, hostname renaming, a new alert category) have been merged into the original schema file, so fresh installs run through in a single transaction. Existing databases are already up to date — no action needed. *(Backend)*


## 2026-04-16

- **Devices: new "invoice number" and "supplier" fields** — Devices can now optionally record an invoice number and a supplier, visible in the device detail view and the create form. CSV import accepts several column-name variants, and export appends both columns at the end; the values are deliberately hidden in the device list and the warranty overview, serving mainly as a lookup aid for warranty claims. *(Management interface, backend)*

- **Groups: resetting a subgroup to root level now possible** — Editing a subgroup previously offered no way to remove its parent reference — it stayed stuck in its hierarchy. Saving now explicitly accepts "no parent", moving the group to the root level; the same fix applies to the description field. *(Management interface, backend)*

- **Setup wizard: backend and worker are restarted after completion** — After the setup wizard, previously only the reverse proxy was restarted — the backend and worker kept running without the newly generated keys until an operator intervened manually. Both are now automatically restarted a few seconds after the wizard finishes and cleanly pick up the freshly generated keys and tokens. *(Backend, server services)*

- **Clone tree: self-repair and clearer tree display** — If a clone that was the "parent" of another clone was deleted, the orphaned reference used to remain as a broken tree path. The system now detects this automatically and repairs the tree by making the lowest version in each version line the new base; the clones tab also now shows classic tree characters for clearer visualization of branches. *(Backend, management interface)*

- **Client installation: Tools-ISO is now found even with KDE auto-mount** — On some Linux desktops (especially KDE on Debian), the Tools-ISO gets auto-mounted at a path that was previously missing from the installation scripts' search list — as a result, the Agent installation was silently skipped and the device came up half-installed. The path has been added; installation now completes reliably on KDE hosts too. *(Agent)*

- **PXE server IP can now be changed at runtime** — Saving a partial setup-wizard configuration with an empty rollout IP and filling it in later used to leave a stale cached empty IP — every clone deployment afterward failed with a cryptic error until the backend was restarted. The IP can now be updated at runtime, empty values are ignored and flagged in the log, and the backend now also logs a clear warning at startup if no IP has been set yet. *(Backend)*

- **Worker health check now actually works** — The worker container's health check had permanently reported "unhealthy" ever since it was introduced, because it checked a file nobody ever wrote. The worker now signals liveness by regularly touching a marker file; if that file goes untouched for more than a minute, the container switches to "unhealthy" — a real liveness indicator instead of a constant false alarm. *(Server services, backend)*


## 2026-04-14

- **ISO download: more reliable and less memory-hungry** — Downloading an ISO image could previously fail internal address resolution against mirror servers with multiple A/AAAA records, aborting the download — that's fixed. The image is now also streamed directly to disk during download instead of being buffered entirely in RAM, easing memory pressure for multi-GB images; the progress bar now updates live, and partial files are cleaned up properly on error. *(Backend)*

- **Dashboard: on-demand containers no longer shown as a warning** — Cloning containers that only run on demand (e.g. the cloning VM, the cloner) were shown as "not active" among the warning entries on the dashboard's services card, even though being stopped is their normal state. They're now marked as on-demand: on the services card they no longer show as a warning while stopped normally, and in the services panel they get a neutral gray border with an "on-demand" label; unexpected states like "restarting" are still shown. *(Management interface, backend)*

- **Changelog display in the UI works again** — Clicking the version number in the header used to show "No changelog available." instead of the change list, because the file wasn't included in the backend image. The changelog is now bundled into the backend image at build time and shows up directly in the UI. *(Backend, management interface, deploy repo)*


## 2026-04-13

- **VPN: first fully working release (statistics, deploy, status, restore)** — Major functionality push around VPN: a new tab for per-client traffic statistics with resilient sync; VPN deploy/undeploy now work end to end (client creation, deploy button, automatic tunnel restart after a config push, undeploy on client deactivation); detailed VPN status chips in the client table; the tunnel is now reliably re-established after a delta update; VPN detection in the Agent is corrected (checks the right interface and actual route); and recurring "statistics not yet available" messages are no longer shown as error toasts. Shipped alongside Agent v2.5.2 and v2.5.3. *(Backend, management interface, agent)*

- **Network: local network configurable in the UI, dnsmasq maintains its own domain** — The network area now has a "Local Network" tab for configuring the server's network interface. The PXE server IP no longer comes from a configuration file but directly from the database (falling back to the gateway IP); the setup wizard now also maintains a local domain for the internal DNS server, and external addresses are resolved via the management gateway instead of a hardcoded external address. *(Management interface, backend, server services)*

- **Factory reset: complete instead of selective** — The factory reset previously failed to clear seven tables related to update rollouts and rollback tasks. Instead of a manual list, the reset now dynamically clears all tables, so it stays consistent automatically as the schema evolves, and it also flushes Redis caches (token blocklist, rate limiter, sessions) and the entire storage directory. The server key is now generated and stored automatically on first start, is deleted along with a factory reset and freshly regenerated on next start, and is restored again by backup/restore. *(Backend)*

- **Various smaller fixes** — A device's PXE configuration is now properly cleaned up on deletion (it used to be left behind); VM settings are now correctly carried over during clone capture (the 64 GB default-size bug is fixed); the server-prerequisites setup script no longer has duplicate variable definitions and sets the timezone to Berlin; the timezone setting has been removed from the UI since it never affected the host system anyway; the logs view now shows three previously missing containers (Semaphore, cloning VM, cloner); internal data migrations have been consolidated for clarity. *(Backend, management interface)*


## 2026-04-12

- **Backup system: validate and restore now working** — Backup archives can now be validated before restore and fully restored. The archive format covers the manifest, all configuration directories (SSH, VPN, dnsmasq, NFS, Chrony, reverse proxy, signing), the encryption key, and optionally images, clones and captures; database restore uses the standard tool, and the corresponding paths are also active in the setup wizard. *(Backend, management interface)*

- **Maintenance windows fully on the new backend** — The 5 API endpoints for managing maintenance windows have been ported — all 41 API endpoints now run fully on the new backend. The separate older compose file for the previous backend is gone; the standard start command now directly launches the current backend. *(Backend, deploy repo)*

- **Clones actually shrink after uninstalling software** — After removing software inside a clone snapshot, clones stayed the same size because the internally freed data blocks weren't yet finally registered as "free" at clone time and were still counted as used. The synchronization step now explicitly waits for that — clones actually shrink after software is uninstalled. *(Backend, server services)*

- **Security: signature verification now rejects updates without a key** — If the local signature-verification key was missing on a device, the Agent used to silently accept updates anyway — it now rejects them, since a missing key is an error condition, not something to wave through. The backend also no longer crashes when a key path is invalid; it now returns a clean error instead. *(Agent, backend)*

- **Stability: no more server crashes from internal lock conflicts** — An internal class of locking mechanisms could put the server into an unrecoverable state when an error occurred. These locks have been replaced with a more robust variant, so the server now survives the corresponding error paths without crashing; a slow code path in rollback management was also reduced from thousands of database queries to a single one. *(Backend)*

- **Internal improvements** — A global timeout for API requests (30 seconds, with exceptions for deliberately long operations like backup or clone creation); log rotation for the backend and worker containers (50 MB per file, 3 rolling files); the database connection pool size is now configurable via environment variables; an automatic cleanup step removes the Docker build cache after every rebuild; frontend errors that are already surfaced by the global error mechanism are now documented consistently and traceably. *(Backend, management interface, deploy repo)*


## 2026-04-11

- **NFS shares: capture jobs work again, cleanup runs correctly** — When starting a clone capture, the NFS share for captures failed to appear — Clonezilla reported "Access denied NFS" and aborted. The share is now automatically enabled when a capture starts and cleaned up again once the rollout finishes, and its status survives container restarts; the associated capture job is also now correctly created in the database, so progress is trackable in the UI. *(Backend, server services)*

- **DNS preview in the UI extended to the hosts file** — The DNS panel's preview now shows the file with custom DNS entries alongside the main configuration. The DHCP configuration preview also now loads immediately on first click instead of staying empty. *(Management interface, backend)*

- **Security: shell-call input hardened, ISO downloads protected against SSRF** — Values that flow internally into shell calls or PXE scripts are now strictly validated (allowed characters, maximum length) — manipulated input can no longer inject arbitrary commands; version strings are now checked right at the API boundary. The Agent no longer falls back to "skip TLS verification" during self-update and script download, instead insisting on the pinned server certificate, and the backend's ISO download is now protected against SSRF attacks (DNS is resolved up front, private addresses are blocked, and redirects to internal hosts are rejected). *(Backend, agent)*

- **Agent management: "Reinstall" button** — The Agent tab now has a "Reinstall" button with a selection dialog (all / group / individual devices). Reinstall skips the offline filter and sends the task to the selected devices immediately, without waiting for the next heartbeat; the same dialog is also used for regular updates. *(Management interface, backend)*

- **Agent binary: correct version is now served** — The endpoint through which devices fetch their Agent binary was incorrectly serving an old version from the Tools-ISO directory instead of the current one from the build directory — resulting in an endless update loop. The current build directory is now searched first; an unknown device IP is also now derived from the DHCP lease file before falling back to the hostname. *(Backend, agent)*

- **DNS / Docker containers: service resolution fixed** — The internal DNS configuration was reading the wrong field, causing IPv6 queries for local hostnames to be forwarded to external servers instead of being answered directly with "no data" — leaving the Agent stuck in timeouts; that's fixed. The backend and worker also had their own DNS directive that bypassed Docker's internal DNS, so internal service names could no longer resolve and the reverse proxy fell back to the external IP and failed — that directive has been removed and internal resolution works again. *(Backend, server services, agent)*

- **Client migration: Avahi no longer blocks DNS queries** — Clients' DNS resolver had Avahi (mDNS) hooked in ahead of DNS in a way that blocked DNS queries. An Agent migration step now reorders this so DNS takes priority. *(Agent)*

- **BitTorrent deployment: correct partition count in the UI** — During a BitTorrent deployment, the UI showed the partition count as 0 even though the seeder already had several torrents ready. The value is now correctly reported by the seeder and shown in the UI. *(Management interface, server services)*

- **Cloning VM: no more race condition between clone capture and saving updates** — Saving an update or merging deltas while the cloning VM was still running used to cause cryptic disk errors. The backend service now explicitly checks whether the VM is still running and reports a clear error instead of a confusing internal failure. *(Backend, server services)*

- **Setup wizard: defaults, automatic DNS/NTP population, visible countdown** — The setup wizard is now noticeably more user-friendly: the admin account and domain are sensibly pre-filled (password stays blank); upstream DNS and DHCP DNS servers are now populated from detected defaults only after the network interface is selected, instead of hardcoded external addresses; the upstream NTP server and DHCP domain are now automatically carried over from earlier steps. The layout is tidier on narrow screens, and after setup completes, a visible 10-second countdown with a progress ring runs before switching to HTTPS — giving the reverse proxy time to load the fresh certificate. *(Management interface, backend)*

- **Various smaller fixes** — A database error in a group's client list is fixed (it now uses the same clean query helper as the main tab); the Agent tab opens directly via its URL parameter again; deleting a clone is no longer blocked by a running VM (the warning is now purely informational, with no extra confirmation checkbox); and the Agent build's signing step now completes cleanly (a permissions issue on the build directory is fixed). *(Backend, management interface, deploy repo)*


## 2026-04-10

- **Rollback feature: fully caught up with the current backend** — The rollback feature is now fully implemented on the current backend, with several follow-on bugs fixed: the UI route didn't match the backend, so the rollback tab wouldn't load; various status values had formatting issues in the database; a heartbeat race condition meant version changes weren't detected. Rollback tasks are now automatically marked "completed" once all affected devices are done, and the list now cleanly shows "?" instead of blank fields for deleted devices. *(Backend, management interface)*

- **Rollback: detects available snapshots on devices** — On rollback, boot now creates a writable snapshot of the target version's home directory, instead of always mounting a generic home that could be on the wrong version. The Agent now reports the snapshots available on the device in its heartbeat; the rollback dialog can now pick from these instead of only the installed version, and orphaned temporary snapshots are cleaned up when updates are applied. *(Agent, backend, management interface)*

- **New Agent management tab** — The devices area gets a new "Agent" tab: an upload button for a new Agent binary (automatically signed, version number read out), an update task sent to all devices on an outdated version (applied via SSH at the next heartbeat: stop, replace, start), a status view with aggregated progress and per-device status, plus a new "Agent" entry in the sidebar. *(Management interface, backend)*

- **Clone and delta are now correctly linked** — When creating an update also produced a clone, the link between clone and delta wasn't being recorded in the database. That link is now set correctly, and the deletion-impact analysis for a clone is now fully implemented: it shows incoming/outgoing deltas, devices on that version, active rollouts, and VM status; deletion respects the delete-deltas flag, blocks on active rollouts, and can trigger a device rollback if needed. *(Backend, management interface)*

- **BitTorrent deployment: seeder key is now generated** — Creating a BitTorrent deployment used to skip generating the internal key for the seeder container, causing it to crash immediately. The key is now generated reliably — deployment creation now completes cleanly. *(Backend, server services)*


## 2026-04-09

- **Update rollouts start reliably again** — Creating a new update rollout used to crash the backend with an internal type error, making it impossible to start rollouts. The internal status fields now use a type-safe representation and the crash is fixed; a device whose signature check fails is now also counted as the terminal state "signature failed" — previously rollouts would hang in the "active" state forever in such cases. *(Backend)*

- **Keys and tokens now live in the data directory (no longer in the repository)** — Several runtime keys and tokens (SSH keypair, heartbeat token, signing public key) have been removed from the repository and are now managed exclusively in the data directory. On backend startup, key existence is checked and any missing keys are generated immediately, so the first heartbeat on a fresh system finds a valid token right away. If only one half of a keypair exists (e.g. after a partial restore), startup now aborts with a clear error instead of silently generating a new key and overwriting the half already provisioned on devices; a previously existing path mismatch for the heartbeat token is also fixed, so heartbeats are accepted again. *(Backend)*

- **Setup wizard generates the signing keypair automatically** — The setup wizard now automatically generates the update-signing keypair at the end and copies the public part into the next Tools-ISO build. This required bundling the necessary signing tool directly into the backend image — previously signing failed silently because the tool was missing. *(Backend, deploy repo)*

- **TLS certificate: rotatable during live operation** — A new mechanism for the server TLS certificate: the Tools-ISO signing key is the root of trust, and the TLS certificate is delegated from it and can be rotated at any time. Agents remember the hash of their current certificate and send it with every heartbeat; if the server detects a stale certificate, it sends the new one along, signed, and the Agent verifies the signature and swaps the certificate in atomically. On a freshly installed device, or when the pinned anchor is stale, a one-time recovery path runs where the signature is still verified — a man-in-the-middle cannot inject a forged certificate. *(Agent, backend)*

- **Cloning: progress display during restore + persistent VM settings** — During a clone restore, the progress indicator used to jump straight from 0% to 100%; it now updates continuously throughout the restore. In addition, the cloning VM's RAM, CPU count, disk size and virtualization acceleration setting are now persisted with the clone after a successful start — previously these were lost on every backend restart or container rebuild, and they now survive and are automatically applied on the next restore. *(Backend, management interface)*

- **Rust migration: delta-rollout bugfix + tech-debt refactor** — Internal follow-up fix for the Rust migration: update-status fields now consistently use type-safe enums instead of a text-cast workaround that used to crash when creating a rollout. In addition, a client whose signature check fails is now correctly counted as a terminal state — previously this case was ignored by the rollout-completion check, so affected rollouts were never recognized as complete and stayed stuck at "active" forever. The wire format is unchanged. *(Backend)*

- **Runtime secrets: fully moved to the data directory** — Internal follow-up fix: runtime secrets (SSH keypair, heartbeat token, signing public key) are now completely removed from the repository and canonically live in the data directory. They're now generated right at backend startup instead of lazily on first access, so the first client heartbeat on a fresh system immediately finds a valid token; if only one half of a keypair exists, this is now treated as an error instead of silently regenerating and overwriting the half already provisioned on devices. A path mismatch for the heartbeat token that had been rejecting every heartbeat request with a 403 is fixed. *(Backend)*

- **Setup wizard: automatic minisign generation** — Internal follow-up fix: the setup wizard now automatically generates the signing keypair when setup completes, and the Tools-ISO rebuild that runs when the cloning VM starts automatically copies the fresh public key into the ISO, so clients receive it via trust-on-first-use on their first boot. The required signing tool is now baked directly into the backend runtime image — previously key generation failed with a "file not found" error and delta signing was completely broken. *(Backend, deploy repo)*

- **Certificate rotation (new)** — A new trust chain for the server certificate: the Tools-ISO's minisign key is the root of trust, and the TLS certificate is delegated from it and rotatable. Clients pin the certificate and send its checksum with every heartbeat; if it differs from the server's certificate, the backend sends the new one along, signed, and the Agent verifies the signature and swaps it in atomically. On the first heartbeat after a fresh install, or when the pinned anchor is stale, a fallback kicks in that still enforces signature verification — a man-in-the-middle cannot inject an invalid certificate in that gap. *(Agent, backend)*

- **Cloning: restore progress bar + persistent VM settings** — Internal follow-up fix: a background task now reads restore progress every two seconds and updates the display, instead of the UI bar jumping straight from 0% to 100% only at the end of the operation. In addition, RAM, CPU count, disk size and KVM acceleration are now persisted with the clone after a successful VM start rather than being kept only in volatile memory — the values now survive backend restarts and container rebuilds and are automatically reapplied on the next restore. *(Backend, management interface)*
## 2026-04-07

- **Personal settings moved out of the admin area** — Change Password and Two-Factor Authentication (2FA) have moved from the admin Security tab into a dedicated Profile view, reachable from the account menu at top right. This gives every role — not just admins — its personal settings in one logical place. The Security tab now only shows system-level topics (TLS, Remote Desktop, update signing). *(management interface)*

- **Password reset by email and admin reset** — The login page now has a "Forgot password?" link that emails a reset link valid for 15 minutes, shown only if SMTP delivery is configured. The link is tied to the current password hash, making it automatically single-use. In addition, admins can reset passwords for Operator and Viewer accounts in user management and disable two-factor authentication for individual users. *(Backend, management interface)*

- **Cloning: fixed a hang on "Save update delta"** — Triggering the "Save update delta & create clone" workflow could leave the backend permanently stuck on an internal lock (deadlock). Fixed — the call now completes reliably. *(Backend)*

- **Remote Desktop: switched video codec to VP8 (royalty-free)** — Remote Desktop streaming now uses the fully royalty-free VP8 video codec in a WebM container, with settings tuned for real-time, low-latency transmission. The browser automatically picks the matching WebM format. *(Backend, server services)*

- **noVNC now runs through the reverse proxy** — Access to the cloning VM console via noVNC previously used a separate port not covered by the reverse proxy. All noVNC traffic now goes through the reverse proxy's regular HTTPS path — clean TLS termination, no extra port required. *(server services, deploy repo)*

- **Managed agent scripts: consistent category naming** — Helper scripts managed by the Agent are now distinguished by category: operational scripts, scripts that run automatically on the thin client whenever their content changes, and scripts that are only available for download but never run automatically. As a result, future script updates (such as the VP8 codec switch above) are automatically rolled out to existing thin clients. *(Agent, deploy repo)*

- **UI adjustments** — The Maintenance Windows tab is temporarily hidden (not yet production-ready). There's a new "Rollback" sidebar entry under Cloning, and the indentation of sidebar sub-items was tweaked for readability. *(management interface)*

- **Client data import via CSV: group assignment is now applied** — The exported `clients.csv` already included the group column; on re-import it is now evaluated, recognizing common header names such as gruppe, group, or groups. If the CSV references groups that don't exist yet, a dialog asks whether to create them automatically — on confirmation the devices are assigned right away. *(Backend, management interface)*


## 2026-04-06

- **Devices stay usable during a rollback (overlay boot)** — During a rollback, the system on the devices now boots with a temporary writable overlay, so the user can keep working while the rollback mechanism resets the root subvolume to the target snapshot in the background. Works on both Manjaro and Debian; the Agent reports the boot mode ("overlay" or "normal") back via heartbeat. The home directory also stays writable during an overlay boot, so login no longer fails on missing write access. *(Agent)*

- **Install scripts: image rebuild now runs last** — The install scripts for cloning VMs now rebuild the initrd only at the very end, after all package updates and cleanup — ensuring all kernel updates are correctly included. *(deploy repo)*

- **Cloning: no more NBD collisions between parallel operations** — Multiple cloning operations (merging deltas, saving an update) internally shared the same block device without mutual locking, which could cause undefined disk errors under concurrent clone creation. These operations are now properly serialized; if a clone operation is already running, a second one is aborted immediately with a clear message. *(Backend)*

- **VPN: tunnel is restored after a delta update** — A delta update replaces the system's root snapshot, wiping out every VPN trace that lived there (symlinks, systemd override, NetworkManager configuration, DNS entry) — the actual configuration in the data directory survived, but the tunnel no longer came back up. VPN deployment now ships an idempotent restore script; the Agent detects on startup that a VPN configuration exists but the tunnel isn't active, and restores it automatically. *(Backend, Agent)*

- **Setup wizard: reverse proxy restart now runs in the background** — The reverse proxy used to restart while the setup request was still in flight, cutting the HTTPS connection before the login token reached the browser. The restart now runs in the background after the response is sent and the database commit completes; the browser bridges the brief outage. *(Backend, server services)*


## 2026-04-05

- **Cloning VM stays runnable after "Save update"** — After "Save update delta & create clone," the VM disk used to be reset, requiring a manual clone restore before the next update. The VM now stays active on the freshly created clone state, so the next update can build on it directly. *(Backend)*

- **VM settings survive container restarts** — The cloning VM's configuration (RAM, CPUs, disk size, virtualization acceleration) used to be lost on every backend restart or container rebuild. These values are now stored persistently alongside the active clone and reloaded on the next start. *(Backend)*

- **Tools-ISO is rebuilt automatically on VM start** — Clicking "Start VM" now automatically rebuilds the Tools-ISO fresh, so it always contains the latest scripts, the current heartbeat token, the signing key, the TLS certificate, and the server URL. No more manual rebuild needed. *(Backend, deploy repo)*

- **Install scripts: data partition size is now interactive** — The install scripts for cloning VMs now prompt for the desired size of the persistent data partition — accepting input in GB (e.g. 5, 10G) or as a percentage of the disk (e.g. 10%), defaulting to 5 GB. *(deploy repo)*

- **Update deltas: compressed faster, same size** — The delta compression level was reduced from 9 to 3, since the data blocks are already pre-compressed and a higher level brings almost no size benefit while costing noticeably more CPU time. Result: faster updates at nearly the same file size. *(Backend)*

- **UI: buttons disabled during a clone operation** — "Reset VM" and "Save update delta" are now disabled while a clone operation is in progress, preventing accidental triggering mid-operation. *(management interface)*


## 2026-04-04

- **Ansible automation integrated via Semaphore** — ThinForge now ships with a built-in Ansible runner ("Semaphore") for rolling out recurring configuration tasks to managed devices in an automated way. During setup, Semaphore is configured automatically (admin account, API token, project, provisioning key); key rotations and admin password changes are picked up automatically, and all devices are synced to Semaphore as a dynamic inventory grouped by ThinForge groups (hourly, plus manual trigger). Reachable on the server at port 8443. *(Backend, server services, deploy repo)*

- **New "Automation" tab: manage playbook packages** — Under the Clients area, next to "Clients" and "Warranty," there's now an "Automation" tab for uploading, exporting, and removing Ansible playbook packages as ZIP archives with a descriptor file; uploading automatically creates a matching Semaphore template to run it. A first package (XFCE desktop configuration) is included out of the box. *(Backend, management interface)*

- **Partial backup for keys only** — A new "Export Keys" button in the backup settings delivers the SSH key, signing key, heartbeat token, and TLS certificate as a ZIP; the setup wizard offers a matching third option to import keys directly from such a ZIP, generating any missing files automatically. As a result, the separate "Signing Key" setup wizard step is gone — the key is now generated automatically or taken from the imported partial backup. *(Backend, management interface)*

- **Various fixes around Semaphore** — The reverse proxy now clears its certificate cache on reload (preventing stale certificates after a container restart), initial configuration can be retried after a partial failure instead of getting stuck, and password sync to Semaphore now only fires for the admin account, not Operator/Viewer accounts. *(Backend, server services)*


## 2026-04-03

- **Updates with user notification and automatic reboot** — Creating an update rollout now has a "Notify user" toggle. When enabled, after the update is staged the Agent shows the logged-in user a 15-minute countdown dialog on the device with "Restart now" and "Cancel." No response triggers an automatic restart; cancelling applies the update on the next regular shutdown instead (the dialog won't reappear for that same update, but will for a new one). If no user is logged in, the device restarts immediately without a dialog. *(Backend, Agent)*

- **Debian support for cloning VMs** — A new install routine now supports Debian-based cloning VMs alongside the existing Manjaro variant, in two stages: preparation (disk partitioning, Calamares configuration) and finalization (boot loader, Agent, time sync, SSH, packages). The Agent and its helper scripts now automatically detect which name the root subvolume uses on Manjaro/Arch vs. Debian, with protection against accidental deletion covering both variants. *(Agent, deploy repo)*

- **Boot loader: Debian-compatible invocation** — When applying updates and inside the Agent, the Debian-style boot loader update command is now tried first, falling back to the Arch/Manjaro command only when needed — no more manual intervention depending on distribution. *(Agent)*

- **Time sync: Chrony as the default on thin clients** — Both install routines (Manjaro and Debian) now install Chrony as the time synchronization service and point it at the ThinForge server as the time source — preventing TLS errors caused by clock drift on devices. *(deploy repo)*

- **SSH hardening now runs after Agent installation** — SSH used to be hardened (password login disabled) before the Agent was installed; if installation failed between hardening and key transfer, the device became unreachable afterward. The order is now reversed: hardening runs only after the key has been installed successfully, and on Debian the SSH server is auto-installed if missing. *(deploy repo)*

- **NFS server: fixed an endless restart loop** — The NFS server container was stuck in a restart loop because an outdated launch parameter ("disable NFSv2") is no longer supported by the newer server version. The parameter was removed and the container now runs stably. *(server services)*

- **Bilingual guides (German + English) on the Tools-ISO** — The Tools-ISO and its documentation collection now include complete install guides for Debian and Manjaro in both German and English; earlier Manjaro-specific text was generalized so it applies to both distributions. *(deploy repo)*


## 2026-04-02

- **Security: container images cleaned up** — Several container images now run on newer, leaner bases: the NFS server image was fully replaced with a lean, in-house Alpine-based image (previously an outdated third-party image with 13 critical and 72 high vulnerabilities), Chrony and WireGuard now also run on Alpine, the cloner image is now built in multiple stages so build tools no longer ship in the final image, and noVNC on the cloning VM is installed as static files instead of a package, removing an extra Node.js dependency. External image versions (Postgres, Redis, Caddy, Prometheus, Grafana) are now pinned, and there's a documented acceptance list for remaining, unfixable vulnerabilities plus an automatic weekly scan and a scan on every image build. *(server services, deploy repo)*

- **Time settings: centrally configurable and pushed to thin clients** — Under Settings → General you can now configure the upstream NTP server and the global time zone; the time zone is pushed to all managed devices via heartbeat, and the Agent applies it on the device. Works on Manjaro/Arch and Debian/Ubuntu. *(Backend, management interface, Agent)*

- **Update rollouts: devices already on the target version are excluded automatically** — When creating an update rollout, devices that already have the target version or newer are now skipped automatically; the status table no longer lists confirmed devices or ones with a higher version, keeping the list focused on what's actually pending. *(Backend, management interface)*

- **Importing clones: inserting ahead of an existing clone** — Imported clones can now be positioned ahead of an existing clone in the version chain; the original version is detected from the clone's name and validated against the target position to prevent incorrect ordering. The assignment dialog shows grouped "insert ahead of clone" options for unassigned clones with a recognizable version. *(Backend, management interface)*

- **Update deltas: export and import** — Individual update deltas can now be exported as a 7z archive and re-imported into another installation; import detects the version from the file name, validates it against the existing chain, and rejects duplicates. *(Backend, management interface)*

- **Clone import now uses the version stored in the clone** — Importing a clone now reads the version from its name instead of assigning a new root number; clones without a recognizable version in their name still get a new root number. *(Backend)*

- **Rollback tab: persistent rollouts with per-device status** — The Rollback tab under Cloning now works analogously to update rollouts — persistent rollback rollouts with per-device status (pending / prepared / completed), expandable detail rows, automatic status updates via heartbeat, and bulk actions for restart/shutdown. *(Backend, management interface)*

- **Update chains: linked/unlinked status instead of an approval checkbox** — The approval checkbox on update deltas is gone — every delta is available immediately after creation or import, and actual distribution is controlled entirely through rollouts. The update chain is now sorted by version instead of creation date, the previous logic that auto-merged a delta into its successor on clone deletion has been removed (deltas now survive clone deletion), and the old "conflicted devices" sidebar feature is gone in favor of the dedicated Rollback tab. *(Backend, management interface)*


## 2026-04-01

- **Deleting a clone: optional rollback for affected devices** — When deleting a clone that devices are still running, the confirmation dialog now asks whether to trigger an automatic rollback for those devices (server flag → heartbeat → local marker → device switches to the previous snapshot on next shutdown). A dynamic "conflicted devices" group in the sidebar lists affected devices with status markers and a rollback button, individually or in bulk. *(Backend, management interface, Agent)*

- **Update rollout: pick a group first, then devices** — Device selection for update rollouts now follows the same cascading pattern as deployment creation — pick a group first, then devices within it — instead of listing all devices unfiltered as before. *(management interface)*

- **Update deltas: export individually** — Individual update deltas can now be downloaded as a 7z archive, optionally protected with an AES-256 password; the archive contains the delta, its signature, and metadata, with a button right next to each delta in the update chain. *(Backend, management interface)*

- **Smart clone deletion** — Clones can now be deleted "intelligently." The system analyzes the clone's position in the delta chain: for the **last clone** in the chain, its delta is deleted along with it (the version number is reused on the next save); for a **clone in the middle** of the chain, the incoming delta is automatically merged into the successor's delta, with the merge running in the background behind a progress bar. Before deletion, the system checks whether the VM is currently running that version (with a warning), and the confirmation dialog shows all side effects. *(Backend, management interface)*

- **Various fixes** — Agent-internal paths (configuration, token, version files, signing key) now live consistently on the persistent data partition instead of a volatile system directory, so they survive reboots; signature verification of the update key now reliably extracts just the actual key line. Also: devices on the baseline version are now correctly matched, a race condition when creating an update rollout with a merge is fixed, a duplicate confirmation dialog when deleting a rollout is removed, a bug causing the cloning page to open twice on menu click is fixed, a new button resets all DHCP leases, and approved devices now get an IP reservation right at approval time. *(Backend, Agent, management interface)*


## 2026-03-31

- **Update merges: real-time progress + background clone restore** — Generating merged update deltas now shows a real progress bar with named steps instead of an indeterminate spinner, kept in sync across multiple open browser tabs. Also, "Restore clone" no longer blocks the UI — the dialog closes immediately, progress is shown through the usual status mechanism, and on completion a notification appears and the view switches automatically to the VM tab. *(Backend, management interface)*


## 2026-03-30

- **Merged update deltas are now scoped to actually assigned devices** — Merged deltas used to be computed for **every** device in the database, even when only a fraction of them were part of the actual update rollout. The system now only considers the installed versions of devices that are truly assigned; existing merged deltas continue to be reused. Also, the old Ansible integration has been removed entirely, superseded by the Agent-based management path. *(Backend, deploy repo)*


## 2026-03-29

- **Update deltas are now signed (cryptographically verified)** — Every update delta (individual, merged, home deltas) is now automatically signed with minisign (Ed25519). Devices verify the signature before every apply; an invalid signature triggers a hard abort (a second check in the apply script provides additional protection). The public key is distributed via heartbeat, and on rotation the system updates the trust chain automatically (managed under Settings → Security). This secures delivery over NFS, multicast, and BitTorrent against tampering and transmission errors. *(Backend, Agent, management interface)*

- **Update mechanism: merged deltas + automatic package updates on Manjaro** — Devices lagging several versions behind can now be updated in a single step instead of sequentially (one reboot instead of many). The system generates "merged" deltas on a temporary disk and automatically picks the largest available version jump. Creating an update rollout now has a "Generate merged deltas" checkbox; the backend runs the merge in the background, devices automatically wait until the merged deltas are ready, and each merged delta's release can be controlled individually. *(Backend, management interface)*

- **Agent v2.4.1: VPN routes update live** — When the routed networks are changed in the VPN Networks tab (e.g. for full-tunnel routing), all VPN clients automatically receive the updated list on their next heartbeat; the Agent compares it against the local configuration and restarts the tunnel on change — no manual redeployment needed. *(Backend, Agent)*

- **Update-apply mechanism overhauled** — Changed snapshot permissions had corrupted the snapshots' internal data format, so the system tools could no longer find the parent snapshot; received snapshots are no longer modified afterward, boot configuration is now generated **before** the subvolume swap, and only the immediately preceding snapshot appears as a rollback option in the boot menu. Agent v2.4.0 also loads a migration script on every start and runs it idempotently, automatically reinstalling any services missing after a subvolume swap. *(Agent)*

- **Various fixes** — Several bugfixes in the "Save update" flow (snapshot filtering, duplicate generation, cleaner version checks, protection against concurrency issues); tunnel status now refreshes automatically after importing or saving a VPN configuration, stuck "merge in progress" markers are cleared on backend startup, and the delta list automatically reloads once a merge completes. *(Backend)*
## 2026-03-28

- **Clones and deltas: "stale" marker for superseded versions** — Full clones and update deltas that every active client has already moved past are now shown struck through and marked "stale". Expandable detail rows per clone/delta show which active and storage clients are still on that version, making it easy to spot versions that are no longer needed. *(Backend, management interface)*

- **PXE boot works on all clients + GRUB/EFI improvements** — Every registered client now receives a PXE boot image from the server on every start; the per-client PXE configuration decides between local boot and Clonezilla boot, independent of OS. GRUB now also scans local EFI partitions and chainloads the OS boot loader directly, fixing an infinite loop that occurred when PXE was set as the first UEFI boot option. *(Server services, deploy repo)*

- **Updates tab: bulk actions directly in the status table** — The client status table in the Updates tab now has selection checkboxes and bulk "Restart" and "Shut down" actions, matching the main Clients tab. *(Management interface)*

- **Agent: automatic script and version updates, snapshot cleanup** — On startup the agent now updates not only itself but also its helper scripts via hash comparison with the server, and cleans up old btrfs snapshots (keeping two current ones plus one pre-update pair) — permanently reducing disk usage on clients. Self-update now runs on every heartbeat instead of only at startup, so new versions land within 60 seconds. On rollback the home directory is now also mounted from the matching snapshot, and GRUB is reconfigured immediately after the subvolume swap at shutdown so rollback entries are available on the very next boot. *(Agent)*

- **VPN firewall: persistent and hardened** — Firewall rules are now stored persistently and reloaded automatically on container start (previously all rules were lost on restart); the backend also reapplies them defensively on its own startup. System rules (DNS, HTTPS) can now only be toggled on/off, not modified; firewall rule input is strictly validated to prevent command injection. **Security note:** the VPN management API is no longer reachable from the LAN interface, only via the internal Docker bridge. *(Backend)*


## 2026-03-27

- **Agent self-update and snapshot management** — On startup the agent now checks its version against the server and updates itself automatically (backing up before the swap, restarting via systemd afterward), and reconfigures the boot loader after a delta update so all snapshots show up in the boot menu. A successful boot on a new version is confirmed to the server automatically and old snapshots are cleaned up. Also new: an inventory number column in the update views (used as default sort), refresh buttons throughout, and expandable update assignments showing per-client hostname, MAC, installed version and status. *(Agent, management interface)*

- **Version scheme: unified "vMAJOR.MINOR" with three-digit minor** — Version strings are now automatically normalized with a "v" prefix, and the minor version is zero-padded to three digits (e.g. `v1.001`) so filenames and snapshot lists sort correctly alphabetically. The "Save update" dialog now lets you choose between a delta update (minor bump) or a new base image (major bump, new version chain); with no existing clones a fresh `v1.000` baseline is always enforced. *(Backend, management interface)*

- **Update applied at shutdown instead of at runtime** — Delta updates are now applied by a systemd service at shutdown instead of on the running system, preventing the desktop from freezing during the internal subvolume swap. The agent stages the delta locally; the actual switch happens on the next shutdown. Old snapshots on the cloning VM are now deleted automatically before a new base image, and client provisioning now also installs the apply service and the snapshot management script. *(Agent, deploy repo)*

- **Various fixes** — Fixed desktop freezing after a delta update (subvolume swap now only happens at shutdown, GRUB snapshot daemon disabled); prevented duplicate delta downloads via an extra local marker; pre-update snapshots no longer grow unbounded; fixed a multicast import error caused by a faulty internal import. *(Agent, backend)*


## 2026-03-26

- **Cloning VM: data partition is created automatically** — The Manjaro install script now automatically creates a roughly 5 GiB btrfs data partition (`@data` subvolume), mounted at `/data`, that survives all updates; the system partition is shrunk online live to make room. *(Server services, deploy repo)*

- **Tools ISO cleaned up + version consistency** — The Tools ISO now contains only three main scripts, with helpers moved into a subfolder. When creating a clone, the version is now stamped onto the disk automatically, so freshly rolled-out clients report it correctly from the first boot. Update assignments can be deleted from the Updates tab (running ones are cancelled cleanly), and the VM disk is automatically reset after a successful clone. *(Backend, deploy repo)*

- **Update deltas: multiple subvolumes + automatic subvolume swap + persistent WireGuard** — Snapshots and deltas now cover both `@root` and `@home`, so desktop customizations (icons, workspace layout, panel settings) flow automatically from the master system to clients; the subvolume swap on the next boot no longer needs manual GRUB intervention. WireGuard configuration now lives on the data partition and survives all updates. The VPN subnet is now automatically added to all NFS shares, and a DNS override maps the server hostname to the internal IP so heartbeats and update downloads correctly go through the tunnel. *(Agent, server services)*

- **Various fixes** — "Installed image" now shows the correct visible version instead of the internal number; fixed a duplicate "v" in the client list; fixed a crash in clone restore when the version started with "v"; VM startup stabilized (invalid MAC address fixed, UEFI boot order reset when the ISO is mounted); capture with spaces in the name now works; several capture follow-on bugs plus VPN NFS access and VPN routing through the tunnel were fixed. *(Backend, management interface)*

- **Security (note)** — Documented as an important pre-production TODO: WireGuard keys currently live in plaintext on the data partition. Before production use, the data partition should be encrypted with LUKS and secured with TPM 2.0 auto-unlock (or a hardware-ID fallback); the database schema and UI groundwork for this already exist. *(Agent, backend)*


## 2026-03-25

- **First complete delta update on real hardware** — First full end-to-end run on a real client: baseline v1.0 → update v1.1, a 1.6 GB delta pulled over NFS in 2 seconds and applied in 26 seconds, with GRUB reconfigured automatically — no user interaction and no forced restart. This confirms the end-to-end path works. *(Agent, server services)*

- **Automatic version numbering + boot loader now standard Manjaro logic** — Versions are now auto-incremented (v1.0 → v1.1 → …) instead of entered manually, with an optional comment in place of a version number. The custom GRUB mechanism has been replaced by Manjaro's native `grub-mkconfig` plus `grub-btrfs`: snapshots automatically show up as bootable entries in the GRUB menu, so rollback just means "pick a snapshot from the menu"; "Timeshift" is no longer needed, removing about 300 lines of code. *(Backend, deploy repo)*

- **Manjaro install script split into two stages + various fixes** — New two-stage install script (a "prepare" phase for Calamares, a "finish" phase for GRUB and the agent) with dynamic kernel detection, plus a separate script for quick SSH access to the VM. Fixes from live testing: an NBD write error, a missing heartbeat token from the Python agent (causing 403s), missing baseline versions for freshly rolled-out clients, incorrect snapshot list parsing, and visibility of the deltas directory inside the backend container. *(Server services, deploy repo)*

- **Cloning VM info: MAC + IP + progress bar** — The VM tab now shows the VM's MAC address and IP in the info panel; "Save update" now shows a percentage progress bar, matching clone creation. *(Management interface)*


## 2026-03-23

- **Major feature: delta update system for clones** — First stage of the delta update mechanism: instead of full redeployments (15+ GB), a delta between two versions (typically 50–200 MB) is now enough. This introduces a new partition scheme (EFI + btrfs system with snapshots + btrfs data), a "Save update" button in the VM tab (creates a snapshot, delta, and full clone in one step), and a new Updates tab for the delta list and rollout management. The agent confirms successful update boots to the backend, delivery runs over NFS restricted to authorized clients with no automatic restart, and the whole mechanism is distribution-neutral, working on both Debian-based and Arch/Manjaro systems. *(Backend, agent, management interface)*

- **Update release gating, update chain, and group assignments** — Updates must now be explicitly released before clients receive them (a rollout starts as "Draft", is clicked to "Active", and is automatically marked "Completed" once all clients are done). The update chain is shown as an enforced order in the UI (e.g. v1.1 can only be released once v1.0 is already active), groups/clients can target different versions, and clients automatically work through the chain step by step on each heartbeat. Deleting a delta now warns if clients or the version chain would be affected. *(Backend, management interface)*

- **New disk scheme can be applied from the UI** — A new "Apply disk scheme" button in the VM tab creates the disk if needed and repartitions it (EFI + system btrfs + data btrfs). A warning dialog shows the layout and explicitly calls out data loss; the button is disabled for restored clones. *(Backend, management interface)*

- **Agent refactor (v2.0)** — The Python agent was substantially reworked: retries per delta are now capped at 3, a new delta is not accepted until the previous one has booted successfully, the installed version is now persistently tracked in its own file, and installation now runs cleanly through the Tools ISO and provisioning script. *(Agent)*


## 2026-03-22

- **Setup wizard: restore from backup as an entry option** — The setup wizard now first asks whether to do a fresh install or restore from a backup. On restore, the backup is uploaded, validated, and fully restored — including the database, configuration (VPN, DHCP, NFS, Chrony, reverse proxy) and encryption keys; services are restarted as needed so the imported key takes effect. *(Backend, management interface)*

- **VPN: FullVPN subnet management** — ThinForge now supports the thinVPN server's FullVPN endpoints; routed networks are automatically synced to the VPN server as individual subnets of the main server. This resolves a previous VPN routing problem: the local subnet is now automatically added to the main-server peer's routes (provided `fullvpn: true` is enabled on the VPN server). FullVPN status is visible in the VPN Networks panel, with a manual "VPS Sync" button. *(Backend, management interface)*

- **Various fixes** — A client's PXE configuration is no longer incorrectly reset during capture; the new deployment dialog now auto-preselects the most recent clone; VPS status requests return an empty default instead of an error when the VPS is unreachable (e.g. right after a tunnel import while WireGuard is still starting); the Tools ISO is now automatically rebuilt before every VM start; the CSV import dialog now closes automatically on success; the WireGuard container no longer gets stuck "unhealthy" after a factory reset. *(Backend, management interface)*

- **Per-client SSH keys removed** — Individual per-client SSH key management has been removed entirely; all SSH connections now use only the central provisioning key. Several related API endpoints and UI sections were removed — leaner, fewer failure points, with no loss of functionality in practice. *(Backend, management interface)*

- **Clients: new "connection type" field (LAN / VPN / VPN sync)** — Every client now tracks a connection type: `lan`, `vpn` (heartbeat over VPN), or `vpn_sync` (detected only via VPN API sync, no heartbeat). The status display uses matching icons, plus a new "Connection" filter in the client list and display in the detail view and on the dashboard card. *(Backend, management interface)*

- **VPN: new "VPN Networks" tab and clean deactivation** — New tab with checkboxes for detected host interfaces and manual CIDR entry. Deactivating VPN now automatically triggers a cleanup job on the client (stopping WireGuard, removing the configuration); deployment now also installs a systemd override file that pins route metrics at system startup. *(Management interface, agent)*


## 2026-03-21

- **Setup scripts consolidated, host dependencies reduced** — Two separate setup scripts have been merged into one; host dependencies are now reduced to Docker, Git, OpenSSL and a few kernel modules. Packages like qemu-kvm, NFS server packages, WireGuard tools and libvirt are no longer installed on the host (the kernel modules already ship with Ubuntu 24.04), the KVM vendor is detected automatically, and conflicting host NFS services now only trigger a warning instead of being shut down. *(Server services, deploy repo)*

- **Version display + changelog dialog in the header bar** — The ThinForge version number is now shown top right in the header bar; clicking it opens a dialog with the current changelog, rendered as Markdown. *(Management interface)*

- **Large codebase cleanup pass** — Extensive internal cleanup across roughly 40 areas with no behavior changes: less duplicated code, faster database queries (several "N+1" patterns eliminated, one spot saving around 700 database queries per cycle), and overall more stable operation. *(Backend)*


## 2026-03-20

- **Large bundle of deployment, VPN, and task improvements** — All deployment paths (unicast, multicast, BitTorrent) now check the target disk size before restore and abort cleanly with a clear error if it's too small, instead of failing mid-restore. New additions include a "General" settings tab with configurable session duration (1h–30 days), a VPN Tasks tab with live status/retry/cancel for VPN background jobs, a VPN Remote Sync tab (shows clients configured on the VPN server, orphaned entries marked red), the ability to re-push VPN configuration without regenerating keys, schedulable task templates, and a unified group filter for client selection. VPN clients with key-decryption problems are now automatically re-provisioned on their next configuration fetch, and storage clients are now visually marked (greyed out, orange status chip) with automatic IP release/reassignment. Also included: numerous smaller fixes (metrics, race conditions in the rate limiter and IP allocation, the provisioning SSH key in the worker container, N+1 queries). *(Backend, management interface)*


## 2026-03-19

- **Major feature: VPN integration based on thinVPN (cloud)** — The previous local WireGuard VPN system has been replaced by a cloud-based thinVPN integration: the ThinForge server connects as a WireGuard client to an external thinVPN server and manages client VPN profiles from there via a REST API. Tunnel configuration is set up via import in the new VPN tab and can be removed again with confirmation; VPN configuration is now controlled per group (a "VPN active" toggle, plus bulk "generate missing" / "regenerate all (key rotation)" operations), keys can optionally be stored in each client's TPM, and there's periodic sync, traffic monitoring, and an optional firewall for VPN-to-LAN traffic. Alongside this, the WireGuard configuration is now automatically deployed to clients via SSH, including auto-installing the WireGuard tools if needed. *(Backend, management interface)*

- **Profile feature removed** — The separate "configuration profile" feature has been removed entirely, as it saw no use in practice; groups now carry the relevant settings directly, and data migration runs automatically. *(Backend, management interface)*

- **Various VPN and TLS fixes** — Tunnel status now displays correctly in the UI (previously stuck showing "disconnected"); the firewall toggle no longer overwrites the rest of the VPN settings; DNS resolution from the backend after WireGuard starts works again; the WireGuard container now runs stably even without an initial configuration; TLS certificates now include all detected server IPs, preventing certificate errors when accessing the management interface. *(Backend)*


## 2026-03-18

- **BitTorrent deployment works again** — Because of an ordering issue in internal key generation, clients were looking for their torrent files in a directory the seeder never populated. Fixed: the key is now generated before activation, so PXE configurations line up correctly. *(Backend)*

- **Deployment status: errors now shown correctly** — Previously a deployment stayed permanently "Completed" (green) even if every client had failed. A new "Completed with errors" status (red) now surfaces failures instead of hiding them. Torrent and helper files are also cleaned up when a deployment is deleted, and spurious offline alerts after a deployment no longer occur. *(Backend, management interface)*

- **Active client check ("ping") and default sort by inventory number** — Clicking a client's green "Online" status in the list now triggers two parallel pings; if neither responds, the client is immediately marked offline (this requires ICMP to be allowed in the client's firewall). The client list is now sorted by inventory number (ascending) by default. *(Backend, management interface)*

- **Container base moved to Debian Trixie + newer Partclone** — All ThinForge containers now use Debian 13 (Trixie, stable) instead of the unstable development branch, and Partclone (the disk cloning tool) has been bumped to version 0.3.47. Build sources are now cached locally for faster rebuilds and less network load. *(Server services)*

- **Deployment retry improvements** — The inventory number is now visible in the client list of an expanded deployment; the restart button now also appears for cancelled deployments (not just failed ones), and cancelling now cleans up status correctly. Clients that don't report back after a multicast transfer finishes (e.g. rebooted mid-transfer) are now automatically marked as failed (timeout configurable, default 120 seconds); retrying failed clients now reliably reactivates the NFS share. *(Backend, management interface)*

- **Security: BitTorrent paths no longer predictable** — Torrent files are now served under a random 32-character path instead of the predictable deployment ID. As additional protection, the DHCP configuration now filters unknown clients (`dhcp-ignore=tag:!known`) — only registered clients get an IP at all. *(Backend)*

- **HTTPS from the start + TLS certificate on clients** — On first server startup, a self-signed TLS certificate is now generated automatically; the reverse proxy serves HTTPS immediately and redirects HTTP automatically. The setup wizard replaces the certificate in step six with one carrying the correct CN/SANs; the server certificate is also automatically embedded in the Tools ISO and added to each client's system trust store by the client install script, so all server URLs (heartbeat, agent, ISO) now run over HTTPS. *(Server services, deploy repo)*

- **Security: stronger key derivation + login rate limiting** — Encryption of stored SSH and WireGuard keys now uses PBKDF2-HMAC-SHA256 with 600,000 iterations and a persistent salt; existing data is migrated transparently as needed. New: rate limits on login endpoints (`/login` 5 attempts/5 min, `/totp/login` 3/5 min, `/change-password` 5/5 min). **Important:** an unauthenticated web terminal endpoint that gave anyone on the LAN a root shell has been removed — the terminal dialog now only uses the authenticated endpoint. *(Backend)*
## 2026-03-17

- **Worker Stabilized + BitTorrent Mode Detection Fixed + Persistent PXE State** — The worker container crashed on every recurring task due to an internal error; this is now fixed. BitTorrent deployment mode detection compared mismatched values, so devices received no boot image — both variants are now accepted. A backend restart used to wipe the PXE configuration for running deployments; active deployments are now restored from the database on startup, so deployments survive backend restarts. *(Backend, server services)*

- **VPN Improvements: Live Status, Auto-Install, Retry, Revocation** — WireGuard handshake data (last contact, transferred bytes) now syncs to the database every minute, and the agent reports VPN status in its heartbeat. WireGuard tools are installed automatically on the thin client when needed, and SSH failures during VPN deployment trigger up to three retries with increasing delay. Revoking a VPN client now also removes the WireGuard configuration from the device (service stopped, disabled, file deleted). *(Backend, Agent)*

- **Dashboard: Storage Usage + New Info & Backup Section** — A new dashboard card shows the server's disk usage with a color-coded bar. The new Info & Backup menu adds full backup and restore — database and configuration are always included, with ISOs/clones/captures as optional add-ons, downloadable as an archive, and restorable via upload with password confirmation. ThinForge logos were also added throughout the interface with automatic dark/light switching. *(Backend, management interface)*


## 2026-03-16

- **New Feature: Remote Desktop (Live Screen View)** — Thin clients can now be viewed live in the browser and controlled remotely. The stream runs entirely over the existing SSH connection — no VNC, no extra open ports required. X11/XFCE is supported today, with Wayland planned. *(Backend, management interface)*

- **Devices: Shutdown as Bulk Action + Actions Dropdown** — A new Shutdown button is available on the device detail view and as a bulk action for multiple devices. Wake, Reboot, and Shutdown are now grouped into a single, tidy actions menu. *(management interface)*

- **DHCP: Static IP Assignment + Mismatch Detection** — Newly created or imported devices automatically get a static IP from the DHCP pool, bound to their MAC address via dnsmasq. If a device later reports a different IP (except VPN IPs on another subnet), the interface now warns about it. *(Backend, management interface)*

- **Heartbeat and Clone Provisioning, Dynamic Server URL** — Heartbeats are now token-authenticated and report MAC address and IP to the server. Clone provisioning uses a global SSH key with an automatic provisioning script; the server URL is now embedded dynamically into the Tools-ISO, and the server's DNS entry is created automatically during the setup wizard. Hardware captures are now zstd-compressed, enabling password-free clone import, and the TLS form in the setup wizard is pre-filled with hostname and IPs. *(Backend, Agent, deploy repo)*

- **Various Fixes** — Remote Desktop now sets up root's X11 access correctly and automatically, reboot works again, and an internal DNS loop was fixed. PXE boot is now reliable (boot mode, DHCP reload, static IPs), NFS mounts use the assigned static IP instead of the heartbeat IP, the clean-reset script is more thorough, and older hardware captures in the `.gz.aa` format can be restored again. *(Backend, Agent, server services)*


## 2026-03-15

- **Several New Features Around Clones, NFS, and Maintenance** — NFS shares are now restricted to authorized device IPs, and the post-capture action is configurable. New: a storage mode for marking devices as stored, a version-mismatch alert when a device isn't running the current clone version, and maintenance windows for scheduled deployments. TLS certificates can now be managed through the interface, the Tools-ISO for the cloning VM was improved (CD-ROM detection, display, hostname script), and the product was renamed from ThinOS to ThinForge. *(Backend, management interface, deploy repo)*


## 2026-03-14

- **Client Time Sync + UEFI-PXE Improvements** — A new Chrony-based NTP server keeps thin client clocks in sync. The setup wizard now supports capture restart and network hardening, and UEFI devices can boot via PXE with a local-boot fallback. *(Backend, server services)*


## 2026-03-13

- **Scheduled Deployments, BitTorrent Stability, Wake-on-LAN** — Clone deployments can now be scheduled for a specific time, and the BitTorrent seeder is more stable and performant. A new Wake-on-LAN button is available in the interface, and the factory reset flow got clearer guidance. *(Backend, management interface)*


## 2026-03-12

- **BitTorrent and Multicast Deployment** — Clone images can now be distributed peer-to-peer via BitTorrent to many devices cloning in parallel. Alternatively, the server can stream the image once via multicast to multiple devices simultaneously, with a countdown shown until all recipients are ready. *(Backend, server services)*


## 2026-03-11

- **Container Stability + New Deployments Tab** — All Docker services now run with automatic restart and health checks. A new Clone Deployments tab manages deployments, letting clones be assigned to individual devices. *(server services, management interface)*


## 2026-03-10

- **Capture Job System + Dashboard Settings** — PXE-based disk captures can now be cancelled mid-run. The dashboard also got layout adjustments and new settings options. *(Backend, management interface)*


## 2026-03-09

- **Task System with Progress + Encrypted Clone Export** — Running tasks now show a progress indicator, and tasks can be scheduled. Clone export can optionally be password-encrypted, and the thin client agent version is now tracked. *(Backend, Agent, management interface)*


## 2026-03-08

- **UEFI Boot, DNS Forwarding, Restore Progress** — UEFI devices can now boot via PXE with GRUB-EFI support, and dnsmasq handles DNS forwarding, configurable through the interface. Restoring a clone now shows a progress indicator, and external DNS servers are auto-detected during setup. *(Backend, server services, management interface)*
