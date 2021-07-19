import XCTest
@testable import Flower
import Datable

final class FlowerTests: XCTestCase {
    func testExample() {
    }

    func testUInt16() {
        let uint: UInt16 = 99
        let data = uint.data
        print(data.array)
        let result = data.uint16
        XCTAssertEqual(uint, result)
    }
    
    static var allTests = [
        ("testExample", testExample),
    ]
}
