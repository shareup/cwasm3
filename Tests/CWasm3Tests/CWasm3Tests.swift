import XCTest
@testable import CWasm3

final class CWasm3Tests: XCTestCase {
    func testCanCreateEnvironmentAndRuntime() {
        let environment = m3_NewEnvironment()
        defer { m3_FreeEnvironment(environment) }
        XCTAssertNotNil(environment)

        let runtime = m3_NewRuntime(environment, 512, nil)
        defer { m3_FreeRuntime(runtime) }
        XCTAssertNotNil(runtime)
    }

    static var allTests = [
        ("testCanCreateRuntime", testCanCreateEnvironmentAndRuntime),
    ]
}
