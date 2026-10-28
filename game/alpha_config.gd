extends RefCounted

# The export script replaces this file in an isolated build copy. The source
# checkout always remains a test-only loopback client.
const ENDPOINT := "http://127.0.0.1:8787/v1/events"
const MATCH_ENDPOINT := "http://127.0.0.1:8790"
const TEST_ACCOUNT := true
const CHANNEL := "development"
const BUILD_ID := "local-debug"
const SIMULATION_HASH := "1c36f8538337a3c5dcd5859d0c451b7eb589415b3c478d1f0709c630888724b7"
