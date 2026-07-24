import Foundation
import CommonCrypto

enum IDAActivator {
    private static let defaultUserName = "MacXK"
    private static let defaultUserEmail = "admin@hex-rays.com"
    private static let defaultExpiryDate = "2033-12-31 23:59:59"

    private static let cModulus: [UInt8] = [
        0x3f, 0x03, 0x07, 0x60, 0x7f, 0xed, 0x56, 0x2f, 0xd5, 0xa1, 0x63, 0xad, 0xc4, 0x0f, 0xcc, 0x60,
        0x33, 0x73, 0xca, 0xa2, 0x84, 0x14, 0xe6, 0x4c, 0xdc, 0x45, 0x52, 0xa5, 0x55, 0xb1, 0x3a, 0xd4,
        0xb3, 0xad, 0x0a, 0x81, 0x28, 0x00, 0xa0, 0x31, 0x95, 0x30, 0x0f, 0xd7, 0x16, 0x34, 0xb9, 0x0e,
        0xdb, 0x0d, 0x69, 0xea, 0x71, 0x0e, 0xfe, 0xbb, 0x2b, 0x0b, 0x9e, 0x72, 0xda, 0x2e, 0xff, 0xb1,
        0x49, 0xde, 0x70, 0xbc, 0xbf, 0xa9, 0x4b, 0x86, 0xaf, 0x01, 0xce, 0x45, 0x5d, 0xbb, 0xd5, 0xfa,
        0x98, 0x72, 0x07, 0x65, 0x1c, 0x7b, 0x60, 0xc2, 0xe4, 0xca, 0xfd, 0x06, 0x54, 0x18, 0x8d, 0x98,
        0xc3, 0x0f, 0x64, 0xdc, 0x08, 0x4d, 0x85, 0x47, 0xf0, 0xac, 0x32, 0xdb, 0x91, 0x12, 0x4a, 0xf8,
        0x2b, 0x3b, 0x15, 0xbf, 0x92, 0x2a, 0x31, 0xf1, 0xd5, 0xe3, 0x32, 0xf2, 0x76, 0x15, 0xce, 0xa7
    ]

    private static let privateKey: [UInt8] = [
        0x8b, 0x3f, 0x5f, 0xdf, 0xad, 0x7f, 0x87, 0x23, 0x97, 0x34, 0xc5, 0x30, 0xe2, 0xec, 0xeb, 0xeb,
        0x4f, 0xa4, 0x8d, 0x79, 0x51, 0x87, 0x56, 0xc1, 0x5f, 0xd5, 0x46, 0x36, 0x80, 0x1c, 0xf7, 0xea,
        0x63, 0x67, 0x10, 0x05, 0x66, 0xbf, 0x8b, 0x52, 0xb1, 0x6b, 0xec, 0x05, 0x25, 0x8d, 0x84, 0x26,
        0xea, 0x94, 0xc1, 0x58, 0x41, 0xab, 0x2d, 0x37, 0x80, 0x2c, 0x07, 0x34, 0x9d, 0xf4, 0xc2, 0x08,
        0x58, 0x4e, 0x86, 0xd2, 0x5a, 0x6b, 0xfb, 0x82, 0x96, 0x6c, 0xb2, 0xdd, 0xcd, 0x3d, 0x65, 0x4e,
        0x99, 0x94, 0xe8, 0x14, 0xca, 0x47, 0x05, 0x77, 0x36, 0x2a, 0x93, 0x7c, 0xc9, 0x84, 0xe4, 0x04,
        0xa0, 0xb6, 0x8d, 0x17, 0x3a, 0xab, 0x31, 0x80, 0x13, 0x01, 0x18, 0xe1, 0xb0, 0x3e, 0xd2, 0x09,
        0xa9, 0xd8, 0x75, 0x75, 0x60, 0xa8, 0x5a, 0x3c, 0x9b, 0x0d, 0x33, 0x80, 0xe7, 0x90, 0x7c, 0x4f
    ]

    private static let v54 = 127
    private static let v56 = 95

