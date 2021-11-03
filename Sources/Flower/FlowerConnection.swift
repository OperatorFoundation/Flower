//
//  File.swift
//  
//
//  Created by Dr. Brandon Wiley on 11/2/21.
//

import Foundation
import Transport
import SwiftQueue

public class FlowerConnection
{
    let connection: Transport.Connection

    let readMessageQueue: Queue<Message> = Queue<Message>()
    let writeMessageQueue: Queue<Message> = Queue<Message>()

    let readQueue: DispatchQueue = DispatchQueue(label: "FlowerConnection.readMessages")
    let writeQueue: DispatchQueue = DispatchQueue(label: "FlowerConnection.writeMessages")

    public init(connection: Transport.Connection)
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

    func readMessages()
    {
        while true
        {
            guard let message = self.connection.readMessage() else {return}

            self.readMessageQueue.enqueue(message)
        }
    }

    func writeMessages()
    {
        while true
        {
            guard let message = self.writeMessageQueue.dequeue() else {return}

            guard self.connection.writeMessage(message: message) else {return}
        }
    }
}
