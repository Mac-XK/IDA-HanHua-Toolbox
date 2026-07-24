import Foundation

struct IDAAppInfo: Identifiable {
    let id = UUID()
    let path: String
    let version: String
    let isPatched: Bool
    let isActivated: Bool
    var macosDir: String {
        (path as NSString).appendingPathComponent("Contents/MacOS")
    }
    var displayName: String {
        "IDA Pro \(version)"
    }
}
