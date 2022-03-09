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
        guard self.count > position else
        {
            return nil
        }

        let headSlice = self[0..<position]
        let head = Data(headSlice)
        
        let tailSlice = self[position...]
        let tail = Data(tailSlice)
        
        return (head, tail)
    }
}
