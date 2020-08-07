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

        var module: IM3Module?
        XCTAssertNil(m3_ParseModule(environment, &module, addBytes, UInt32(addBytes.count)))
        XCTAssertNil(m3_LoadModule(runtime, module))

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

    func testCanCallAndReceiveReturnValueFromFibonacci() throws {
        let environment = m3_NewEnvironment()
        defer { m3_FreeEnvironment(environment) }

        let runtime = m3_NewRuntime(environment, 1 * 1024 * 1024, nil)
        defer { m3_FreeRuntime(runtime) }

        var fibonacciBytes = try fibonacciWasm()
        defer { fibonacciBytes.removeAll() }

        var module: IM3Module?
        XCTAssertNil(m3_ParseModule(environment, &module, fibonacciBytes, UInt32(fibonacciBytes.count)))
        XCTAssertNil(m3_LoadModule(runtime, module))

        var fibonacciFunction: IM3Function?
        XCTAssertNil(m3_FindFunction(&fibonacciFunction, runtime, "fib"))

        let result = ["25"].withCStrings { (arguments) -> Int64 in
            var mutableArguments = arguments
            let size = UnsafeMutablePointer<Int>.allocate(capacity: 1)
            let output = UnsafeMutablePointer<Int64>.allocate(capacity: 1)
            XCTAssertNil(wasm3_CallWithArgs(fibonacciFunction, UInt32(1), &mutableArguments, size, output))
            XCTAssertEqual(MemoryLayout<Int64>.size, size.pointee)
            return output.pointee
        }

        XCTAssertEqual(75025, result)
    }

    func testImportingNativeFunction() throws {
        let environment = m3_NewEnvironment()
        defer { m3_FreeEnvironment(environment) }

        let runtime = m3_NewRuntime(environment, 512, nil)
        defer { m3_FreeRuntime(runtime) }

        var simpleImportBytes = try simpleImport()
        defer { simpleImportBytes.removeAll() }

        var module: IM3Module?
        XCTAssertNil(m3_ParseModule(environment, &module, simpleImportBytes, UInt32(simpleImportBytes.count)))
        XCTAssertNil(m3_LoadModule(runtime, module))

        // The imported function needs to linked before the exported function can be referenced.
        XCTAssertNil(m3_LinkRawFunction(
            module, "imports", "imported_func", "i(I i)", simpleImport(runtime:stackPointer:memory:)
        ))

        var exportedFunction: IM3Function?
        XCTAssertNil(m3_FindFunction(&exportedFunction, runtime, "exported_func"))

        let result = [].withCStrings { (arguments) -> Int32 in
            var mutableArguments = arguments
            let size = UnsafeMutablePointer<Int>.allocate(capacity: 1)
            let output = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
            let result = wasm3_CallWithArgs(exportedFunction, UInt32(0), &mutableArguments, size, output)
            XCTAssertNil(result)
            XCTAssertEqual(MemoryLayout<Int32>.size, size.pointee)
            return output.pointee
        }

        XCTAssertEqual(1, result)
    }

//    try vm.link(function: "imported_func", namespace: "imports", signature: "v(I I)", block: imported_func(runtime:stackPointer:memory:))

//    public typealias ImportFunction = @convention(c) (IM3Runtime?, UnsafeMutablePointer<UInt64>?, UnsafeMutableRawPointer?) -> UnsafeRawPointer?
//
//        public func link(
//            function name: String,
//            namespace: String,
//            signature: String,
//            block: ImportFunction?
//    //        typedef const void * (* M3RawCall) (IM3Runtime runtime, uint64_t * _sp, void * _mem);
//        ) throws {
//
//            try check(m3_LinkRawFunction(_moduleCache.keys.first!, namespace, name, signature, block))
//        }

//I was thinking of some tests we could write for the wasm package to make sure memory access is working. We are only writing bytes of a certain length at a memory address. I think we could add a function to the wat that does that and then we write “hello” at an address and then we call a function with the address and have it read five bytes and if it’s “hello” then return 0 else 1. If you want to work on that (or something like it) later today let me know.

    static var allTests = [
        ("testCanCreateEnvironmentAndRuntime", testCanCreateEnvironmentAndRuntime),
        ("testCanCallAndReceiveReturnValueFromAdd", testCanCallAndReceiveReturnValueFromAdd),
        ("testCanCallAndReceiveReturnValueFromFibonacci", testCanCallAndReceiveReturnValueFromFibonacci),
        ("testImportingNativeFunction", testImportingNativeFunction),
    ]
}

private func simpleImport(
    runtime: IM3Runtime?,
    stackPointer: UnsafeMutablePointer<UInt64>?,
    memory: UnsafeMutableRawPointer?
) -> UnsafeRawPointer? {
    let size = MemoryLayout<CChar>.size
    let alignment = MemoryLayout<CChar>.alignment

    let pointer: UnsafeMutableRawPointer = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: alignment)
    defer { pointer.deallocate() }

    pointer.storeBytes(of: CChar(exactly: 0)!, as: CChar.self) // Default to `false`

    guard let stackPointer = stackPointer else { return UnsafeRawPointer(pointer) }

    let firstArg = stackPointer.pointee
    let secondArg: Int32 = stackPointer.withMemoryRebound(to: Int32.self, capacity: 4) { $0.advanced(by: 2).pointee }

    if firstArg == Int64(42) && secondArg == Int32(-3333) {
        pointer.storeBytes(of: CChar(exactly: 1)!, as: CChar.self) // `true`
        return UnsafeRawPointer(pointer)
    } else {
        return UnsafeRawPointer(pointer)
    }
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

    private func simpleImport() throws -> Array<UInt8> {
        let base64 = "AGFzbQEAAAABCwJgAn5/AX9gAAF/AhkBB2ltcG9ydHMNaW1wb3J0ZWRfZnVuYwAAAwIBAQcRAQ1leHBvcnRlZF9mdW5jAAEKEQEPAQF/QipB+2UQACAAIQAL"
        guard let data = Data(base64Encoded: base64) else { throw TestError.couldNotDecodeWasm("simple-import.wasm") }
        return Array<UInt8>(data)
    }
}
