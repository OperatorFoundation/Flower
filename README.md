# The Operator Foundation

[Operator](https://operatorfoundation.org) makes useable tools to help people around the world with censorship, security, and privacy.

## Flower

Flower is a simple protocol for packet encapsulation. The Flower library can be integrated into Swift applications running on iOS or macOS. The intended use case is for macOS and iOS Network Extensions. A Network Extension is the Apple-approved way to create custom VPN protocols.

### Usage

#### Obtain a Connection

The Flower library does not provide connections. A Connection must be obtained elsewhere, either a NWConnection from the Network framework or any transport Connection type from the Shapeshifter library.

##### Example using an NWConnection

    import Network
    
    let conn = NWConnection(host: NWEndpoint.Host("localhost"), port: NWEndpoint.Port(integerLiteral: 5555), using: .tcp)
    conn.start(queue: .global())

##### Example using Shapeshifter transport Connection

    import Shapeshifter-Swift-Transports
    
    // Only use Rot13 transport for examples, never for real deployments.
    let factory = Rot13ConnectionFactory((host: NWEndpoint.Host("localhost"), port: NWEndpoint.Port(integerLiteral: 5555))
    let conn = factory.connect(using: .tcp)

#### Create Message objects

Create Message objects for encapsulated packets.

##### Example using IPv4 packet

    import Flower

    let data = Data(repeating: 0x00, count: 80)
    let message = Message.IPDataV4(data)

##### Example using IPv6 packet

    import Flower

    let data = Data(repeating: 0x00, count: 80)
    let message = Message.IPDataV6(data)

#### Send Message objects over Connection

Flower extends the Connection protocol to include the ```sendMessage``` function. You can call ```sendMessage``` on any
Connection.

    conn.sendMessage(message)
    {
      maybeError in
      
      // Handle errors while attempting to send message
    }
    
#### Read Message objects from Connection

Flower extends the Connection protocol to include the ```readMessages``` function. You can call ```readMessages``` on any
Connection.

    conn.readMessages
    {
      message in
      
      switch message
      {
        case .IPDataV4(let data):
          print("Received an IPv4 packet")
        case .IPDataV6(let data):
          print("Receieved an IPv6 packet")
      }
    }
    
The ```readMessages``` function only needs to be called once. It will call the provided callback multiple times, once
for each packet received.
