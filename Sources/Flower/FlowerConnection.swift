//
//  File.swift
//  
//
//  Created by Dr. Brandon Wiley on 11/2/21.
//

import Foundation

#if os(macOS) || os(iOS)
import os.log
#else
import Logging
#endif

import Datable
import Transport
import SwiftQueue
import Transmission
import Chord
import SwiftHexTools

public class FlowerConnection
{
    public var writeLog: [Data]?
    public var readLog: [Data]?

    public let connection: Transmission.Connection

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
    }

    public func readMessage() -> Message?
    {
        guard open else
        {
            return nil
        }

        guard let data = self.connection.readWithLengthPrefix(prefixSizeInBits: 16) else
        {
            logAThing(logger: log, logMessage: "FlowerConnection.readMessages: flower connection failed to get data from readWithLengthPrefix")
            logAThing(logger: log, logMessage: "FlowerConnection.readMessages: closing flower connection")

            return nil
        }

        readLog?.append(data)

        guard data.count > 0 else
        {
            logAThing(logger: log, logMessage: "readWithLengthPrefix(prefixSizeInBits: 16) returned a data of 0 bytes using a \(type(of: connection)).")
            logAThing(logger: log, logMessage: "FlowerConnection.readMessages: closing flower connection")

            return nil
        }

        guard let message = Message(data: data) else
        {
            log?.error("FlowerConnection.readMessages: failed to parse data as message")

            if let rLog = readLog
            {
                print("FlowerConnection.readMessages: Read log contains \(rLog.count) elements: ")

                for connectionData in rLog
                {
                    print("FlowerConnection.readMessages: Actual Read Data length \(connectionData.count): \(connectionData.hex)")
                }
            }
            else
            {
                print("FlowerConnection.readMessages: Read log was null.")
            }

            if let wLog = writeLog
            {
                print("FlowerConnection.readMessages: Write log contains \(wLog.count) elements: ")

                for connectionData in wLog
                {
                    print("FlowerConnection.readMessages: Actual Write Data length \(connectionData.count): \(connectionData.hex)")
                }
            }
            else
            {
                print("FlowerConnection.readMessages: Write log is null.")
            }

            return nil
        }

        return message
    }

    public func writeMessage(message: Message)
    {
        guard open else
        {
            return
        }

        let data = message.data

        writeLog?.append(data)

        guard self.connection.writeWithLengthPrefix(data: data, prefixSizeInBits: 16) else
        {
            logAThing(logger: log, logMessage: "FlowerConnection.writeMessages: writeWithLengthPrefix failed using a \(type(of: connection))")
            logAThing(logger: log, logMessage: "FlowerConnection.writeMessages: closing flower connection")

            self.open = false
            self.connection.close()

            return
        }
    }

    public func close()
    {
        self.open = false
        self.connection.close()
    }
}

func logAThing(logger: Logger?, logMessage: String)
{
    if let aLog = logger
    {
        #if os(macOS) || os(iOS)
        aLog.log("🌷 \(logMessage, privacy: .public)")
        #else
        aLog.debug("🌷 \(logMessage)")
        #endif
    }
    else
    {
        print("🌷 \(logMessage)")
    }
}
