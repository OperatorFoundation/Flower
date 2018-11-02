//
//  MessageStream.swift
//  Datable
//
//  Created by Dr. Brandon Wiley on 11/1/18.
//

import Foundation
import Transport
import Network

extension Connection
{
    public func readMessages(handler: @escaping (Message) -> Void)
    {
        self.receive(minimumIncompleteLength: 2, maximumLength: 2)
        {
            (maybeData, maybeContext, isComplete, maybeError) in
            
            if let error = maybeError
            {
                print(error)
                return
            }
            
            guard let data = maybeData else
            {
                return
            }
            
            let length = Int(data.uint16)
            
            self.receive(minimumIncompleteLength: length, maximumLength: length, completion:
            {
                (maybeData, maybeContext, isComplete, maybeError) in

                if let error = maybeError
                {
                    print(error)
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
                self.readMessages(handler: handler)
            })
        }
    }

    public func writeMessage(message: Message, completion: @escaping (NWError?) -> Void)
    {
        let data = message.data

        self.send(content: data, contentContext: NWConnection.ContentContext.defaultMessage, isComplete: false, completion: NWConnection.SendCompletion.contentProcessed(
            {
                (maybeError) in
                
                completion(maybeError)
        }))
    }
}
