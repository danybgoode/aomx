extends RefCounted

# The export script replaces this file in an isolated build copy. The source
# checkout always remains a test-only loopback client.
const ENDPOINT := "http://127.0.0.1:8787/v1/events"
const MATCH_ENDPOINT := "http://127.0.0.1:8790"
const TEST_ACCOUNT := true
const CHANNEL := "development"
const BUILD_ID := "local-debug"
const SIMULATION_HASH := "1861b72f20ce6d92b54369d20233459bbf1dc6c2be1d022b91fe842307da09cd"
