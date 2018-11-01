//
//  DataUtils.swift
//  Datable
//
//  Created by Dr. Brandon Wiley on 11/1/18.
//

import Foundation

extension Data
{
    public func splitOn(position: UInt) -> (Data, Data)?
    {
        let head = self[0..<position]
        let tail = self[position...]
        return (head, tail)
    }
}