    private static let padKey: [UInt8] = [
        0xe2, 0xa7, 0xc3, 0x00, 0xdf, 0xcc, 0x77, 0x7f, 0x89, 0xb5, 0x75, 0x00, 0xd8, 0x15, 0x1c, 0x7f,
        0xb1, 0xd9, 0x7b, 0x3f, 0x9f, 0x17, 0x03, 0x93, 0x31, 0x12, 0x34, 0xce, 0xeb, 0x9e, 0x37, 0x7a,
        0xe2, 0xa7, 0xc3, 0x00, 0xdf, 0xcc, 0x77, 0x7f, 0x89, 0xb5, 0x75, 0x00, 0xd8, 0x15, 0x1c, 0x7f,
        0xb1, 0xd9, 0x7b, 0x3f, 0x9f, 0x17, 0x03, 0x93, 0x31, 0x12, 0x34, 0xce, 0xeb, 0x9e, 0x37, 0x7a,
        0xe2, 0xa7, 0xc3, 0x00, 0xdf, 0xcc, 0x77, 0x7f, 0x89, 0xb5, 0x75, 0x00, 0xd8, 0x15, 0x1c, 0x7f,
        0xb1, 0xd9, 0x7b, 0x3f, 0x9f, 0x17, 0x03, 0x93, 0x31, 0x12, 0x34, 0xce, 0xeb, 0x9e, 0x37, 0x7a,
        0xe2, 0xa7, 0xc3, 0x00, 0xdf, 0xcc, 0x77, 0x7f, 0x89, 0xb5, 0x75, 0x00, 0xd8, 0x15, 0x1c, 0x7f,
        0xb1, 0xd9, 0x7b, 0x3f, 0x9f, 0x17, 0x03, 0x93, 0x31, 0x12, 0x34, 0xce, 0xeb, 0x9e, 0x37
    ]

    private static let patchSearch: [UInt8] = [
        0x29, 0xf4, 0x48, 0x1f, 0x79, 0x6f, 0x9f, 0x66, 0xf2, 0xff, 0x13, 0xcc, 0x4a, 0xb5, 0xb5, 0x4f,
        0x60, 0x84, 0x5d, 0xb6, 0x03, 0xba, 0x2c, 0x0b, 0xac, 0x8a, 0x9b, 0xc4, 0xb6, 0xcb, 0xde, 0xfc,
        0x5c, 0x62, 0xbf, 0xc2, 0xf5, 0xee, 0x85, 0x0a, 0xc4, 0x5e, 0xa9, 0x7a, 0xd3, 0x47, 0xe8, 0xb5,
        0x6d, 0xba, 0x50, 0x85, 0xaf, 0x8c, 0x8a, 0xad, 0x9c, 0xc2, 0xec, 0x62, 0x6c, 0xa7, 0x8a, 0x06,
        0x80, 0x06, 0xd6, 0x58, 0xf6, 0x86, 0x51, 0xda, 0x31, 0xa0, 0xa7, 0x7c, 0x65, 0xa7, 0x0e, 0xd7,
        0x3a, 0x40, 0xd5, 0x3b, 0x08, 0xed, 0xd4, 0x03, 0xc0, 0x95, 0xaa, 0x0b, 0xcf, 0xfa, 0x52, 0xf3,
        0x13, 0xeb, 0xca, 0xca, 0xaa, 0x2c, 0xe5, 0x02, 0x4a, 0x4e, 0x2b, 0x9a, 0xa7, 0x0f, 0xc6, 0x09,
        0x2f, 0x38, 0xae, 0x09, 0x4d, 0x71, 0xe4, 0x3f, 0x76, 0x90, 0xb5, 0xdd, 0xd3, 0xe9, 0xe4, 0xf7
    ]

