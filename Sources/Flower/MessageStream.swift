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
    public func readMessage(log: Logger? = nil, handler: @escaping (Message) -> Void)
    {
        DatableConfig.endianess = .big
        self.debug(log: log, message: "calling Flower receive function")
        self.receive(minimumIncompleteLength: 2, maximumLength: 2)
        {
            (maybeData, maybeContext, isComplete, maybeError) in
            
            self.debug(log: log, message: "Flower receive called")
            if let error = maybeError
            {
                self.debug(log: log, message: "Error when calling receive (message length) from readMessages: \(error)")
                return
            }
            
            guard let data = maybeData else
            {
                self.debug(log: log, message: "done receiving Flower message length data in readMessage")
                return
            }
            
            let length = Int(data.uint16!)
            self.debug(log: log, message: "Read Length:\(length)")
            self.debug(log: log, message: "Read LengthData: \(data.array)")
            self.receive(minimumIncompleteLength: length, maximumLength: length, completion:
            {
                (maybeData, maybeContext, isComplete, maybeError) in

                if let error = maybeError
                {
                    self.debug(log: log, message: "Error when calling receive (message body) from readMessages: \(error)")
                    return
                }
                
                guard let data = maybeData else
                {
                    self.debug(log: log, message: "done receiving Flower message body data in readMessage")
                    return
                }
                
                guard let message = Message(data: data) else
                {
                    self.debug(log: log, message: "done receiving Flower messages in readMessage")
                    return
                }
                
                handler(message)
                
            })
        }
    }
    
    public func readMessages(log: Logger, handler: @escaping (Message) -> Void)
    {
        self.readMessage(log: log)
        {
            (message) in
            
            handler(message)
            self.readMessages(log: log, handler: handler)
        }
    }

    public func writeMessage(log: Logger? = nil, message: Message, completion: @escaping (NWError?) -> Void)
    {
        DatableConfig.endianess = .big
        let data = message.data
        let length = UInt16(data.count)
        self.debug(log: log, message: "writemessage length:\(length)")
        let lengthData = length.data
        self.debug(log: log, message: "writemessage lengthData:\(lengthData.array)")
        
        self.debug(log: log, message: "writeMessage called send")
        self.send(content: lengthData, contentContext: NWConnection.ContentContext.defaultMessage, isComplete: false, completion: NWConnection.SendCompletion.contentProcessed(
            {
                (maybeLengthError) in
                
                self.debug(log: log, message: "writeMessage send callback called")
                
                if let lengthError = maybeLengthError
                {
                    self.debug(log: log, message: "Error sending length bytes. Error: \(lengthError)")
                    completion(lengthError)
                    return
                }
                
                self.send(content: data, contentContext: NWConnection.ContentContext.defaultMessage, isComplete: false, completion: NWConnection.SendCompletion.contentProcessed(
                {
                    (maybeError) in
                    
                    completion(maybeError)
            }))
        }))
    }
    
    func debug(log: Logger?, message: Logger.Message) {
        if let logger = log {
            logger.debug(message)
        }
    }
}
