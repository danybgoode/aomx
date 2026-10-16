# Private alpha: local macOS download QA

Use the Restricted [itch.io page](https://danybgoode.itch.io/battle-for-la-roma) while signed in as its owner. The `mac-private-alpha` art build is `preview-9e1c6f0e3a3e` (itch build `#2139865`, `la-roma-prototype-1`; source ZIP SHA-256 `84b4aa9aa31653144fad7541c527e14af6dfcd83735a7f0f6f590dfb84e9c5f3`). It is a **preview**: its events are test traffic even though the owner enabled the **preview** Golden Frijoles flag on 2026-10-15. The owner waived a separate-Mac check on 2026-10-14, so record that this walkthrough covers one machine. ZIP integrity passed; Butler fetched the processed build back to this Mac, where its app files matched the signed local candidate byte-for-byte, strict signature verification passed and packaged startup succeeded. The owner browser download and full playthrough below remain to be recorded.

The selection-and-scale update `preview-6d6016d42d8e` was uploaded as itch build `#2140875` on 2026-10-16 but is still processing. Until Butler shows that build as ready, the older version above is the downloadable one. The new source ZIP is `dist/alpha/battle-for-la-roma-preview-6d6016d42d8e-macos.zip` (SHA-256 `e6cb202b8d8b6497cf2a290823109b76bf7b157b1cc08902163fc51159519003`); it was signed and launched locally. Do not record owner download QA for the newer build until itch serves it.

## Selection-and-scale retest when the new build is ready

1. Confirm the setup or HUD names `preview-6d6016d42d8e` after downloading a fresh app from the Restricted page.
2. Hover over the visible body of a blue worker, including pixels above its ground tile. The warm outline and short selection hint should appear. Click there: the active worker should show a cyan outline, ground ring and arrow.
3. With that worker selected, hover the visible gold cart body. The hint should indicate gathering; right-click above the cart's ground tile and confirm “Gathering gold” appears and the worker starts moving toward the source.
4. Select a fighter and hover an enemy's visible body. The hint should indicate attack; right-click the body and confirm the attack order. Click empty ground and verify the active marker clears.
5. Compare workers, fighters, the headquarters and recruitment post at normal zoom. People should read distinctly smaller than the buildings, while remaining identifiable. Repeat selection at 100% and 125% zoom; note any sprite body that fails to respond.

Record the exact version, screenshots and any ambiguous clicks. The older walkthrough below still covers the economy, construction, win routes, restart and offline sync.

## Install the current build

1. Download `preview-9e1c6f0e3a3e` from itch.io. Safari may expand the download into an app automatically. The checksum above identifies the locally uploaded source ZIP; itch.io may package the browser download differently. macOS may add a number to the app name when a previous copy is present.
2. Verify the newly downloaded app before opening it:

   ```sh
   codesign --verify --deep --strict --verbose=2 "$HOME/Downloads/Battle for La Roma Alpha.app"
   ```

   Use the exact app name shown in Downloads. It should say `valid on disk` and `satisfies its Designated Requirement`. If it reports an invalid signature or macOS says the app is damaged, stop and report the version shown on itch.io.
3. Move the new app into `/Applications`, then open it. This private preview has a valid ad hoc signature but no Apple notarization. If macOS says its developer cannot be verified, use **System Settings → Privacy & Security → Open Anyway**, then confirm **Open**. This makes an exception for this app; there is no need to disable Gatekeeper globally. [Apple's instructions](https://support.apple.com/en-ie/102445) and [Godot's macOS guide](https://docs.godotengine.org/en/4.7/tutorials/export/running_on_macos.html) describe this path.

## Play and check the outbox

1. Check that the window shows `Battle for La Roma Alpha`, an invite-code field, sync status and a setup choice between Regios and Poblanos. Before choosing, confirm it states both win routes: destroy the opposing command post or hold La Roma for 60 seconds. Record a screenshot.
2. Check the board and setup text at normal window size. Choose Poblanos; the HUD should show `preview-9e1c6f0e3a3e`, `Poblanos vs Regios`, a blue headquarters against a red one, a central plaza objective and a neutral hold state. Check that terrain, carts, jacarandas, buildings and units have transparent edges and that friend/enemy colors remain clear. Press **+** and **-** or scroll to zoom the board, **0** to reset, and **G** to toggle fullscreen. Select a blue unit at its feet at each zoom level; its highlight should stay on the ground tile you clicked. The invite field, HUD and bottom controls should remain readable.
3. Turn Wi-Fi off and play the Poblanos match. Your stockpile starts at **0**. Left-click the blue worker's feet near your HQ, then right-click the nearby gold cart's ground tile. A short marker should say **Gathering gold**, and the HUD should repeat it under **Last action**. Poblanos workers deliver four gold per trip. Watch **Stockpile** in the HUD, rather than **Gold left** at the source. After two trips, Stockpile should reach at least **6**.
4. With the worker selected and at least 6 in your stockpile, press **B** and point at a clear 2×2 patch near your HQ outside the district. A yellow-green preview means you can build; red means the footprint is blocked. Left-click a valid patch and wait for the worker to finish the recruitment **POST**. Try one blocked patch as well: the board marker should turn red and the HUD should explain the rejection. Press **Esc** to cancel placement. Select the blue HQ at its ground footprint and press **1** to queue another worker (cost 4). Select the completed POST at its footprint and press **2** for melee (cost 3) or **3** for ranged (cost 4). Poblanos' command and recruitment posts have 20% more health. Each successful order should show a short confirmation.
5. Move a blue fighter into the marked center by selecting at its feet. The HUD should show the blue side holding La Roma and increasing progress. Move the fighter out or let a red fighter contest it; progress should reset. Win either by holding uncontested for 60 seconds or by destroying the red command post. If yours falls, you lose; an unresolved match draws after 15 minutes. The computer should contest the center and pressure a command post. Record the route and result.
6. Press **R** to return to faction choice and choose Regios. Confirm workers deliver five gold per trip and melee/ranged cost one more gold than Poblanos (4 and 5). Finish a Regios match by either route, checking the economy and district state along the way. Record any unclear rule text.
7. At the result, verify the HUD says the event is saved and pending sync. Quit the app, reopen it, and verify the saved state remains. Press **R** to choose a new match. Record the result and restart screens.
8. Once a fresh **internal QA invite code** is issued and the reviewed ingest version is deployed, enter it, turn Wi-Fi back on and press **F** to retry sync. Expect a synced **test** receipt; retry with **F** and confirm the receipt does not change. The operator checks that no public cohort event or numeric reading was created, including for a preview client that claims `test_account: false`. Without an invite code, pending sync is expected. The earlier `owner_qa_20261014` code was used and revoked on 2026-10-15; it cannot be reused for the new preview.

Before external invitations, verify that an anonymous visit cannot see the Restricted page and that a temporary download key works outside the creator session. Revoke the test key afterward. A Developer ID signature and notarization would remove the manual Gatekeeper step, but require Apple developer credentials that are not configured for this preview.
