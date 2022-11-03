//
//  Network+Codable.swift
//  
//
//  Created by Dr. Brandon Wiley on 10/31/22.
//

import Foundation

import Net

extension NWEndpoint.Host: Codable
{
    enum CodingKeys: String, CodingKey
    {
        case hostData
    }
    
    public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedHostData = try container.decode(Data.self, forKey: .hostData)
        
        guard let host = NWEndpoint.Host(data: decodedHostData) else
        {
            throw NetworkCodableError.hostDataInvalid
        }
        
        self = host
    }
    
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self
        {
            case .ipv4(let ipv4):
                try container.encode(ipv4.rawValue, forKey: .hostData)
            case .ipv6(let ipv6):
                try container.encode(ipv6.rawValue, forKey: .hostData)
            case .name(_, _):
                throw NetworkCodableError.nameAddressUnsupported
            @unknown default:
                throw NetworkCodableError.badHost
        }
    }
}

extension IPv4Address: Codable
{
    enum CodingKeys: String, CodingKey
    {
        case rawData
    }
    
    public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedRawData = try container.decode(Data.self, forKey: .rawData)
        
        guard let ipv4Address = IPv4Address(decodedRawData) else
        {
            throw NetworkCodableError.ipv4DataInvalid
        }
        
        self = ipv4Address
    }

    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.rawValue, forKey: .rawData)
    }
}

extension IPv6Address: Codable
{
    enum CodingKeys: String, CodingKey
    {
        case rawData
    }

    public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedRawData = try container.decode(Data.self, forKey: .rawData)
        
        guard let ipv6Address = IPv6Address(decodedRawData) else
        {
            throw NetworkCodableError.ipv6DataInvalid
        }
        
        self = ipv6Address
    }
    
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.rawValue, forKey: .rawData)
    }
}

extension NWEndpoint.Port: Codable
{
    enum CodingKeys: String, CodingKey
    {
        case intLiteral
    }
    
    public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedUInt16 = try container.decode(UInt16.self, forKey: .intLiteral)
        self.init(integerLiteral: decodedUInt16)
    }

    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.rawValue, forKey: .intLiteral)
    }
}

public enum NetworkCodableError: Error
{
    case badHost
    case badIPAddress
    case badPort(UInt16)
    case nameAddressUnsupported
    case hostDataInvalid
    case ipv4DataInvalid
    case ipv6DataInvalid
    case ipv6Unsupported
}
