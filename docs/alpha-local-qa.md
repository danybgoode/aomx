# Private alpha: local macOS download QA

Use the Restricted [itch.io page](https://danybgoode.itch.io/battle-for-la-roma) while signed in as its owner. The `mac-private-alpha` build is a **preview**: its events are test traffic even though the owner enabled the **preview** Golden Frijoles flag on 2026-10-15. The owner waived a separate-Mac check on 2026-10-14, so record that this walkthrough covers one machine.

## Install the current build

1. Move the old `Battle for La Roma Alpha.app` that macOS called damaged to the Bin. That build had an invalid code signature. Download the newest macOS build from itch.io; check that its version starts with `preview-` and matches the current build ID in the epic execution log. Safari may expand the ZIP into an app automatically. macOS may name the current copy `Battle for La Roma Alpha-2.app` or another numbered variant when a previous copy is present.
2. Verify the newly downloaded app before opening it:

   ```sh
   codesign --verify --deep --strict --verbose=2 "$HOME/Downloads/Battle for La Roma Alpha-2.app"
   ```

   Safari may add a different number to the app name if an older copy remains in Downloads; use the exact name shown there. It should say `valid on disk` and `satisfies its Designated Requirement`. If it reports an invalid signature or macOS still says the app is damaged, stop and report the version shown on itch.io. Do not try to open the old build by removing its quarantine attribute.
3. Move the new app into `/Applications`, then open it. This private preview has a valid ad hoc signature but no Apple notarization. If macOS says its developer cannot be verified, use **System Settings → Privacy & Security → Open Anyway**, then confirm **Open**. This makes an exception for this app; there is no need to disable Gatekeeper globally. [Apple's instructions](https://support.apple.com/en-ie/102445) and [Godot's macOS guide](https://docs.godotengine.org/en/4.7/tutorials/export/running_on_macos.html) describe this path.

## Play and check the outbox

1. Check that the window shows `Battle for La Roma Alpha`, the expected `preview-` build ID, an invite-code field and sync status. Record a screenshot.
2. Check the board and text at normal window size. Press **+** and **-** or scroll to zoom the board, **0** to reset, and **G** to toggle fullscreen. Select a blue unit at each zoom level; its highlight should stay on the tile you clicked. The invite field, HUD and bottom controls should remain readable. The older `preview-1cf1e6843e3b` build in `Battle for La Roma Alpha-2.app` does not have these controls.
3. Turn Wi-Fi off and start a solo match. Your stockpile starts at **0**. Left-click the small blue worker near your HQ, then right-click the nearby gold circle. A short marker should say **Gathering gold**, and the HUD should repeat it under **Last action**. The worker automatically gathers and delivers four resource per trip. Watch **Stockpile** in the HUD, rather than **Gold left** at the source. After two trips, Stockpile should reach at least **6**. In build `preview-1cf1e6843e3b`, these labels read **Resource** and **Source** instead.
4. With the worker selected and at least 6 in your stockpile, press **B** and point at a clear 2×2 patch near your HQ. A yellow-green preview means you can build; red means the footprint is blocked (or, in the earlier build, the stockpile is below 6). Left-click a valid patch and wait for the worker to finish the recruitment **POST**. Try one blocked patch as well: the board marker should turn red and the HUD should explain the rejection. Press **Esc** to cancel placement. Click your blue HQ and press **1** to queue another worker (cost 4). Click the completed POST and press **2** for melee (cost 3) or **3** for ranged (cost 4). Each successful order should show a short confirmation. Click a blue combat unit, then right-click a red unit or the red HQ to attack. Destroy the red HQ to win; if yours falls, you lose. The opponent attacks at 01:20 and an unresolved match draws after 15 minutes. Press **R** to restart.
5. At the result, verify the HUD says the event is saved and pending sync. Quit the app, reopen it, and verify the saved state remains. Press **R** to start a new match. Record the result and restart screens.
6. Once an **internal QA invite code** is available, enter it, turn Wi-Fi back on and press **F** to retry sync. Expect a synced **test** receipt; retry with **F** and confirm the receipt does not change. The operator checks that no public cohort event or numeric reading was created. Without an invite code, pending sync is expected.

Before external invitations, verify that an anonymous visit cannot see the Restricted page and that a temporary download key works outside the creator session. Revoke the test key afterward. A Developer ID signature and notarization would remove the manual Gatekeeper step, but require Apple developer credentials that are not configured for this preview.
