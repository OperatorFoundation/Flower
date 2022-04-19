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
            print("Flower starting readMessages queue")
            self.readMessages()
        }

        self.writeQueue.async
        {
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
        while true
        {
            guard let data = self.connection.readWithLengthPrefix(prefixSizeInBits: 16) else
            {
                if let logger = log
                {
                    logger.info("FlowerConnection.readMessages: flower connection was closed by other side")
                    logger.info("FlowerConnection.readMessages: closing flower connection")
                }

                return
            }

            if let logger = log
            {
                logger.debug("read data \(data.hex)")
            }

            guard let message = Message(data: data) else
            {
                if let logger = log
                {
                    logger.error("flower failed to parse data as message")
                }

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

            guard self.connection.writeWithLengthPrefix(data: data, prefixSizeInBits: 16) else
            {
                if let logger = log
                {
                    logger.info("FlowerConnection.writeMessages: flower connection was closed by other side")
                    logger.info("FlowerConnection.writeMessages: closing flower connection")
                }

                return
            }
        }
    }
}
