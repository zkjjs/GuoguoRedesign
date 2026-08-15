struct AuthSession {
    var authorization: String?
    var cookie: String?
    var xToken: String?
    var playToken: String?

    var headers: [String: String] {
        var result: [String: String] = [:]
        if let authorization {
            result["authorization"] = authorization
        }
        if let cookie {
            result["cookie"] = cookie
        }
        if let xToken {
            result["X-Token"] = xToken
        }
        if let playToken {
            result["PLAY-TOKEN"] = playToken
        }
        return result
    }
}
