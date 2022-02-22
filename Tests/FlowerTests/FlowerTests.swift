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
        let pongReceived: XCTestExpectation = XCTestExpectation(description: "pong received")
        let newPacket = "45000054edfa00004001baf10A000001080808080800335dde64021860f5bcab0009db7808090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f3031323334353637"
        
        guard var pingPacket = Data(hex: newPacket) else
        {
            XCTFail()
            return
        }
        
        guard let transmissionConnection: Transmission.Connection = TransmissionConnection(host: "159.203.108.187", port: 1234) else
        {
            XCTFail()
            return
        }
        
        let flowerConnection = FlowerConnection(connection: transmissionConnection, log: nil)
        

        guard let ipAssign = flowerConnection.readMessage() else
        {
          XCTFail()
          return
        }
        
        switch ipAssign
        {
            case .IPAssignV4(let ipv4Address):
                let addressData = ipv4Address.rawValue
                pingPacket[15] = addressData[3] // Some hackery to give the server our assigned IP
                pingPacket[14] = addressData[2]
                pingPacket[13] = addressData[1]
                pingPacket[12] = addressData[0]
            default:
                XCTFail()
                return
        }
        
        
        let message = Message.IPDataV4(pingPacket)
        flowerConnection.writeMessage(message: message)
        
        guard let receivedMessage = flowerConnection.readMessage() else
        {
            XCTFail()
            return
        }
        
        pongReceived.fulfill()
        wait(for: [pongReceived], timeout: 15) // 15 seconds
    }
    
    func testServerUDP()
    {
        let pongReceived: XCTestExpectation = XCTestExpectation(description: "pong received")
        let newPacket = "45000022231b0000401135c7c0a8016ba747b88edb3004d2000eba0968656c6c6f0a"
        
        guard var pingPacket = Data(hex: newPacket) else
        {
            XCTFail()
            return
        }
        
        guard let transmissionConnection: Transmission.Connection = TransmissionConnection(host: "138.197.196.245", port: 1234) else
        {
            XCTFail()
            return
        }
        
        let flowerConnection = FlowerConnection(connection: transmissionConnection, log: nil)
        

        guard let ipAssign = flowerConnection.readMessage() else
        {
          XCTFail()
          return
        }
        
        switch ipAssign
        {
            case .IPAssignV4(let ipv4Address):
                let addressData = ipv4Address.rawValue
                pingPacket[15] = addressData[3] // Some hackery to give the server our assigned IP
                pingPacket[14] = addressData[2]
                pingPacket[13] = addressData[1]
                pingPacket[12] = addressData[0]
            default:
                XCTFail()
                return
        }
        
        
        let message = Message.IPDataV4(pingPacket)
        flowerConnection.writeMessage(message: message)
        
        guard let receivedMessage = flowerConnection.readMessage() else
        {
            XCTFail()
            return
        }
        
        pongReceived.fulfill()
        wait(for: [pongReceived], timeout: 15) // 15 seconds
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
    
    func testReplicantSwiftServer()
    {
        guard let transmissionConnection: Transmission.Connection = TransmissionConnection(host: "host", port: 1234) else

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

        print(ipAssign)
        print("read")
    }

    static var allTests = [
        ("testServer", testServer),
    ]
}
