import XCTest

#if !canImport(ObjectiveC)
    public func allTests() -> [XCTestCaseEntry] {
        [
            testCase(CWasm3Tests.allTests),
        ]
    }
#endif
