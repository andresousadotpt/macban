import Testing
@testable import MacbanCore

@Suite("AppVersion")
struct AppVersionTests {
    @Test("Marketing version is non-empty")
    func marketingVersionIsNonEmpty() {
        #expect(!AppVersion.marketing.isEmpty)
    }
}
