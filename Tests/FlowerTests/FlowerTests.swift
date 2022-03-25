import Datable
@testable import Flower
import InternetProtocols
import Logging
import Net
import Transmission
import XCTest

final class FlowerTests: XCTestCase
{
    func testUInt16()
    {
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

    func testServerUDPLocal()
    {
        let newPacket = "45000021cbcb0000401100007f0000017f000001de1b04d2000dfe20746573740a"
        
        guard var pingPacket = Data(hex: newPacket) else
        {
            XCTFail()
            return
        }
        
        guard let transmissionConnection: Transmission.Connection = TransmissionConnection(host: "127.0.0.1", port: 1234) else
        {
            XCTFail()
            return
        }
        
        let flowerConnection = FlowerConnection(connection: transmissionConnection, log: nil)
        
        // make IP request
        let ipRequest = Message.IPRequestV4
        flowerConnection.writeMessage(message: ipRequest)
        
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

        Thread.sleep(forTimeInterval: 1)
    }

    func testServerTCP()
    {
        let newPacket = "45000000d4310000ff0600000a080002cebdada404d20050000001c6000000005002d0167bd3000048656c6c6f2c20686f772061726520796f75"

        guard var pingPacket = Data(hex: newPacket) else
        {
            XCTFail()
            return
        }

        guard let transmissionConnection: Transmission.Connection = TransmissionConnection(host: "206.189.200.18", port: 1234) else
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

        Thread.sleep(forTimeInterval: 1)
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

            do
            {
                let flowerConnection = try flowerListener.accept()
                flowerConnection.writeMessage(message: .IPDataV4("server".data))
                let message = flowerConnection.readMessage()
                serverRead.fulfill()
            }
            catch
            {
                print(error)
                XCTFail()
            }
            
            return
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
    
    func testServerUDP2()
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
    
    func testServerUDP3()
    {
        let pongReceived: XCTestExpectation = XCTestExpectation(description: "pong received")
        let newPacket = "450000258ad100004011ef41c0a801e79fcb9e5adf5104d200115d4268656c6c6f6f6f6f0a"

        guard var pingPacket = Data(hex: newPacket) else
        {
            XCTFail()
            return
        }
        
//        guard let transmissionConnection: Transmission.Connection = TransmissionConnection(host: "159.203.108.187", port: 1234) else
        guard let transmissionConnection: Transmission.Connection = TransmissionConnection(host: "127.0.0.1", port: 1234) else
        {
            XCTFail()
            return
        }
        
        let flowerConnection = FlowerConnection(connection: transmissionConnection, log: nil)
        
        var message = Message.IPRequestV4
        flowerConnection.writeMessage(message: message)

        guard let ipAssign = flowerConnection.readMessage() else
        {
          XCTFail()
          return
        }

        switch ipAssign
        {
            case .IPAssignV4(let ipv4Address):
//                guard let udp = UDP(sourcePort: 4567, destinationPort: 5678, payload: "test".data) else
//                {
//                    XCTFail()
//                    return
//                }
//
//                guard let ipv4 = try? IPv4(sourceAddress: IPv4Address("127.0.0.1")!, destinationAddress: ipv4Address, payload: udp.data, protocolNumber: IPprotocolNumber.UDP) else
//                {
//                    XCTFail()
//                    return
//                }
//
//                let pingPacket = ipv4.data

                let addressData = ipv4Address.rawValue
                // Some hackery to give the server our assigned IP
                pingPacket[15] = addressData[3]
                pingPacket[14] = addressData[2]
                pingPacket[13] = addressData[1]
                pingPacket[12] = addressData[0]

                pingPacket[16] = 127
                pingPacket[17] = 0
                pingPacket[18] = 0
                pingPacket[19] = 1

                message = Message.IPDataV4(pingPacket)
                flowerConnection.writeMessage(message: message)

            default:
                XCTFail()
                return
        }

        guard let receivedMessage = flowerConnection.readMessage() else
        {
            XCTFail()
            return
        }

        print(receivedMessage)

        switch receivedMessage
        {
            case .IPDataV4(let data):
                let packet = Packet(ipv4Bytes: data, timestamp: Date(), debugPrints: true)
                print(packet)
                if let udp = packet.udp
                {
                    if let payload = udp.payload
                    {
                        print(payload.string)
                    }
                    else
                    {
                        print("Not UDP")
                    }
                }
                else
                {
                    print("Not IPv4")
                }
            default:
                print("Unknown message \(receivedMessage)")
                XCTFail()
                return
        }

        pongReceived.fulfill()
        wait(for: [pongReceived], timeout: 15) // 15 seconds
    }

    static var allTests = [
        ("testServer", testServer),
    ]
}
