//
//  MessageStream.swift
//  Datable
//
//  Created by Dr. Brandon Wiley on 11/1/18.
//

import Foundation
import Datable
import Logging
import Transmission

extension Transmission.Connection
{
    public func readMessage(log: Logger? = nil) -> Message?
    {
        guard let data = self.read(size: 2) else
        {
            return nil
        }

        guard let uint16Length = UInt16(maybeNetworkData: data) else {
            return nil
        }

        let length = Int(uint16Length)

        if length > 1600 {
            return nil
        }

        guard let data = self.read(size: length) else
        {
            return nil
        }

        guard let message = Message(data: data) else
        {
            return nil
        }

        return message
    }

    public func writeMessage(log: Logger? = nil, message: Message) -> Bool
    {
        let data = message.data
        let length = UInt16(data.count)
        guard let lengthData = length.maybeNetworkData else {return false}

        guard self.write(data: lengthData) else {return false}
        guard self.write(data: data) else {return false}

        return true
    }
    
    func debug(log: Logger?, message: Logger.Message) {
        if let logger = log {
            logger.debug(message)
        }
    }
}
