# Private alpha participant notice — owner review draft

Battle for La Roma is an unfinished RTS with solo play and a limited private
two-player match. The alpha may change,
crash, or lose local progress. This build is intended only for people who
receive an individual download key and in-game invite code. Please do not
redistribute either one.

The game saves a random installation ID and a queue of play events on your
Mac. When online, it sends first open, match start, and match result events to
the aomx service. Each event includes a random event and match ID, UTC time,
local order number, game/content version, play mode, and result. The service
records receipt time, validation outcome and the flag decision. Results are
reported by the client and are not replay verified. We do not ask for your
name or email in the game; itch.io may process account and download information
under its own terms when you access the restricted page.

For a private match, each player enters a separate invite code. The match host
binds that code to the installation ID, receives your orders, and sends each
player the current battle view. It keeps the two installation IDs, hashed code
identifiers, accepted orders, result, state checkpoints and a replay after a
completed match. Only the two participants may retrieve that replay. The host
also handles your network address while you connect; reverse-proxy access logs
may contain that address and request time. Do not share your code or replay.
If one player is away for more than 60 seconds, the session ends without a
result. Private-match results in preview are test data and do not count toward
public play readings. The host may be unavailable or restarted between matches.

We use accepted events to see whether invited players install, finish a first
match, and return on a later day. Test and rejected traffic is left out of
those readings. The game keeps unsent events on your Mac and retries when
online. The operator can inspect the pseudonymous audit. Live audit events
and completed private-match records are deleted after 30 days by a daily
operator job. Invite codes and their server-side bindings expire after 30 days;
the operator deletes plaintext code files after delivery. A short-lived hash
of a withdrawn support ID is kept for up to 30 days to prevent an active
session from restoring deleted data. Aggregate daily counts may be kept longer
without your installation ID. Database backups are private in Oracle Object Storage and
expire after 30 days, so deleted data may remain in a backup until that copy
expires. Do not send sensitive information through any free-text support report.

To withdraw or request deletion, contact **miyagi@despachobonsai.com**
and include the support ID copied from the game's private alpha button.
Deleting the app alone stops new events but does not remove those
already uploaded. The operator verifies deletion requests, removes the live
audit and match records associated with that support ID, and removes its invite
binding. An active session or replay stops after withdrawal. The owner approves the first invitation before the restricted page is
shared with people outside the owner account.
