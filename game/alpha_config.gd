extends RefCounted

# The export script replaces this file in an isolated build copy. The source
# checkout always remains a test-only loopback client.
const ENDPOINT := "http://127.0.0.1:8787/v1/events"
const MATCH_ENDPOINT := "http://127.0.0.1:8790"
const TEST_ACCOUNT := true
const CHANNEL := "development"
const BUILD_ID := "local-debug"
const SIMULATION_HASH := "146914d0a35e2fc598290adf5e1d165c4206126edc36185dbe16bbda92f33c64"
