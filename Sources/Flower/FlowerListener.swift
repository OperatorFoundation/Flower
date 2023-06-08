//
//  FlowerListener.swift
//  
//
//  Created by Dr. Brandon Wiley on 12/8/21.
//

#if os(macOS) || os(iOS)
import os.log
#else
import Logging
#endif

import Foundation
import Transmission


public class FlowerListener
{
    let logger: Logger
    let listener: Transmission.Listener

    public init(listener: Transmission.Listener, logger: Logger)
    {
        self.logger = logger
        self.listener = listener
    }

    public func accept() throws -> FlowerConnection
    {
        let connection = try self.listener.accept()
        
        return FlowerConnection(connection: connection, log: self.logger)
    }
}
