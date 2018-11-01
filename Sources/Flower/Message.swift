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
}

public typealias StreamIdentifier = UInt64

public struct EndpointV4: MaybeDatable
{
    public let host: IPv4Address
    public let port: NWEndpoint.Port
    
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
    case TCPOpenV4(EndpointV4, EndpointV4, StreamIdentifier)
    case TCPOpenV6(EndpointV6, EndpointV6, StreamIdentifier)
    case TCPClose(StreamIdentifier)
    case TCPData(StreamIdentifier, Data)
    case UDPDataV4(EndpointV4, EndpointV4, Data)
    case UDPDataV6(EndpointV6, EndpointV6, Data)
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
                guard let (srcData, rest) = tail.splitOn(position: UInt(endpointSize)) else
                {
                    return nil
                }
                
                guard let (dstData, streamidData) = rest.splitOn(position: UInt(endpointSize)) else
                {
                    return nil
                }

                guard let src = EndpointV4(data: srcData), let dst = EndpointV4(data: dstData) else
                {
                    return nil
                }
                
                let streamid = streamidData.uint64
                
                self = .TCPOpenV4(src, dst, streamid)
            case .TCPOpenV6Type:
                let endpointSize = AddressSize.v6.rawValue + 2
                guard let (srcData, rest) = tail.splitOn(position: UInt(endpointSize)) else
                {
                    return nil
                }
                
                guard let (dstData, streamidData) = rest.splitOn(position: UInt(endpointSize)) else
                {
                    return nil
                }
                
                guard let src = EndpointV6(data: srcData), let dst = EndpointV6(data: dstData) else
                {
                    return nil
                }
                
                let streamid = streamidData.uint64
                
                self = .TCPOpenV6(src, dst, streamid)
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
                guard let (srcData, rest) = tail.splitOn(position: UInt(endpointSize)) else
                {
                    return nil
                }
                
                guard let (dstData, payload) = rest.splitOn(position: UInt(endpointSize)) else
                {
                    return nil
                }
                
                guard let src = EndpointV4(data: srcData), let dst = EndpointV4(data: dstData) else
                {
                    return nil
                }
                
                self = .UDPDataV4(src, dst, payload)
            case .UDPDataV6Type:
                let endpointSize = AddressSize.v6.rawValue + 2
                guard let (srcData, rest) = tail.splitOn(position: UInt(endpointSize)) else
                {
                    return nil
                }
                
                guard let (dstData, payload) = rest.splitOn(position: UInt(endpointSize)) else
                {
                    return nil
                }
                
                guard let src = EndpointV6(data: srcData), let dst = EndpointV6(data: dstData) else
                {
                    return nil
                }
                
                self = .UDPDataV6(src, dst, payload)
        }
    }
    
    public var data: Data {
        var result = Data()
        switch self
        {
            case .TCPOpenV4(let src, let dst, let streamid):
                result.append(MessageType.TCPOpenV4Type.rawValue)
                result.append(src.data)
                result.append(dst.data)
                result.append(streamid.data)
            case .TCPOpenV6(let src, let dst, let streamid):
                result.append(MessageType.TCPOpenV6Type.rawValue)
                result.append(src.data)
                result.append(dst.data)
                result.append(streamid.data)
            case .TCPClose(let streamid):
                result.append(MessageType.TCPCloseType.rawValue)
                result.append(streamid.data)
            case .TCPData(let streamid, let payload):
                result.append(MessageType.TCPDataType.rawValue)
                result.append(streamid.data)
                result.append(payload)
            case .UDPDataV4(let src, let dst, let payload):
                result.append(MessageType.UDPDataV4Type.rawValue)
                result.append(src.data)
                result.append(dst.data)
                result.append(payload)
            case .UDPDataV6(let src, let dst, let payload):
                result.append(MessageType.UDPDataV6Type.rawValue)
                result.append(src.data)
                result.append(dst.data)
                result.append(payload)
        }
        
        return result
    }
}