    private static let patchReplace: [UInt8] = [
        0xa1, 0x07, 0xb7, 0x1c, 0x8a, 0x08, 0xba, 0x53, 0x50, 0x93, 0x4f, 0x7c, 0xf6, 0xe8, 0x1b, 0xe3,
        0xa2, 0x4d, 0xc2, 0xe3, 0x5f, 0x72, 0x00, 0xd8, 0x0c, 0xbd, 0x70, 0xb3, 0x7e, 0xd6, 0x81, 0x1d,
        0xd2, 0x14, 0x6d, 0x3c, 0xb7, 0xe2, 0x0a, 0xd1, 0x9b, 0x25, 0x44, 0xc0, 0xef, 0x14, 0xc5, 0xc6,
        0x6f, 0xfb, 0xbd, 0xf2, 0x26, 0xec, 0x3f, 0x3d, 0x54, 0x4c, 0x04, 0x38, 0x53, 0x03, 0xca, 0x4a,
        0x71, 0x79, 0x29, 0x93, 0x40, 0x02, 0x2f, 0x5d, 0x50, 0x94, 0x8b, 0xcf, 0x8a, 0x60, 0x30, 0x7e,
        0x2c, 0x19, 0x63, 0x29, 0xe5, 0x1a, 0x52, 0x96, 0xdc, 0x41, 0x9e, 0x40, 0xfe, 0xf3, 0xef, 0x7c,
        0x6f, 0x01, 0x5a, 0x09, 0xeb, 0xd9, 0x79, 0xe7, 0x96, 0x15, 0x33, 0x89, 0x85, 0x64, 0x3e, 0x66,
        0x6c, 0x14, 0x89, 0x7f, 0x9f, 0x59, 0x7e, 0x11, 0xf4, 0x43, 0x41, 0xf4, 0x96, 0xd5, 0x68, 0x61
    ]

    private static let patchDylibs = ["libida.dylib", "libida32.dylib"]

    private static let addons = [
        "LUMINA", "TEAMS",
        "HEXX86", "HEXX64", "HEXARM", "HEXARM64",
        "HEXMIPS", "HEXMIPS64", "HEXPPC", "HEXPPC64",
        "HEXRV", "HEXRV64", "HEXARC", "HEXARC64",
        "HEXV850", "HEXDALVIK"
    ]

    static func activate(app: IDAAppInfo,
                        userName: String = defaultUserName,
                        userEmail: String = defaultUserEmail,
                        expiryDate: String = defaultExpiryDate,
                        progress: @escaping (String) -> Void,
                        completion: @escaping (Bool, String) -> Void) {
        let macosDir = app.macosDir
        let fm = FileManager.default
        let needsAdmin = PrivilegeHelper.needsAdminRights(for: macosDir)

        DispatchQueue.global(qos: .userInitiated).async {
            var messages: [String] = []
            let tmpDir = NSTemporaryDirectory() + "ida_activate_\(UUID().uuidString)"

            guard fm.fileExists(atPath: macosDir) else {
                completion(false, "未找到 MacOS 目录: \(macosDir)")
                return
            }

            progress("正在生成许可证...")
            let licContent = generateLicense(userName: userName, userEmail: userEmail, expiryDate: expiryDate)

            do {
                try fm.createDirectory(atPath: tmpDir, withIntermediateDirectories: true)
                defer { try? fm.removeItem(atPath: tmpDir) }

                let tmpLic = (tmpDir as NSString).appendingPathComponent("idapro.hexlic")
                try licContent.data(using: .utf8)?.write(to: URL(fileURLWithPath: tmpLic))

                progress("正在准备补丁...")
                var patchedFiles: [String] = []
                var skippedFiles: [String] = []

                for dylibName in patchDylibs {
                    let srcPath = (macosDir as NSString).appendingPathComponent(dylibName)
                    guard fm.fileExists(atPath: srcPath) else {
                        skippedFiles.append("\(dylibName): 文件不存在")
                        continue
                    }

                    var data = try [UInt8](Data(contentsOf: URL(fileURLWithPath: srcPath)))
                    
                    if data.firstRange(of: patchReplace) != nil {
                        skippedFiles.append("\(dylibName): 已补丁")
                        continue
                    }
                    
                    var count = 0
                    var idx = data.firstRange(of: patchSearch)?.lowerBound

                    while idx != nil {
                        let start = idx!
                        let end = start + patchSearch.count
                        guard end <= data.count else { break }
                        data.replaceSubrange(start..<end, with: patchReplace)
                        count += 1
                        let searchStart = start + patchReplace.count
                        if searchStart >= data.count { break }
                        idx = data[searchStart...].firstRange(of: patchSearch)?.lowerBound
                    }

                    if count > 0 {
                        let tmpPath = (tmpDir as NSString).appendingPathComponent(dylibName)
                        try Data(data).write(to: URL(fileURLWithPath: tmpPath))
                        patchedFiles.append(dylibName)
                    } else {
                        skippedFiles.append("\(dylibName): 未找到特征码")
                    }
                }

                if needsAdmin {
                    progress("需要管理员权限，正在请求授权...")

                    var scriptLines = ["#!/bin/bash", "set -e"]
                    scriptLines.append("MACOS_DIR=\"\(macosDir.replacingOccurrences(of: "\"", with: "\\\""))\"")
                    scriptLines.append("TMP_DIR=\"\(tmpDir.replacingOccurrences(of: "\"", with: "\\\""))\"")

