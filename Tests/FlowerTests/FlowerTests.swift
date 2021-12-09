import XCTest
@testable import Flower
import Datable
import Transmission
import Logging

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

    func testClientServer()
    {
        let logger = Logger(label: "FlowerTests")
        let queue = DispatchQueue(label: "FlowerTests.testClientServer.server")
        let lock = DispatchGroup()
        let serverRead = expectation(description: "server read")

        lock.enter()
        queue.async
        {
            guard let networkListener = TransmissionListener(port: 1234, logger: logger) else
            {
                XCTFail()
                return
            }

            let flowerListener = FlowerListener(listener: networkListener, logger: logger)
            lock.leave()

            let flowerConnection = flowerListener.accept()
            flowerConnection.writeMessage(message: .IPDataV4("server".data))
            let message = flowerConnection.readMessage()
            serverRead.fulfill()
        }
        lock.wait()

        guard let networkConnection = TransmissionConnection(host: "127.0.0.1", port: 1234) else
        {
            XCTFail()
            return
        }

        let flowerConnection = FlowerConnection(connection: networkConnection, log: logger)
        flowerConnection.writeMessage(message: .IPDataV4("client".data))
        let message = flowerConnection.readMessage()

        wait(for: [serverRead], timeout: 30)
    }

    static var allTests = [
        ("testServer", testServer),
    ]
}
