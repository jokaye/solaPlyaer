enum ScrubDirection {
    case forward
    case backward

    var label: String {
        switch self {
        case .forward: "快进"
        case .backward: "倒退"
        }
    }

    var systemImage: String {
        switch self {
        case .forward: "goforward"
        case .backward: "gobackward"
        }
    }
}
