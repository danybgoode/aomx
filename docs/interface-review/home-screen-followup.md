# Home-screen identity follow-up — local QA

The owner supplied `references/homescreenart/homescreen.jpg` as the visual brief. This slice uses the existing owned jacaranda/city background and adds the main red La Roma wordmark, gold tagline, and a left navigation rail. The rail opens quick solo setup, an enabled campaign, private multiplayer join, a concise controls dialog, interface-size settings, or quits the native app. It is hidden on the narrow layout so setup remains usable. A disabled campaign tab explains why the chapter is unavailable.

The central setup keeps live controls for faction, mode, objective, map size, opponent, difficulty, recovery and Restricted join. The start button stays visible while the details scroll. Returning from a match through **MENU** shows the same home screen.

Local Godot 4.7.2 captures: [desktop 1920×1080](../screenshots/home-screen/home-desktop-1920.png), [narrow 390×844](../screenshots/home-screen/home-mobile-390.png). `skirmish_client_test.gd`, `campaign_client_test.gd` and `solo_team_client_test.gd` passed. These are source and render checks; owner acceptance on a freshly downloaded Web and macOS build is still owed. The production portrait illustrations and card treatments in the reference remain future art direction, so the current screen is not a pixel-for-pixel copy of that mockup.
