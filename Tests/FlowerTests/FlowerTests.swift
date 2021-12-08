import XCTest
@testable import Flower
import Datable
import Transmission

final class FlowerTests: XCTestCase {
    func testUInt16() {
        let uint: UInt16 = 99
        let data = uint.data
        print(data.array)
        let result = data.uint16
        XCTAssertEqual(uint, result)
    }

    func testServer()
    {
        guard let transmissionConnection: Transmission.Connection = TransmissionConnection(host: "127.0.0.1", port: 1234) else

        {
            XCTFail()
            return
        }
        
        let flowerConnection = FlowerConnection(connection: transmissionConnection, log: nil)
        let data = "a".data
        let message = Message.IPDataV4(data)

        print("wrote")

        flowerConnection.writeMessage(message: message)

        guard let ipAssign = flowerConnection.readMessage() else
        {
          XCTFail()
          return
        }

        print("read")
    }
    
    static var allTests = [
        ("testServer", testServer),
    ]
}
