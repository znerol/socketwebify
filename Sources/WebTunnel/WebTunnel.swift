import Dispatch
import Foundation
import Logging
import NIO
import Starscream

/**
 Establishes connection to WebSocket and tunnels all traffic through it.
 */
public final class WebTunnel: ChannelInboundHandler, WebSocketDelegate {
    public typealias InboundIn = ByteBuffer

    private let logger = Logger(label: "ch.znerol.socketwebify.WebTunnel")

    private let maxFrameSize: Int

    private let url: URL
    private let ws: WebSocket
    private var channel: Channel?

    public init(
        url: URL,
        maxFrameSize: Int = 1 << 16
    ) {
        self.url = url
        self.maxFrameSize = maxFrameSize
        ws = WebSocket(url: url)
        ws.delegate = self
    }

    public func channelRead(ctx _: ChannelHandlerContext, data: NIOAny) {
        let bytes = unwrapInboundIn(data)
        logger.debug("Local read: \(bytes.readableBytes)")
        var len = bytes.readableBytes
        var off = 0
        while len > 0 {
            logger.debug("WS send: \(off)...\(off + len)")
            ws.write(data: Data(bytes: bytes.getBytes(at: off, length: len)!))
            len = len - maxFrameSize
            off = off + maxFrameSize
        }
    }

    public func errorCaught(ctx _: ChannelHandlerContext, error: Error) {
        logger.error("Local caught: \(error)")
    }

    public func handlerAdded(ctx: ChannelHandlerContext) {
        logger.info("Local connected")

        channel = ctx.channel
        ws.connect()

        logger.info("WS attempting to connect to \(url)")
    }

    public func handlerRemoved(ctx _: ChannelHandlerContext) {
        logger.info("WS attempting to disconnect from \(url)")

        ws.disconnect()
        channel = nil

        logger.info("Local removed")
    }

    public func websocketDidConnect(socket _: WebSocketClient) {
        logger.info("WS is connected")
    }

    public func websocketDidDisconnect(socket _: WebSocketClient, error: Error?) {
        logger.info("WS is disconnected: \(String(describing: error))")
        channel?.close()
    }

    public func websocketDidReceiveMessage(socket _: WebSocketClient, text: String) {
        logger.info("WS unexpected text: \(text)")
        channel?.close()
    }

    public func websocketDidReceiveData(socket _: WebSocketClient, data: Data) {
        if let chan = channel {
            logger.debug("WS read \(data.count)")
            var buffer = chan.allocator.buffer(capacity: data.count)
            buffer.write(bytes: data)
            logger.debug("Local write \(data.count)")
            chan.writeAndFlush(buffer).whenFailure { error in
                self.logger.error("Local write error, \(error)")
                chan.close()
            }
        }
    }
}
