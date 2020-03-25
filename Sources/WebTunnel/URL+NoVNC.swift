import Foundation

public extension URL {
    init?(fromNoVNC string: String) {
        var result: URL?

        if let url = URL(string: string) {
            switch url.scheme {
            case "ws", "wss":
                result = url

            case "http", "https":
                var scheme: String = url.scheme == "http" ? "ws://" : "wss://"

                // Extract websocket URL from query/fragment parameters.
                if let novncparams = url.query ?? url.fragment {
                    if let query = URLComponents(string: "?\(novncparams)")?.queryItems {
                        var host: String?
                        var port: String = ""
                        var path: String = ""

                        for item in query {
                            switch item.name {
                            case "host":
                                if let value = item.value {
                                    host = value
                                }

                            case "port":
                                if let value = item.value, let number = Int(value) {
                                    port = ":\(number)"
                                }

                            case "secure":
                                if let value = item.value, let secure = Int(value) {
                                    scheme = secure == 0 ? "ws://" : "wss://"
                                }

                            case "path":
                                if let value = item.value {
                                    path = "/\(value)"
                                }

                            default:
                                continue
                            }
                        }

                        if let host = host, let url = URL(string: "\(scheme)\(host)\(port)\(path)") {
                            result = url
                        }
                    }
                }

            default:
                break
            }
        }

        if let result = result {
            self = result
        } else {
            return nil
        }
    }
}
