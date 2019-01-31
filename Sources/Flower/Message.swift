import Foundation
import Network
import Datable

public enum MessageType: UInt8
{
    case TCPOpenV4Type = 0
    case TCPOpenV6Type = 1
    case TCPCloseType = 2
    case TCPDataType = 3
    case UDPDataV4Type = 4
    case UDPDataV6Type = 5
    case IPOpenV4Type = 6
    case IPOpenV6Type = 7
    case IPCloseV4Type = 8
    case IPCloseV6Type = 9
    case IPAssignV4Type = 10
    case IPAssignV6Type = 11
    case IPDataV4Type = 12
    case IPDataV6Type = 13
}

public typealias StreamIdentifier = UInt64

public struct EndpointV4: MaybeDatable
{
    public let host: IPv4Address
    public let port: NWEndpoint.Port

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
        
        guard let p = NWEndpoint.Port(rawValue: portData.uint16) else
        {
            return nil
        }
        
        port = p
        
        guard let address = IPv4Address.init(tail) else
        {
            return nil
        }
        
        host = address
    }
    
    public var data: Data
    {
        var result = Data()
        result.append(port.data)
        result.append(host.data)
        return result
    }
}

public struct EndpointV6: MaybeDatable
{
    public let host: IPv6Address
    public let port: NWEndpoint.Port
    
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
        
        guard let p = NWEndpoint.Port(rawValue: portData.uint16) else
        {
            return nil
        }
        
        port = p
        
        guard let address = IPv6Address.init(tail) else
        {
            return nil
        }
        
        host = address
    }
    
    public var data: Data
    {
        var result = Data()
        result.append(port.data)
        result.append(host.data)
        return result
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
    case IPOpenV4()
    case IPOpenV6()
    case IPCloseV4()
    case IPCloseV6()
    case IPAssignV4(IPv4Address)
    case IPAssignV6(IPv6Address)
    case IPDataV4(Data)
    case IPDataV6(Data)
}

extension Message: MaybeDatable
{
    public init?(data: Data) {
        guard let (messageTypeByte, tail) = data.splitOn(position: 1) else
        {
            return nil
        }
        
        guard let messageType = MessageType.init(rawValue: messageTypeByte[0]) else
        {
            return nil
        }
        
        switch messageType
        {
            case .TCPOpenV4Type:
                let endpointSize = AddressSize.v4.rawValue + 2
                guard let (dstData, streamidData) = tail.splitOn(position: UInt(endpointSize)) else
                {
                    return nil
                }

                guard let dst = EndpointV4(data: dstData) else
                {
                    return nil
                }
                
                let streamid = streamidData.uint64
                
                self = .TCPOpenV4(dst, streamid)
            case .TCPOpenV6Type:
                let endpointSize = AddressSize.v6.rawValue + 2
                guard let (dstData, streamidData) = tail.splitOn(position: UInt(endpointSize)) else
                {
                    return nil
                }
                
                guard let dst = EndpointV6(data: dstData) else
                {
                    return nil
                }
                
                let streamid = streamidData.uint64
                
                self = .TCPOpenV6(dst, streamid)
            case .TCPCloseType:
                let streamid = tail.uint64

                self = .TCPClose(streamid)
            case .TCPDataType:
                let endpointSize = AddressSize.v4.rawValue + 2
                guard let (streamidData, payload) = tail.splitOn(position: UInt(endpointSize)) else
                {
                    return nil
                }

                let streamid = streamidData.uint64
                
                self = .TCPData(streamid, payload)
            case .UDPDataV4Type:
                let endpointSize = AddressSize.v4.rawValue + 2
                guard let (dstData, payload) = tail.splitOn(position: UInt(endpointSize)) else
                {
                    return nil
                }
                
                guard let dst = EndpointV4(data: dstData) else
                {
                    return nil
                }
                
                self = .UDPDataV4(dst, payload)
            case .UDPDataV6Type:
                let endpointSize = AddressSize.v6.rawValue + 2
                guard let (dstData, payload) = tail.splitOn(position: UInt(endpointSize)) else
                {
                    return nil
                }
                
                guard let dst = EndpointV6(data: dstData) else
                {
                    return nil
                }
                
                self = .UDPDataV6(dst, payload)
            case .IPDataV4Type:
                self = .IPDataV4(tail)
            case .IPDataV6Type:
                self = .IPDataV6(tail)
        case .IPOpenV4Type:
            self = .IPOpenV4()
        case .IPOpenV6Type:
            self = .IPOpenV6()
        case .IPCloseV4Type:
            self = .IPCloseV4()
        case .IPCloseV6Type:
            self = .IPCloseV6()
        case .IPAssignV4Type:
            guard let ip = IPv4Address(data: tail) else
            {
                return nil
            }
           
            self = .IPAssignV4(ip)
        case .IPAssignV6Type:
            guard let ip = IPv6Address(data: tail) else
            {
                return nil
            }
            
            self = .IPAssignV6(ip)
        }
    }
    
    public var data: Data {
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
            case .IPOpenV4:
                result.append(MessageType.IPOpenV4Type.rawValue)
            case .IPOpenV6:
                result.append(MessageType.IPOpenV6Type.rawValue)
            case .IPCloseV4:
                result.append(MessageType.IPCloseV4Type.rawValue)
            case .IPCloseV6:
                result.append(MessageType.IPCloseV6Type.rawValue)
            case .IPAssignV4(let ip):
                result.append(MessageType.IPAssignV4Type.rawValue)
                result.append(ip.data)
            case .IPAssignV6(let ip):
                result.append(MessageType.IPAssignV4Type.rawValue)
                result.append(ip.data)
        }
        
        return result
    }
}
