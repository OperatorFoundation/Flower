//
//  File.swift
//  
//
//  Created by Dr. Brandon Wiley on 11/2/21.
//

import Foundation

import Datable
import Transport
import SwiftQueue
import Transmission
import Chord
import Logging
import SwiftHexTools

public class FlowerConnection
{
    public var writeLog: [Data]?
    public var readLog: [Data]?

    public let connection: Transmission.Connection

    let readMessageQueue: BlockingQueue<Message> = BlockingQueue<Message>()
    let writeMessageQueue: BlockingQueue<Message> = BlockingQueue<Message>()

    let readQueue: DispatchQueue = DispatchQueue(label: "FlowerConnection.readMessages")
    let writeQueue: DispatchQueue = DispatchQueue(label: "FlowerConnection.writeMessages")
    
    let log: Logger?
    var open = true

    public init(connection: Transmission.Connection, log: Logger? = nil, logReads: Bool = false, logWrites: Bool = false)
    {
        print("🌷 FlowerConnection init called. 🌷")
        self.connection = connection
        self.log = log

        if logReads
        {
            readLog = []
        }

        if logWrites
        {
            writeLog = []
        }
        
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
        if open
        {
            return self.readMessageQueue.dequeue()
        }
        else
        {
            return nil
        }
    }

    public func writeMessage(message: Message)
    {
        print("FlowerConnection.writeMessage: enqueueing \(message)")
        return self.writeMessageQueue.enqueue(element: message)
    }

    public func close()
    {
        self.open = false
        self.connection.close()
    }

    func readMessages()
    {
        print("FlowerConnection.readMessages() called")
        while self.open
        {
            guard let data = self.connection.readWithLengthPrefix(prefixSizeInBits: 16) else
            {
                log?.info("FlowerConnection.readMessages: flower connection was closed by other side")
                log?.info("FlowerConnection.readMessages: closing flower connection")
                print("FlowerConnection.readMessages: flower connection was closed by other side")

                self.open = false
                self.connection.close()
                return
            }

            readLog?.append(data)

//            log?.debug("FlowerConnection.readMessages: read data \(data.hex)")
//            print("FlowerConnection.readMessages: read data \(data.hex)")

            guard let message = Message(data: data) else
            {
                log?.error("flower failed to parse data as message")
                print("flower failed to parse data as message")
                
                if let rLog = readLog
                {
                    print("Read log contains \(rLog.count) elements: ")
                    
                    for connectionData in rLog
                    {
                        print(connectionData.hex)
                    }
                }
                else
                {
                    print("Read log was null.")
                }
                
                
                if let wLog = writeLog
                {
                    print("Write log contains \(wLog.count) elements: ")
                    
                    for connectionData in wLog
                    {
                        print(connectionData.hex)
                    }
                }
                else
                {
                    print("Write log is null.")
                }
                
                
                self.open = false
                self.connection.close()
                return
            }

            self.readMessageQueue.enqueue(element: message)
        }
    }

    func writeMessages()
    {
        while self.open
        {
            let message = self.writeMessageQueue.dequeue()
            let data = message.data

            writeLog?.append(data)

            print("FlowerConnection.writeMessages: writing a message: \(message.description)")
            
            guard self.connection.writeWithLengthPrefix(data: data, prefixSizeInBits: 16) else
            {
                log?.info("FlowerConnection.writeMessages: flower connection was closed by other side")
                log?.info("FlowerConnection.writeMessages: closing flower connection")
                print("FlowerConnection.writeMessages: flower connection was closed by other side")

                self.open = false
                self.connection.close()
                
                return
            }
        }
    }
}
