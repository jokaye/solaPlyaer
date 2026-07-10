import Foundation

enum BuildInfo {
    static var version: String {
        requiredBundleValue(for: "CFBundleShortVersionString")
    }

    static var buildNumber: String {
        requiredBundleValue(for: "CFBundleVersion")
    }

    static var gitCommitSHA: String {
        requiredBundleValue(for: "GitCommitSHA")
    }

    private static func requiredBundleValue(for key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              !value.isEmpty else {
            assertionFailure("Missing required bundle value: \(key)")
            return "missing"
        }
        return value
    }
}
