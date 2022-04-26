//
//  File.swift
//  
//
//  Created by Dr. Brandon Wiley on 11/2/21.
//

import Foundation
import Transport
import SwiftQueue
import Transmission
import Chord
import Logging
import SwiftHexTools

public class FlowerConnection
{
    public let connection: Transmission.Connection

    let readMessageQueue: BlockingQueue<Message> = BlockingQueue<Message>()
    let writeMessageQueue: BlockingQueue<Message> = BlockingQueue<Message>()

    let readQueue: DispatchQueue = DispatchQueue(label: "FlowerConnection.readMessages")
    let writeQueue: DispatchQueue = DispatchQueue(label: "FlowerConnection.writeMessages")
    
    let log: Logger?

    public init(connection: Transmission.Connection, log: Logger? = nil)
    {
        print("🌷 FlowerConnection init called. 🌷")
        self.connection = connection
        self.log = log
        
        self.readQueue.async
        {
            print("🌷 FlowerConnection starting readMessages queue")
            self.readMessages()
        }

        self.writeQueue.async
        {
            print("🌷 FlowerConnection starting writeMessages queue")
            self.writeMessages()
        }
    }

    public func readMessage() -> Message?
    {
        return self.readMessageQueue.dequeue()
    }

    public func writeMessage(message: Message)
    {
        return self.writeMessageQueue.enqueue(element: message)
    }

    func readMessages()
    {
        print("FlowerConnection.readMessages() called")
        while true
        {
            guard let data = self.connection.readWithLengthPrefix(prefixSizeInBits: 16) else
            {
                log?.info("FlowerConnection.readMessages: flower connection was closed by other side")
                log?.info("FlowerConnection.readMessages: closing flower connection")
                print("FlowerConnection.readMessages: flower connection was closed by other side")

                return
            }

            log?.debug("FlowerConnection.readMessages: read data \(data.hex)")
            print("FlowerConnection.readMessages: read data \(data.hex)")

            guard let message = Message(data: data) else
            {
                log?.error("flower failed to parse data as message")
                print("flower failed to parse data as message")
                
                return
            }

            self.readMessageQueue.enqueue(element: message)
        }
    }

    func writeMessages()
    {
        while true
        {
            let message = self.writeMessageQueue.dequeue()
            let data = message.data

            print("FlowerConnection.writeMessages: writing a message: \(message.description)")
            
            guard self.connection.writeWithLengthPrefix(data: data, prefixSizeInBits: 16) else
            {
                log?.info("FlowerConnection.writeMessages: flower connection was closed by other side")
                log?.info("FlowerConnection.writeMessages: closing flower connection")
                print("FlowerConnection.writeMessages: flower connection was closed by other side")

                return
            }
        }
    }
}
