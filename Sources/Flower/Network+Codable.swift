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
    public init(from decoder: Decoder) throws
    {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self.init(string)
    }

    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.singleValueContainer()

        switch self
        {
            case .ipv4(let ipv4):
                let data = ipv4.rawValue
                let string = "\(data[0]).\(data[1]).\(data[2]).\(data[3])"

                try container.encode(string)

            default:
                throw NetworkCodableError.nameAddressUnsupported
        }
    }
}

extension IPv4Address: Codable
{
    public init(from decoder: Decoder) throws
    {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self.init(string)! // FIXME - this is bad, but it's unclear how to work around this in a Codable extension
    }

    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.singleValueContainer()

        let data = self.rawValue
        let string = "\(data[0]).\(data[1]).\(data[2]).\(data[3])"

        try container.encode(string)
    }
}

extension IPv6Address: Codable
{
    public init(from decoder: Decoder) throws
    {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self.init(string)! // FIXME - this is bad, but it's unclear how to work around this in a Codable extension
    }

    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.singleValueContainer()

        let string = self.debugDescription // FIXME - This is bad, never do this. It is unclear how to get a proper string from an IPv6Address type.
        try container.encode(string)
    }
}

extension NWEndpoint.Port: Codable
{
    public init(from decoder: Decoder) throws
    {
        let container = try decoder.singleValueContainer()
        let uint16 = try container.decode(UInt16.self)
        self.init(rawValue: uint16)! // FIXME - this is bad, but it's unclear how to work around this in a Codable extension
    }

    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.singleValueContainer()

        try container.encode(self.rawValue)
    }
}

public enum NetworkCodableError: Error
{
    case ipv6Unsupported
    case nameAddressUnsupported
    case badIPAddress
}
