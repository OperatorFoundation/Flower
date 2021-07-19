//
//  MessageStream.swift
//  Datable
//
//  Created by Dr. Brandon Wiley on 11/1/18.
//

import Foundation
import Transport
import Datable
#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
import Network
#elseif os(Linux)
import NetworkLinux
#endif

extension Connection
{
    public func readMessage(handler: @escaping (Message) -> Void)
    {
        print("calling Flower receive function")
        self.receive(minimumIncompleteLength: 2, maximumLength: 2)
        {
            (maybeData, maybeContext, isComplete, maybeError) in
            
            print("Flower receive called")
            if let error = maybeError
            {
                print("Error when calling receive (message length) from readMessages: \(error)")
                return
            }
            
            guard let data = maybeData else
            {
                return
            }
            
            let length = Int(data.uint16!)
            print("Read Length:\(length)")
            print("Read LengthData: \(data.array)")
            self.receive(minimumIncompleteLength: length, maximumLength: length, completion:
            {
                (maybeData, maybeContext, isComplete, maybeError) in

                if let error = maybeError
                {
                    print("Error when calling receive (message body) from readMessages: \(error)")
                    return
                }
                
                guard let data = maybeData else
                {
                    return
                }
                
                guard let message = Message(data: data) else
                {
                    return
                }
                
                handler(message)
                
            })
        }
    }
    
    public func readMessages(handler: @escaping (Message) -> Void)
    {
        self.readMessage
        {
            (message) in
            
            handler(message)
            self.readMessages(handler: handler)
        }
    }

    public func writeMessage(message: Message, completion: @escaping (NWError?) -> Void)
    {
        let data = message.data
        let length = UInt16(data.count)
        print("writemessage length:\(length)")
        let lengthData = length.data
        print("writemessage lengthData:\(lengthData.array)")
        
        print("writeMessage called send")
        self.send(content: lengthData, contentContext: NWConnection.ContentContext.defaultMessage, isComplete: false, completion: NWConnection.SendCompletion.contentProcessed(
            {
                (maybeLengthError) in
                
                print("writeMessage send callback called")
                
                if let lengthError = maybeLengthError
                {
                    print("Error sending length bytes. Error: \(lengthError)")
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
}
