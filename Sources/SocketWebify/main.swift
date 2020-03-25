import Dispatch
import Foundation
import Logging
import NIO
import WebTunnel

let argv = CommandLine.arguments

if argv.count > 1, let url = URL(fromNoVNC: argv[1]) {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    let bootstrap = ServerBootstrap(group: group)
        .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
        .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
        .childChannelInitializer { channel in
            channel.pipeline.add(handler: WebTunnel(url: url))
        }

    let ip6 = bootstrap.bind(to: try! SocketAddress(ipAddress: "::1", port: 59009))
    ip6.whenSuccess { channel in
        // Need to create this here for thread-safety purposes
        let logger = Logger(label: "ch.znerol.socketwebify.main")
        logger.info("Listening on \(String(describing: channel.localAddress))")
    }
    ip6.whenFailure { error in
        let logger = Logger(label: "ch.znerol.socketwebify.main")
        logger.error("Failed to bind [::1]:8080, \(error)")
    }

    let ip4 = bootstrap.bind(to: try! SocketAddress(ipAddress: "127.0.0.1", port: 59009))
    ip4.whenSuccess { channel in
        // Need to create this here for thread-safety purposes
        let logger = Logger(label: "ch.znerol.socketwebify.main")
        logger.info("Listening on \(String(describing: channel.localAddress))")
    }
    ip4.whenFailure { error in
        let logger = Logger(label: "ch.znerol.socketwebify.main")
        logger.error("Failed to bind 127.0.0.1:8080, \(error)")
    }

    dispatchMain()
} else {
    let logger = Logger(label: "ch.znerol.socketwebify.main")
    logger.error("Usage: \(argv[0]) URL")
}
