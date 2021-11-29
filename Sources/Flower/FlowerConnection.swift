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

public class FlowerConnection
{
    let connection: Transmission.Connection

    let readMessageQueue: BlockingQueue<Message> = BlockingQueue<Message>()
    let writeMessageQueue: BlockingQueue<Message> = BlockingQueue<Message>()

    let readQueue: DispatchQueue = DispatchQueue(label: "FlowerConnection.readMessages")
    let writeQueue: DispatchQueue = DispatchQueue(label: "FlowerConnection.writeMessages")

    public init(connection: Transmission.Connection)
    {
        self.connection = connection

        self.readQueue.async
        {
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
            guard let message = self.connection.readMessage() else {return}

            self.readMessageQueue.enqueue(element: message)
        }
    }

    func writeMessages()
    {
        while true
        {
            let message = self.writeMessageQueue.dequeue()

            guard self.connection.writeMessage(message: message) else {return}
        }
    }
}
