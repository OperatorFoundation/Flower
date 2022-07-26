import Foundation

import Datable
import Net


public enum MessageType: UInt8
{
    case TCPOpenV4Type = 0
    case TCPOpenV6Type = 1
    case TCPCloseType = 2
    case TCPDataType = 3
    case UDPDataV4Type = 4
    case UDPDataV6Type = 5
    case IPAssignV4Type = 6
    case IPAssignV6Type = 7
    case IPAssignDualStackType = 8
    case IPDataV4Type = 9
    case IPDataV6Type = 10
    case IPRequestV4Type = 11
    case IPRequestV6Type = 12
    case IPRequestDualStackType = 13
    case IPReuseV4Type = 14
    case IPReuseV6Type = 15
    case IPReuseDualStackType = 16
    case ICMPDataV4Type = 17
    case ICMPDataV6Type = 18
}

public typealias StreamIdentifier = UInt64

public func generateStreamID(source: EndpointV4, destination: EndpointV4) -> UInt64
{
    var hasher = Hasher()
    hasher.combine(source)
    hasher.combine(destination)
    
    return UInt64(hasher.finalize())
}

public struct EndpointV4: MaybeDatable, Hashable, Comparable
{
    public let host: IPv4Address
    public let port: NWEndpoint.Port

    public var data: Data
    {
        var result = Data()
        result.append(port.data)
        result.append(host.data)
        return result
    }
    
    public init(host: IPv4Address, port: NWEndpoint.Port)
    {
        self.host = host
        self.port = port
    }
    
    public init?(data: Data)
    {
        guard let (portData, tail) = data.splitOn(position: 2) else
        {
            return nil
        }
        
        let p = NWEndpoint.Port(integerLiteral: portData.uint16!)
        
        port = p
        
        guard let address = IPv4Address.init(tail) else
        {
            return nil
        }
        
        host = address
    }
    
    public static func < (lhs: EndpointV4, rhs: EndpointV4) -> Bool
    {
        if lhs.host.rawValue.lexicographicallyPrecedes(rhs.host.rawValue)
        {
            return true
        }
        else if rhs.host.rawValue.lexicographicallyPrecedes(lhs.host.rawValue)
        {
            return false
        }
        else
        {
            return lhs.port.rawValue < rhs.port.rawValue
        }
    }
}

public struct EndpointV6: MaybeDatable, Hashable, Comparable
{
    public let host: IPv6Address
    public let port: NWEndpoint.Port
    
    public var data: Data
    {
        var result = Data()
        result.append(port.data)
        result.append(host.data)
        return result
    }
    
    public init(host: IPv6Address, port: NWEndpoint.Port)
    {
        self.host = host
        self.port = port
    }

    public init?(data: Data)
    {
        guard let (portData, tail) = data.splitOn(position: 2) else
        {
            return nil
        }

        let p = NWEndpoint.Port(integerLiteral: portData.uint16!)


        port = p

        guard let address = IPv6Address.init(tail) else
        {
            return nil
        }

        host = address
    }
    
    public static func < (lhs: EndpointV6, rhs: EndpointV6) -> Bool
    {
        if lhs.host.rawValue.lexicographicallyPrecedes(rhs.host.rawValue)
        {
            return true
        }
        else if rhs.host.rawValue.lexicographicallyPrecedes(lhs.host.rawValue)
        {
            return false
        }
        else
        {
            return lhs.port.rawValue < rhs.port.rawValue
        }
    }
    
}

public enum Message
{
    case TCPOpenV4(EndpointV4, StreamIdentifier)
    case TCPOpenV6(EndpointV6, StreamIdentifier)
    case TCPClose(StreamIdentifier)
    case TCPData(StreamIdentifier, Data)
    case UDPDataV4(EndpointV4, Data)
    case UDPDataV6(EndpointV6, Data)
    case IPAssignV4(IPv4Address)
    case IPAssignV6(IPv6Address)
    case IPAssignDualStack(IPv4Address, IPv6Address)
    case IPDataV4(Data)
    case IPDataV6(Data)
    case IPRequestV4
    case IPRequestV6
    case IPRequestDualStack
    case IPReuseV4(IPv4Address)
    case IPReuseV6(IPv6Address)
    case IPReuseDualStack(IPv4Address, IPv6Address)
    case ICMPDataV4(IPv4Address, Data)
    case ICMPDataV6(IPv6Address, Data)
}

