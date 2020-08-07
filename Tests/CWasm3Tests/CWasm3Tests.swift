import XCTest
@testable import CWasm3

final class CWasm3Tests: XCTestCase {
    func testCanCreateEnvironmentAndRuntime() throws {
        let environment = m3_NewEnvironment()
        defer { m3_FreeEnvironment(environment) }
        XCTAssertNotNil(environment)

        let runtime = m3_NewRuntime(environment, 512, nil)
        defer { m3_FreeRuntime(runtime) }
        XCTAssertNotNil(runtime)
    }

    func testCanCallAndReceiveReturnValueFromAdd() throws {
        let environment = m3_NewEnvironment()
        defer { m3_FreeEnvironment(environment) }

        let runtime = m3_NewRuntime(environment, 512, nil)
        defer { m3_FreeRuntime(runtime) }

        var addBytes = try addWasm()
        defer { addBytes.removeAll() }

        var addModule: IM3Module?
        XCTAssertNil(m3_ParseModule(environment, &addModule, addBytes, UInt32(addBytes.count)))
        XCTAssertNil(m3_LoadModule(runtime, addModule))

        var addFunction: IM3Function?
        XCTAssertNil(m3_FindFunction(&addFunction, runtime, "add"))

        let result = ["3", "12345"].withCStrings { (arguments) -> Int32 in
            var mutableArguments = arguments
            let size = UnsafeMutablePointer<Int>.allocate(capacity: 1)
            let output = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
            XCTAssertNil(wasm3_CallWithArgs(addFunction, UInt32(2), &mutableArguments, size, output))
            XCTAssertEqual(MemoryLayout<Int32>.size, size.pointee)
            return output.pointee
        }

        XCTAssertEqual(12348, result)
    }

    static var allTests = [
        ("testCanCreateEnvironmentAndRuntime", testCanCreateEnvironmentAndRuntime),
        ("testCanCallAndReceiveReturnValueFromAdd", testCanCallAndReceiveReturnValueFromAdd),
    ]
}

extension CWasm3Tests {
    private enum TestError: Error {
        case couldNotDecodeWasm(String)
        case couldNotLoadResource(String)
    }

    private func addWasm() throws -> Array<UInt8> {
        let base64 = "AGFzbQEAAAABBwFgAn9/AX8DAgEABwcBA2FkZAAACgkBBwAgACABags="
        guard let data = Data(base64Encoded: base64) else { throw TestError.couldNotDecodeWasm("add.wasm") }
        return Array<UInt8>(data)
    }

    private func fibonacciWasm() throws -> Array<UInt8> {
        let base64 = "AGFzbQEAAAABBgFgAX4BfgMCAQAHBwEDZmliAAAKHwEdACAAQgJUBEAgAA8LIABCAn0QACAAQgF9EAB8Dws="
        guard let data = Data(base64Encoded: base64) else { throw TestError.couldNotDecodeWasm("fib64.wasm") }
        return Array<UInt8>(data)
    }
}