                    scriptLines.append("cp \"$TMP_DIR/idapro.hexlic\" \"$MACOS_DIR/idapro.hexlic\"")
                    scriptLines.append("cp \"$TMP_DIR/idapro.hexlic\" \"$MACOS_DIR/ida.hexlic\"")

                    for dylibName in patchedFiles {
                        scriptLines.append("cp \"$TMP_DIR/\(dylibName)\" \"$MACOS_DIR/\(dylibName)\"")
                    }

                    let allTargets = patchedFiles + ["ida", "ida64", "idat", "idat64"]
                    for target in allTargets {
                        scriptLines.append("if [ -f \"$MACOS_DIR/\(target)\" ]; then")
                        scriptLines.append("  codesign --force --deep --sign - \"$MACOS_DIR/\(target)\" 2>/dev/null || true")
                        scriptLines.append("fi")
                    }
                    scriptLines.append("codesign --force --deep --sign - \"\(app.path)\" 2>/dev/null || true")

                    let script = scriptLines.joined(separator: "\n")
                    let (ok, msg) = PrivilegeHelper.runScriptAsAdmin(script)

                    if !ok {
                        completion(false, "激活失败: \(msg)\n" + messages.joined(separator: "\n"))
                        return
                    }
                } else {
                    progress("正在写入许可证...")
                    let licApp = (macosDir as NSString).appendingPathComponent("idapro.hexlic")
                    try licContent.write(toFile: licApp, atomically: true, encoding: .utf8)

                    let licIda = (macosDir as NSString).appendingPathComponent("ida.hexlic")
                    try? fm.copyItem(atPath: licApp, toPath: licIda)

                    progress("正在应用补丁...")
                    for dylibName in patchedFiles {
                        let tmpPath = (tmpDir as NSString).appendingPathComponent(dylibName)
                        let destPath = (macosDir as NSString).appendingPathComponent(dylibName)
                        try fm.removeItem(atPath: destPath)
                        try fm.copyItem(atPath: tmpPath, toPath: destPath)
                    }

                    progress("正在重新签名...")
                    let _ = codesignFiles(idaDir: macosDir, appPath: app.path, needsAdmin: false)
                }

                messages.append("许可证已生成")
                if !patchedFiles.isEmpty {
                    messages.append("补丁成功:")
                    messages.append(contentsOf: patchedFiles.map { "  \($0)" })
                }
                if !skippedFiles.isEmpty {
                    messages.append("跳过/失败:")
                    messages.append(contentsOf: skippedFiles.map { "  \($0)" })
                }
                messages.append("代码签名完成")

                progress("正在测试运行...")
                let (testOk, testMsg) = testIDA(idaDir: macosDir)
                messages.append("运行测试: \(testMsg)")

                DispatchQueue.main.async {
                    completion(testOk, messages.joined(separator: "\n"))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, "激活失败: \(error.localizedDescription)\n" + messages.joined(separator: "\n"))
                }
            }
        }
    }

    static func checkActivation(app: IDAAppInfo) -> (Bool, String) {
        let macosDir = app.macosDir
        let licApp = (macosDir as NSString).appendingPathComponent("idapro.hexlic")
        let fm = FileManager.default

        guard fm.fileExists(atPath: licApp) else {
            return (false, "未激活")
        }
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: licApp)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let payload = json["payload"] as? [String: Any],
              let licenses = payload["licenses"] as? [[String: Any]],
              let firstLic = licenses.first,
              let owner = firstLic["owner"] as? String else {
            return (false, "许可证无效")
        }
        
        let isOurLicense = owner == defaultUserName
        let patched = isDylibPatched(idaDir: macosDir)
        
        if isOurLicense && patched {
            return (true, "已激活")
        } else if isOurLicense && !patched {
            return (false, "许可证存在但缺少补丁")
        } else if !isOurLicense && patched {
            return (false, "已打补丁但缺少有效许可证")
        }
        return (false, "未激活")
    }
    
    static func isDylibPatched(idaDir: String) -> Bool {
        let fm = FileManager.default
        for dylibName in patchDylibs {
            let path = (idaDir as NSString).appendingPathComponent(dylibName)
            guard fm.fileExists(atPath: path) else { continue }
            guard let data = try? [UInt8](Data(contentsOf: URL(fileURLWithPath: path))) else { continue }
            if data.firstRange(of: patchSearch) == nil {
                return true
            }
        }
        return false
    }

    private static func generateLicense(userName: String, userEmail: String, expiryDate: String) -> String {
        var licenseData: [String: Any] = [
            "header": ["version": 1],
            "payload": [
                "name": userName,
                "email": userEmail,
                "licenses": [
                    [
                        "description": "license",
                        "edition_id": "ida-pro",
                        "id": "14-0000-FFFF-88",
                        "license_type": "named",
                        "product": "IDA",
                        "seats": 1,
                        "start_date": "2024-08-10 00:00:00",
                        "end_date": expiryDate,
                        "issued_on": "2025-07-20 00:00:00",
                        "owner": userName,
                        "product_id": "IDAPRO",
                        "product_version": "9.4",
                        "add_ons": [],
                        "features": []
                    ]
                ]
            ]
        ]

        var addOns: [[String: Any]] = []
        for (i, addon) in addons.enumerated() {
            addOns.append([
                "id": String(format: "48-1337-B00B-%02d", i + 1),
                "code": addon,
                "owner": "14-0000-FFFF-88",
                "start_date": "2025-07-20 00:00:00",
                "end_date": expiryDate
            ])
        }

        if var payload = licenseData["payload"] as? [String: Any],
           var licenses = payload["licenses"] as? [[String: Any]],
           !licenses.isEmpty {
            licenses[0]["add_ons"] = addOns
            payload["licenses"] = licenses
            licenseData["payload"] = payload
        }

        guard let payload = licenseData["payload"] else { return "" }
        let dataStr = sortObj(["payload": payload])
        let hashData = sha256(dataStr)

        var U = [UInt8](repeating: 0, count: v54)
        U[v56...] = Array(hashData.prefix(v54 - v56))[...]

        var block = [UInt8](repeating: 0, count: v54)
        for i in 0..<v54 {
            block[i] = U[i] ^ padKey[i]
        }
        if block[0] == 0 {
            block[0] ^= 1
        }

        let sig = rsaEncrypt(message: block, cModulus: cModulus, privateKey: privateKey)
        var out = [UInt8](repeating: 0, count: 128)
        let sigLen = min(sig.count, 128)
        out.replaceSubrange(0..<sigLen, with: sig.prefix(sigLen))

        let signatureHex = out.map { String(format: "%02X", $0) }.joined()
        licenseData["signature"] = signatureHex

        return sortObj(licenseData)
    }

    private static func sortObj(_ obj: Any) -> String {
        if let arr = obj as? [Any] {
            return "[" + arr.map { sortObj($0) }.joined(separator: ",") + "]"
        } else if let dict = obj as? [String: Any] {
            let keys = dict.keys.sorted()
            return "{" + keys.map { "\"\($0)\":\(sortObj(dict[$0]!))" }.joined(separator: ",") + "}"
        } else if let str = obj as? String {
            let escaped = str
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\r", with: "\\r")
                .replacingOccurrences(of: "\t", with: "\\t")
            return "\"\(escaped)\""
        } else if let num = obj as? Int {
            return String(num)
        } else if let num = obj as? Double {
            return String(num)
        } else if let bool = obj as? Bool {
            return bool ? "true" : "false"
        } else if obj is NSNull {
            return "null"
        } else {
            return "null"
        }
    }

    private static func sha256(_ string: String) -> [UInt8] {
        let data = string.data(using: .utf8)!
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { buf in
            _ = CC_SHA256(buf.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash
    }

    private static func bytesToIntLE(_ bytes: [UInt8]) -> BigInt {
        BigInt(bytes: bytes, littleEndian: true)
    }

    private static func rsaEncrypt(message: [UInt8], cModulus: [UInt8], privateKey: [UInt8]) -> [UInt8] {
        let modulus = bytesToIntLE(cModulus)
        let exponent = bytesToIntLE(privateKey)
        let reversedMsg = Array(message.reversed())
        let msg = bytesToIntLE(reversedMsg)

        let base = msg % modulus
        var result = BigInt(value: 1)
        var exp = exponent
        var b = base

        while exp > BigInt(value: 0) {
            if exp.isOdd {
                result = (result * b) % modulus
            }
            exp = exp >> 1
            b = (b * b) % modulus
        }

        return result.bytesLE()
    }

    private static func patchDylibs(idaDir: String, needsAdmin: Bool) -> ([String], [String]) {
        var patched: [String] = []
        var skipped: [String] = []
        let fm = FileManager.default

        for dylibName in patchDylibs {
            let path = (idaDir as NSString).appendingPathComponent(dylibName)
            guard fm.fileExists(atPath: path) else {
                skipped.append("\(dylibName): 文件不存在")
                continue
            }

            do {
                var data = try [UInt8](Data(contentsOf: URL(fileURLWithPath: path)))
                var count = 0
                var idx = data.firstRange(of: patchSearch)?.lowerBound

                while idx != nil {
                    let start = idx!
                    let end = start + patchSearch.count
                    guard end <= data.count else { break }
                    data.replaceSubrange(start..<end, with: patchReplace)
                    count += 1
                    let searchStart = start + patchReplace.count
                    if searchStart >= data.count { break }
                    idx = data[searchStart...].firstRange(of: patchSearch)?.lowerBound
                }

                if count > 0 {
                    if needsAdmin {
                        let (ok, _) = PrivilegeHelper.writeDataAsAdmin(Data(data), to: path)
                        if ok {
                            patched.append("\(dylibName): 补丁 \(count) 处")
                        } else {
                            skipped.append("\(dylibName): 写入失败")
                        }
                    } else {
                        try Data(data).write(to: URL(fileURLWithPath: path))
                        patched.append("\(dylibName): 补丁 \(count) 处")
                    }
                } else {
                    skipped.append("\(dylibName): 未找到特征码")
                }
            } catch {
                skipped.append("\(dylibName): \(error.localizedDescription)")
            }
        }

        return (patched, skipped)
    }

    private static func codesignFiles(idaDir: String, appPath: String, needsAdmin: Bool) -> (Bool, String) {
        let fm = FileManager.default
        let targets = [
            "libida.dylib", "libida32.dylib", "libida64.dylib",
            "ida", "ida64", "idat", "idat64"
        ].compactMap { name -> String? in
            let path = (idaDir as NSString).appendingPathComponent(name)
            return fm.fileExists(atPath: path) ? path : nil
        } + [appPath]

        var allOk = true
        var messages: [String] = []

        for target in targets {
            let name = URL(fileURLWithPath: target).lastPathComponent
            if needsAdmin {
                let (ok, _) = PrivilegeHelper.codesignAsAdmin(target)
                if !ok {
                    allOk = false
                    messages.append("\(name): 签名失败")
                } else {
                    messages.append("\(name): 签名成功")
                }
            } else {
                let result = IDALocalizer.runProcess(
                    ["codesign", "--force", "--deep", "--sign", "-", target]
                )
                if result.0 != 0 {
                    allOk = false
                    messages.append("\(name): 签名失败")
                } else {
                    messages.append("\(name): 签名成功")
                }
            }
        }

        return (allOk, messages.joined(separator: "\n"))
    }

    private static func testIDA(idaDir: String) -> (Bool, String) {
        let fm = FileManager.default
        let idatNames = ["idat", "idat64"]
        var idatPath: String?

        for name in idatNames {
            let p = (idaDir as NSString).appendingPathComponent(name)
            if fm.fileExists(atPath: p) {
                idatPath = p
                break
            }
        }

        guard let idatPath = idatPath else {
            return (false, "未找到 idat 可执行文件")
        }

        let result = runProcessWithTimeout([idatPath, "-B", "/bin/ls"], timeout: 60)
        let output = result.1 + result.2

        if output.contains("Failed to initialize") || output.contains("error code 2") || output.contains("License is invalid") {
            return (false, "IDA 测试失败")
        }
        return (true, "IDA 测试通过")
    }

    private static func runProcessWithTimeout(_ args: [String], timeout: TimeInterval) -> (Int32, String, String) {
        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = args

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        do {
            try process.run()

            let deadline = DispatchTime.now() + timeout
            let sem = DispatchSemaphore(value: 0)

            DispatchQueue.global().async {
                process.waitUntilExit()
                sem.signal()
            }

            let timedOut = sem.wait(timeout: deadline) == .timedOut
            if timedOut {
                process.terminate()
            }

            let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            let outStr = String(data: outData, encoding: .utf8) ?? ""
            let errStr = String(data: errData, encoding: .utf8) ?? ""

            return (process.terminationStatus, outStr, errStr)
        } catch {
            return (-1, "", error.localizedDescription)
        }
    }
}

struct BigInt {
    private var words: [UInt64]

    init(value: Int) {
        if value < 0 {
            self.words = [0]
        } else {
            self.words = [UInt64(value)]
        }
    }

    init(bytes: [UInt8], littleEndian: Bool) {
        var data = bytes
        if !littleEndian {
            data = data.reversed()
        }

        var w: [UInt64] = []
        var i = 0
        while i < data.count {
            var word: UInt64 = 0
            for j in 0..<8 {
                if i + j < data.count {
                    word |= UInt64(data[i + j]) << (j * 8)
                }
            }
            w.append(word)
            i += 8
        }

        while w.count > 1 && w.last == 0 {
            w.removeLast()
        }

        self.words = w.isEmpty ? [0] : w
    }

    func bytesLE() -> [UInt8] {
        var result: [UInt8] = []
        for word in words {
            for j in 0..<8 {
                result.append(UInt8((word >> (j * 8)) & 0xFF))
            }
        }
        while result.count > 1 && result.last == 0 {
            result.removeLast()
        }
        return result
    }

    var isZero: Bool {
        words.count == 1 && words[0] == 0
    }

    var isOdd: Bool {
        words[0] & 1 == 1
    }

    static func +(lhs: BigInt, rhs: BigInt) -> BigInt {
        let maxCount = max(lhs.words.count, rhs.words.count)
        var result: [UInt64] = []
        var carry: UInt64 = 0

        for i in 0..<maxCount {
            let a = i < lhs.words.count ? lhs.words[i] : 0
            let b = i < rhs.words.count ? rhs.words[i] : 0
            let (sum, c1) = a.addingReportingOverflow(b)
            let (total, c2) = sum.addingReportingOverflow(carry)
            result.append(total)
            carry = (c1 ? 1 : 0) + (c2 ? 1 : 0)
        }

        if carry > 0 {
            result.append(carry)
        }

        return BigInt(words: result)
    }

    static func *(lhs: BigInt, rhs: BigInt) -> BigInt {
        var result = [UInt64](repeating: 0, count: lhs.words.count + rhs.words.count)

        for i in 0..<lhs.words.count {
            var carry: UInt64 = 0
            for j in 0..<rhs.words.count {
                let a = lhs.words[i]
                let b = rhs.words[j]
                let (high, low) = a.multipliedFullWidth(by: b)
                let (sum1, c1) = result[i + j].addingReportingOverflow(low)
                let (sum2, c2) = sum1.addingReportingOverflow(carry)
                result[i + j] = sum2
                carry = high + (c1 ? 1 : 0) + (c2 ? 1 : 0)
            }
            if carry > 0 {
                result[i + rhs.words.count] = carry
            }
        }

        while result.count > 1 && result.last == 0 {
            result.removeLast()
        }

        return BigInt(words: result)
    }

    static func %(lhs: BigInt, rhs: BigInt) -> BigInt {
        var remainder = lhs
        let divisor = rhs

        if divisor.isZero {
            return BigInt(value: 0)
        }

        if lhs < rhs {
            return lhs
        }

        var shift = 0
        var shifted = divisor
        while shifted <= remainder {
            shift += 1
            shifted = shifted << 1
        }
        shift -= 1

        while shift >= 0 {
            shifted = divisor << shift
            if shifted <= remainder {
                remainder = remainder - shifted
            }
            shift -= 1
        }

        return remainder
    }

    static func -(lhs: BigInt, rhs: BigInt) -> BigInt {
        var result: [UInt64] = []
        var borrow: UInt64 = 0

        for i in 0..<lhs.words.count {
            let a = lhs.words[i]
            let b = i < rhs.words.count ? rhs.words[i] : 0

            let (diff, b1) = a.subtractingReportingOverflow(b)
            let (total, b2) = diff.subtractingReportingOverflow(borrow)
            result.append(total)
            borrow = (b1 ? 1 : 0) + (b2 ? 1 : 0)
        }

        while result.count > 1 && result.last == 0 {
            result.removeLast()
        }

        return BigInt(words: result)
    }

    static func <<(lhs: BigInt, rhs: Int) -> BigInt {
        if rhs == 0 || lhs.isZero { return lhs }

        let wordShift = rhs / 64
        let bitShift = rhs % 64

        var words = [UInt64](repeating: 0, count: lhs.words.count + wordShift + 1)

        for i in 0..<lhs.words.count {
            if bitShift == 0 {
                words[i + wordShift] = lhs.words[i]
            } else {
                words[i + wordShift] |= lhs.words[i] << bitShift
                words[i + wordShift + 1] |= lhs.words[i] >> (64 - bitShift)
            }
        }

        while words.count > 1 && words.last == 0 {
            words.removeLast()
        }

        return BigInt(words: words)
    }

    static func >>(lhs: BigInt, rhs: Int) -> BigInt {
        if rhs == 0 || lhs.isZero { return lhs }

        let wordShift = rhs / 64
        let bitShift = rhs % 64

        if wordShift >= lhs.words.count {
            return BigInt(value: 0)
        }

        var words: [UInt64] = []
        for i in wordShift..<lhs.words.count {
            var val = lhs.words[i] >> bitShift
            if bitShift > 0 && i + 1 < lhs.words.count {
                val |= lhs.words[i + 1] << (64 - bitShift)
            }
            words.append(val)
        }

        while words.count > 1 && words.last == 0 {
            words.removeLast()
        }

        return BigInt(words: words)
    }

    static func <(lhs: BigInt, rhs: BigInt) -> Bool {
        if lhs.words.count != rhs.words.count {
            return lhs.words.count < rhs.words.count
        }
        for i in (0..<lhs.words.count).reversed() {
            if lhs.words[i] != rhs.words[i] {
                return lhs.words[i] < rhs.words[i]
            }
        }
        return false
    }

    static func <=(lhs: BigInt, rhs: BigInt) -> Bool {
        !(lhs > rhs)
    }

    static func >(lhs: BigInt, rhs: BigInt) -> Bool {
        rhs < lhs
    }

    static func ==(lhs: BigInt, rhs: BigInt) -> Bool {
        lhs.words == rhs.words
    }

    private init(words: [UInt64]) {
        var w = words
        while w.count > 1 && w.last == 0 {
            w.removeLast()
        }
        self.words = w.isEmpty ? [0] : w
    }
}