extension Message: MaybeDatable
{
    public init?(data: Data)
    {
        guard let (messageTypeByte, tail) = data.splitOn(position: 1) else
        {
            print("Flower.Message.init: Failed to initialize a Message. Unable to split the data of size \(data.count) on position 1.")
            return nil
        }
        
        guard let messageType = MessageType.init(rawValue: messageTypeByte[0]) else
        {
            print("Failed to initialize a Message. Message type byte of \(messageTypeByte[0]) is invalid.")
            return nil
        }
        
        switch messageType
        {
            case .TCPOpenV4Type:
                let endpointSize = AddressSize.v4.rawValue + 2
                guard let (dstData, streamidData) = tail.splitOn(position: UInt(endpointSize)) else
                {
                    print("Flower.Message.init: Failed to initialize a TCPOpenV4Type Message.")
                    return nil
                }

                guard let dst = EndpointV4(data: dstData) else
                {
                    print("Flower.Message.init: Failed to initialize a TCPOpenV4Type Message.")
                    return nil
                }
                
                let streamid = streamidData.uint64!
                
                self = .TCPOpenV4(dst, streamid)
            case .TCPOpenV6Type:
                let endpointSize = AddressSize.v6.rawValue + 2
                guard let (dstData, streamidData) = tail.splitOn(position: UInt(endpointSize)) else
                {
                    print("Flower.Message.init: Failed to initialize a TCPOpenV6Type Message.")
                    return nil
                }

                guard let dst = EndpointV6(data: dstData) else
                {
                    print("Flower.Message.init: Failed to initialize a TCPOpenV6Type Message.")
                    return nil
                }

                let streamid = streamidData.uint64!

                self = .TCPOpenV6(dst, streamid)
            case .TCPCloseType:
                let streamid = tail.uint64!

                self = .TCPClose(streamid)
            case .TCPDataType:
                let endpointSize = AddressSize.v4.rawValue + 2
                guard let (streamidData, payload) = tail.splitOn(position: UInt(endpointSize)) else
                {
                    print("Flower.Message.init: Failed to initialize a TCPDataType Message.")
                    return nil
                }

                let streamid = streamidData.uint64!
                
                self = .TCPData(streamid, payload)
            case .UDPDataV4Type:
                let endpointSize = AddressSize.v4.rawValue + 2
                guard let (dstData, payload) = tail.splitOn(position: UInt(endpointSize)) else
                {
                    print("Flower.Message.init: Failed to initialize a UDPDataV4Type Message.")
                    return nil
                }
                
                guard let dst = EndpointV4(data: dstData) else
                {
                    print("Flower.Message.init: Failed to initialize a UDPDataV4Type Message.")
                    return nil
                }
                
                self = .UDPDataV4(dst, payload)
            case .UDPDataV6Type:
                let endpointSize = AddressSize.v6.rawValue + 2
                guard let (dstData, payload) = tail.splitOn(position: UInt(endpointSize)) else
                {
                    print("Flower.Message.init: Failed to initialize a UDPDataV6Type Message.")
                    return nil
                }

                guard let dst = EndpointV6(data: dstData) else
                {
                    print("Flower.Message.init: Failed to initialize a UDPDataV6Type Message.")
                    return nil
                }

                self = .UDPDataV6(dst, payload)
            case .IPDataV4Type:
                self = .IPDataV4(tail)
            case .IPDataV6Type:
                self = .IPDataV6(tail)
            case .IPAssignV4Type:
                guard let ip = IPv4Address(data: tail) else
                {
                    print("Flower.Message.init: Failed to initialize a IPAssignV4Type Message.")
                    return nil
                }
               
                self = .IPAssignV4(ip)
            case .IPAssignV6Type:
                guard let ip = IPv6Address(data: tail) else
                {
                    print("Flower.Message.init: Failed to initialize a IPAssignV6Type Message.")
                    return nil
                }

                self = .IPAssignV6(ip)
            case .IPAssignDualStackType:
                guard let (ipv4Bytes, ipv6Bytes) = tail.splitOn(position: UInt(AddressSize.v4.rawValue)) else
                {
                    print("Flower.Message.init: Failed to initialize a IPAssignDualStackType Message.")
                    return nil
                }
            
                guard let ipv4 = IPv4Address(data: ipv4Bytes) else
                {
                    print("Flower.Message.init: Failed to initialize a IPAssignDualStackType Message.")
                    return nil
                }
                
                guard let ipv6 = IPv6Address(data: ipv6Bytes) else
                {
                    print("Flower.Message.init: Failed to initialize a IPAssignDualStackType Message.")
                    return nil
                }
            
                self = .IPAssignDualStack(ipv4, ipv6)
            case .IPRequestV4Type:
                self = .IPRequestV4
            case .IPRequestV6Type:
                self = .IPRequestV6
            case .IPRequestDualStackType:
                self = .IPRequestDualStack
            case .IPReuseV4Type:
                guard let ip = IPv4Address(data: tail) else
                {
                    print("Flower.Message.init: Failed to initialize a IPReuseV4Type Message.")
                    return nil
                }

                self = .IPReuseV4(ip)
            case .IPReuseV6Type:
                guard let ip = IPv6Address(data: tail) else
                {
                    print("Flower.Message.init: Failed to initialize a IPReuseV6Type Message.")
                    return nil
                }

                self = .IPReuseV6(ip)
            case .IPReuseDualStackType:
                guard let (ipv4Bytes, ipv6Bytes) = tail.splitOn(position: UInt(AddressSize.v4.rawValue)) else
                {
                    print("Flower.Message.init: Failed to initialize a  IPReuseDualStackType Message.")
                    return nil
                }

                guard let ipv4 = IPv4Address(data: ipv4Bytes) else {return nil}
                guard let ipv6 = IPv6Address(data: ipv6Bytes) else {return nil}

                self = .IPReuseDualStack(ipv4, ipv6)
            case .ICMPDataV4Type:
                guard let (ipv4Bytes, data) = tail.splitOn(position: UInt(AddressSize.v4.rawValue)) else
                {
                    print("Flower.Message.init: Failed to initialize a ICMPDataV4Type Message.")
                    return nil
                }

                guard let ipv4 = IPv4Address(data: ipv4Bytes) else {return nil}

                self = .ICMPDataV4(ipv4, data)
            case .ICMPDataV6Type:
                guard let (ipv6Bytes, data) = tail.splitOn(position: UInt(AddressSize.v6.rawValue)) else
                {
                    print("Flower.Message.init: Failed to initialize a ICMPDataV6Type Message.")
                    return nil
                }

                guard let ipv6 = IPv6Address(data: ipv6Bytes) else {return nil}

                self = .ICMPDataV6(ipv6, data)
         }
    }
    
