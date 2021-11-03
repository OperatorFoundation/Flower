//
//  MessageStream.swift
//  Datable
//
//  Created by Dr. Brandon Wiley on 11/1/18.
//

import Foundation
import Transport
import Datable
import Logging
#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
import Network
#elseif os(Linux)
import NetworkLinux
#endif

extension Connection
{
    public func readMessage(log: Logger? = nil) -> Message?
    {
        self.debug(log: log, message: "calling Flower receive function: \(type(of: self))")

        var maybeMessage: Message? = nil

        let lock = DispatchGroup()

        lock.enter()

        self.receive(minimumIncompleteLength: 2, maximumLength: 2)
        {
            (maybeData, maybeContext, isComplete, maybeError) in
            
            self.debug(log: log, message: "Flower receive called")
            if let error = maybeError
            {
                self.debug(log: log, message: "Error when calling receive (message length) from readMessages: \(error)")
                lock.leave()
                return
            }
            
            guard let data = maybeData else
            {
                self.debug(log: log, message: "done receiving Flower message length data in readMessage")
                lock.leave()
                return
            }
            guard let uint16Length = UInt16(maybeNetworkData: data) else {
                self.debug(log: log, message: "Unable to parse data as uint16 length")
                return
            }
            let length = Int(uint16Length)
            
            self.debug(log: log, message: "Read Length:\(length)")
            self.debug(log: log, message: "Read LengthData: \(data.array)")
            if length > 1600 {
                self.debug(log: log, message: "Invalid message size: \(length)")
            }
            self.receive(minimumIncompleteLength: length, maximumLength: length, completion:
            {
                (maybeData, maybeContext, isComplete, maybeError) in

                if let error = maybeError
                {
                    self.debug(log: log, message: "Error when calling receive (message body) from readMessages: \(error)")
                    lock.leave()
                    return
                }
                
                guard let data = maybeData else
                {
                    self.debug(log: log, message: "done receiving Flower message body data in readMessage")
                    lock.leave()
                    return
                }
                
                guard let message = Message(data: data) else
                {
                    self.debug(log: log, message: "done receiving Flower messages in readMessage")
                    lock.leave()
                    return
                }
                
                maybeMessage = message

                lock.leave()
                return
            })
        }

        lock.wait()

        return maybeMessage
    }

    public func writeMessage(log: Logger? = nil, message: Message) -> Bool
    {
        let data = message.data
        let length = UInt16(data.count)
        self.debug(log: log, message: "writemessage length:\(length)")
        guard let lengthData = length.maybeNetworkData else {
            self.debug(log: log, message: "Error converting length to data.")
            return false
        }
        self.debug(log: log, message: "writemessage lengthData:\(lengthData.array)")

        var success = false

        let lock = DispatchGroup()

        lock.enter()

        self.debug(log: log, message: "writeMessage called send")
        self.send(content: lengthData, contentContext: NWConnection.ContentContext.defaultMessage, isComplete: false, completion: NWConnection.SendCompletion.contentProcessed(
            {
                (maybeLengthError) in
                
                self.debug(log: log, message: "writeMessage send callback called")
                
                if let lengthError = maybeLengthError
                {
                    self.debug(log: log, message: "Error sending length bytes. Error: \(lengthError)")
                    lock.leave()
                    return
                }
                
                self.send(content: data, contentContext: NWConnection.ContentContext.defaultMessage, isComplete: false, completion: NWConnection.SendCompletion.contentProcessed(
                {
                    (maybeError) in

                    success = true
                    lock.leave()
                    return
            }))
        }))

        lock.wait()

        return success
    }
    
    func debug(log: Logger?, message: Logger.Message) {
        if let logger = log {
            logger.debug(message)
        }
    }
}
