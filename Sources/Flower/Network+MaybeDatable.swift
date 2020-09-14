//
//  Network+Datable.swift
//  Datable
//
//  Created by Dr. Brandon Wiley on 11/1/18.
//

import Foundation
import Datable
#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
import Network
#elseif os(Linux)
import NetworkLinux
#endif

enum AddressSize: Int
{
    case v4 = 4
    case v6 = 16
}

extension NWEndpoint.Host: MaybeDatable
{
    public init?(data: Data) {
        guard let addressSize = AddressSize.init(rawValue: data.count) else
        {
            return nil
        }
        
        switch addressSize
        {
            case .v4:
                guard let address = IPv4Address(data) else
                {
                    return nil
                }
                
                self = .ipv4(address)
            case .v6:
                guard let address = IPv6Address(data) else
                {
                    return nil
                }

                self = .ipv6(address)
        }
    }
    
    public var data: Data {
        switch self
        {
            case .ipv4(let address):
                return address.data
            case .ipv6(let address):
                return address.data
            default:
                print("Error, named interfaces not supported")
                return Data()
        }
    }
}

extension IPv4Address: MaybeDatable
{
    public init?(data: Data) {
        self.init(data)
    }
    
    public var data: Data {
        return self.rawValue
    }
}

extension IPv6Address: MaybeDatable
{
    public init?(data: Data) {
        self.init(data)
    }

    public var data: Data {
        return self.rawValue
    }
}

extension NWEndpoint.Port: Datable
{
    public init(data: Data) {
        self.init(rawValue: data.uint16!)!
    }
    
    public var data: Data {
        return self.rawValue.data
    }
}
