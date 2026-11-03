extends RefCounted

# The export script replaces this file in an isolated build copy. The source
# checkout always remains a test-only loopback client.
const ENDPOINT := "http://127.0.0.1:8787/v1/events"
const MATCH_ENDPOINT := "http://127.0.0.1:8790"
const TEST_ACCOUNT := true
const CHANNEL := "development"
const BUILD_ID := "local-debug"
const SIMULATION_HASH := "86f54e37b681ae43fd4b176357e6ad5bccd639e2d0c95bdb442294fb56562e05"
