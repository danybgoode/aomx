# Private alpha: local macOS download QA

Use the Restricted [itch.io page](https://danybgoode.itch.io/battle-for-la-roma) while signed in as its owner. The `mac-private-alpha` build is a **preview**: its events are test traffic, and the Golden Frijoles flag stays off. The owner waived a separate-Mac check on 2026-10-14, so record that this walkthrough covers one machine.

## Install the current build

1. Move the old `Battle for La Roma Alpha.app` that macOS called damaged to the Bin. That build had an invalid code signature. Download the newest macOS build from itch.io; check that its version starts with `preview-` and matches the current build ID in the epic execution log. Safari may expand the ZIP into an app automatically.
2. Verify the newly downloaded app before opening it:

   ```sh
   codesign --verify --deep --strict --verbose=2 "$HOME/Downloads/Battle for La Roma Alpha.app"
   ```

   It should say `valid on disk` and `satisfies its Designated Requirement`. If it reports an invalid signature or macOS still says the app is damaged, stop and report the version shown on itch.io. Do not try to open the old build by removing its quarantine attribute.
3. Move the new app into `/Applications`, then open it. This private preview has a valid ad hoc signature but no Apple notarization. If macOS says its developer cannot be verified, use **System Settings → Privacy & Security → Open Anyway**, then confirm **Open**. This makes an exception for this app; there is no need to disable Gatekeeper globally. [Apple's instructions](https://support.apple.com/en-ie/102445) and [Godot's macOS guide](https://docs.godotengine.org/en/4.7/tutorials/export/running_on_macos.html) describe this path.

## Play and check the outbox

1. Check that the window shows `Battle for La Roma Alpha`, the expected `preview-` build ID, an invite-code field and sync status. Record a screenshot.
2. Turn Wi-Fi off, start a solo match and play to a win or loss. Select a blue worker or building with left click; right-click a tile or resource to move or gather. Select a worker and press **B**, then click a clear 2×2 area to build a recruitment post. Select the command post and press **1** for a worker. Select the completed recruitment post and press **2** or **3** for melee or ranged units. Attack the red command post with combat units. The match draws after 15 minutes if neither command post falls.
3. At the result, verify the HUD says the event is saved and pending sync. Quit the app, reopen it, and verify the saved state remains. Press **R** to start a new match. Record the result and restart screens.
4. Once an **internal QA invite code** is available, enter it, turn Wi-Fi back on and press **F** to retry sync. Expect a synced **test** receipt; retry with **F** and confirm the receipt does not change. The operator checks that no public cohort event or numeric reading was created. Without an invite code, pending sync is expected.

Before external invitations, verify that an anonymous visit cannot see the Restricted page and that a temporary download key works outside the creator session. Revoke the test key afterward. A Developer ID signature and notarization would remove the manual Gatekeeper step, but require Apple developer credentials that are not configured for this preview.
