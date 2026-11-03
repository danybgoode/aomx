extends RefCounted

# The export script replaces this file in an isolated build copy. The source
# checkout always remains a test-only loopback client.
const ENDPOINT := "http://127.0.0.1:8787/v1/events"
const MATCH_ENDPOINT := "http://127.0.0.1:8790"
const TEST_ACCOUNT := true
const CHANNEL := "development"
const BUILD_ID := "local-debug"
const SIMULATION_HASH := "8936e804e4d93f93af1260846c4beac698723074a8612c73db96b353021bea38"
