
@testable import Flower

#if os(macOS) || os(iOS)
import os.log
#else
import Logging
#endif

import XCTest

import Datable
import InternetProtocols
import Net
import Transmission


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
    
    func testCodableHost() throws
    {
        guard let ipv4 = IPv4Address("8.8.8.8") else
        {
            XCTFail()
            return
        }
        
        print("ipv4: \(ipv4.debugDescription)")
        
        guard let ipv4Host = NWEndpoint.Host(data: ipv4.rawValue) else
        {
            XCTFail()
            return
        }
        
        print("ipv4Host: \(ipv4Host.debugDescription)")
        
        let encoder = JSONEncoder()
        let hostJSON = try encoder.encode(ipv4Host)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(NWEndpoint.Host.self, from: hostJSON)
        
        print("Decoded ipv4Host: \(decoded)")
        
        XCTAssert(ipv4Host == decoded)
    }
    
    func testCodableIPV4() throws
    {
        guard let ipv4 = IPv4Address("8.8.8.8") else
        {
            XCTFail()
            return
        }
        
        print("ipv4: \(ipv4.debugDescription)")
        
        let encoder = JSONEncoder()
        let ipv4JSON = try encoder.encode(ipv4)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(IPv4Address.self, from: ipv4JSON)
        
        print("Decoded ipv4: \(decoded)")
        
        XCTAssert(ipv4 == decoded)
    }
    
    func testCodablePort() throws
    {
        let port = NWEndpoint.Port(1122)
        
        print("port: \(port.debugDescription)")
        
        let encoder = JSONEncoder()
        let portJSON = try encoder.encode(port)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(NWEndpoint.Port.self, from: portJSON)
        
        print("Decoded port: \(decoded)")
        
        XCTAssert(port == decoded)
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
        
        guard let transmissionConnection: Transmission.Connection = TransmissionConnection(host: "", port: 1234) else
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
        
        guard flowerConnection.readMessage() != nil else
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

        guard let receiveMessage = flowerConnection.readMessage() else
        {
          XCTFail()
          return
        }
        
        print(receiveMessage)
        
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

        guard let transmissionConnection: Transmission.Connection = TransmissionConnection(host: "164.92.71.230", port: 1234) else
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
        #if os(macOS) || os(iOS)
        let logger = Logger(subsystem: "org.OperatorFoundation.Flower", category: "FlowerTests")
        #else
        let logger = Logger(label: "org.OperatorFoundation.Flower")
        #endif
        
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
                _ = flowerConnection.readMessage()
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
        _ = flowerConnection.readMessage()

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
        
        guard flowerConnection.readMessage() != nil else
        {
            XCTFail()
            return
        }
        
        pongReceived.fulfill()
        wait(for: [pongReceived], timeout: 15) // 15 seconds
    }

    // To run this test, you need a netcat running on the same machine as the Persona server
    // nc -k -u -l 1234
    // This nc only lasts for one test, and then you will need to restart it.
    // On the nc, you should see "helloooo"
    // After that, type something back into the netcat
    // This should be routed through Persona back to the FlowerTest, and then the FlowerTest should succeed.
    // You might need to change the host for the TransmissionConnection if you are running the Persona server on Digital Ocean.
    // For instance, if you are running a similar test on Android then you cannot use 127.0.0.1 for a server host.
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
        guard let transmissionConnection: Transmission.Connection = TransmissionConnection(host: "164.92.71.230", port: 1234) else
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
                        print("No payload")
                        print(data.hex)
                    }
                }
                else
                {
                    print("Not UDP")
                }
            default:
                print("Unknown message \(receivedMessage)")
                XCTFail()
                return
        }

        pongReceived.fulfill()
        wait(for: [pongReceived], timeout: 15) // 15 seconds
    }

    // To run this test, you need a netcat running on the same machine as the Persona server
    // nc -k -l 5678
    // This nc only lasts for one test, and then you will need to restart it.
    // On the nc, you should see "helloooo"
    // After that, type something back into the netcat
    // This should be routed through Persona back to the FlowerTest, and then the FlowerTest should succeed.
    // You might need to change the host for the TransmissionConnection if you are running the Persona server on Digital Ocean.
    // For instance, if you are running a similar test on Android then you cannot use 127.0.0.1 for a server host.
    func testServerTCP3()
    {
        let pongReceived: XCTestExpectation = XCTestExpectation(description: "pong received")
        let newPacket = "4500004000004000400600007f0000017f000001c87f162e8ea91a7500000000b002fffffe34000002043fd8010303060101080abdd993230000000004020000"

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
                if let tcp = packet.tcp
                {
                    if let payload = tcp.payload
                    {
                        print(payload.string)
                    }
                    else
                    {
                        print("No payload")
                        print(data.hex)
                    }
                }
                else
                {
                    print("Not TCP")
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