    public var data: Data
    {
        var result = Data()
        switch self
        {
            case .TCPOpenV4(let dst, let streamid):
                result.append(MessageType.TCPOpenV4Type.rawValue)
                result.append(dst.data)
                result.append(streamid.data)
            case .TCPOpenV6(let dst, let streamid):
                result.append(MessageType.TCPOpenV6Type.rawValue)
                result.append(dst.data)
                result.append(streamid.data)
            case .TCPClose(let streamid):
                result.append(MessageType.TCPCloseType.rawValue)
                result.append(streamid.data)
            case .TCPData(let streamid, let payload):
                result.append(MessageType.TCPDataType.rawValue)
                result.append(streamid.data)
                result.append(payload)
            case .UDPDataV4(let dst, let payload):
                result.append(MessageType.UDPDataV4Type.rawValue)
                result.append(dst.data)
                result.append(payload)
            case .UDPDataV6(let dst, let payload):
                result.append(MessageType.UDPDataV6Type.rawValue)
                result.append(dst.data)
                result.append(payload)
            case .IPDataV4(let payload):
                result.append(MessageType.IPDataV4Type.rawValue)
                result.append(payload)
            case .IPDataV6(let payload):
                result.append(MessageType.IPDataV6Type.rawValue)
                result.append(payload)
            case .IPAssignV4(let ip):
                result.append(MessageType.IPAssignV4Type.rawValue)
                result.append(ip.data)
            case .IPAssignV6(let ip):
                result.append(MessageType.IPAssignV4Type.rawValue)
                result.append(ip.data)
            case .IPAssignDualStack(let ipv4, let ipv6):
                result.append(MessageType.IPAssignDualStackType.rawValue)
                result.append(ipv4.data)
                result.append(ipv6.data)
            case .IPRequestV4:
                result.append(MessageType.IPRequestV4Type.rawValue)
            case .IPRequestV6:
                result.append(MessageType.IPRequestV6Type.rawValue)
            case .IPRequestDualStack:
                result.append(MessageType.IPRequestDualStackType.rawValue)
            case .IPReuseV4(let ip):
                result.append(MessageType.IPAssignV4Type.rawValue)
                result.append(ip.data)
            case .IPReuseV6(let ip):
                result.append(MessageType.IPAssignV4Type.rawValue)
                result.append(ip.data)
            case .IPReuseDualStack(let ipv4, let ipv6):
                result.append(MessageType.IPAssignDualStackType.rawValue)
                result.append(ipv4.data)
                result.append(ipv6.data)
            case .ICMPDataV4(let ipv4, let payload):
                result.append(MessageType.ICMPDataV4Type.rawValue)
                result.append(ipv4.data)
                result.append(payload)
            case .ICMPDataV6(let ipv6, let payload):
                result.append(MessageType.ICMPDataV6Type.rawValue)
                result.append(ipv6.data)
                result.append(payload)
        }
        
        return result
    }
}

