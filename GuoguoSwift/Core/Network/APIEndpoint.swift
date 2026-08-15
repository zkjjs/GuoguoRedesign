enum APIEndpoint {
    case appConfig
    case banners
    case channels
    case videoList
    case videoSearch
    case videoDetail
    case videoPlay
    case playbackToken
    case playbackAddressV3

    var path: String {
        switch self {
        case .appConfig:
            return "/app/config"
        case .banners:
            return "/app/banners/"
        case .channels:
            return "/app/channel/"
        case .videoList:
            return "/app/video/list"
        case .videoSearch:
            return "/app/video/search"
        case .videoDetail:
            return "/app/video/detail"
        case .videoPlay:
            return "/app/video/play"
        case .playbackToken:
            return "/app/playaddr/get/token"
        case .playbackAddressV3:
            return "/app/playaddr/v3/get"
        }
    }
}
