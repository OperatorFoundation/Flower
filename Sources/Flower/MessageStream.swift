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
import SwiftHexTools

extension Transmission.Connection
{
    public func readMessage(log: Logger? = nil) -> Message?
    {
        if let logger = log {
            logger.debug("1: flower read message reading size")
        }
        
        guard let data = self.read(size: 2) else
        {
            if let logger = log {
                logger.error("flower failed to read message length")
            }
            return nil
        }

        if let logger = log {
            logger.debug("flower data: \(data.hex)")
        }
        
        guard let uint16Length = UInt16(maybeNetworkData: data) else {
            if let logger = log {
                logger.error("flower failed to conver message length to UInt16")
            }
            return nil
        }

        if let logger = log {
            logger.debug("Flower Transmission Connection readMessage uint16Length: \(uint16Length)")
        }
        
        let length = Int(uint16Length)

        // FIXME: Debugging only
        if length == 0 {
            if let extraData = self.read(size: 2) {
                if let logger = log {
                    logger.debug("extra data: \(extraData.hex)")
                }
            }
        }
        
        if length > 1600 {
            if let logger = log {
                logger.error("flower read size too big")
            }
            return nil
        }

        if let logger = log {
            logger.debug("2: flower read message reading message data (length: \(length))")
        }
        
        guard let data = self.read(size: length) else
        {
            if let logger = log {
                logger.error("flower failed to read message")
            }
            return nil
        }

        guard let message = Message(data: data) else
        {
            if let logger = log {
                logger.error("flower failed to parse data as message")
            }
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