extension Message: CustomStringConvertible
{
    public var description: String {
        switch self
        {
            case .IPAssignV4(let ipv4Address):
                return """
                IPAssignV4
                IP: \(ipv4Address)
                """
            case .IPAssignV6(let ipv6Address):
                return """
                IPAssignV6
                ip: \(ipv6Address)
                """
            case .IPAssignDualStack(let ipv4Address, let ipv6Address):
                return """
                IPAssignDualStack
                IPv4: \(ipv4Address)
                IPv6: \(ipv6Address)
                """
            case .IPDataV4(let data):
                return """
                IPDataV4
                data: \(data)
                """
            case .IPDataV6(let data):
                return """
                IPDataV6
                data: \(data)
                """
            case .TCPClose(let streamIdentifer):
                return """
                TCPClose
                StreamIdentifier: \(streamIdentifer)
                """
            case .TCPData(let streamIdentifer, let data):
                return """
                TCPData
                streamIdentifier: \(streamIdentifer)
                data: \(data)
                """
            case .TCPOpenV4(let endpointV4, let streamIdentifier):
                return """
                TCPOpenV4
                endpointV4: \(endpointV4)
                streamIdentifier: \(streamIdentifier)
                """
            case .TCPOpenV6(let endpointV6, let streamIdentifier):
                return """
                TCPOpenV6
                endpointV6: \(endpointV6)
                streamIdentifier: \(streamIdentifier)
                """
            case .UDPDataV4(let endpointV4, let data):
                return """
                UDPDataV4
                endpointV4: \(endpointV4)
                data: \(data))
                """
            case .UDPDataV6(let endpointV6, let data):
                return """
                UDPDataV6
                endpointV6: \(endpointV6)
                data: \(data)
                """
            case .IPRequestV4:
                return """
                IPRequestV4
                """
            case .IPRequestV6:
                return """
                IPRequestV6
                """
            case .IPRequestDualStack:
                return """
                IPRequestDualStack
                """
            case .IPReuseV4(let ipv4Address):
                return """
                IPReuseV4
                IP: \(ipv4Address)
                """
            case .IPReuseV6(let ipv6Address):
                return """
                IPReuseV6
                ip: \(ipv6Address)
                """
            case .IPReuseDualStack(let ipv4Address, let ipv6Address):
                return """
                IPReuseDualStack
                IPv4: \(ipv4Address)
                IPv6: \(ipv6Address)
                """
            case .ICMPDataV4(let ipv4Address, let data):
                return """
                ICMPDataV4
                IPv4: \(ipv4Address)
                Data: \(data)
                """
            case .ICMPDataV6(let ipv6Address, let data):
                return """
                ICMPDataV6
                IPv6: \(ipv6Address)
                Data: \(data)
                """
        }
    }
}
