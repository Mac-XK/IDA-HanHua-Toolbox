import Foundation

enum IDALocalizer {
    private static let dylibName = "libIdaTranslateLib.dylib"
    private static let wrapperSuffix = "_orig"

    static func detectApps() -> [IDAAppInfo] {
        var results: [IDAAppInfo] = []
        var seenPaths = Set<String>()

        let searchDirs = [
            "/Applications",
            (NSHomeDirectory() as NSString).appendingPathComponent("Applications"),
            (NSHomeDirectory() as NSString).appendingPathComponent("Desktop"),
            (NSHomeDirectory() as NSString).appendingPathComponent("Downloads")
        ]

        for dir in searchDirs {
            let fm = FileManager.default
            guard let contents = try? fm.contentsOfDirectory(atPath: dir) else { continue }
            for name in contents {
                if name.hasPrefix("IDA Professional") && name.hasSuffix(".app") {
                    let appPath = (dir as NSString).appendingPathComponent(name)
                    let realPath = (appPath as NSString).resolvingSymlinksInPath
                    if seenPaths.contains(realPath) { continue }
                    seenPaths.insert(realPath)

                    let version = name
                        .replacingOccurrences(of: "IDA Professional", with: "")
                        .replacingOccurrences(of: ".app", with: "")
                        .trimmingCharacters(in: .whitespaces)

                    let macosDir = (realPath as NSString).appendingPathComponent("Contents/MacOS")
                    let fm = FileManager.default

                    let hasIDA = fm.fileExists(atPath: (macosDir as NSString).appendingPathComponent("ida"))
                        || fm.fileExists(atPath: (macosDir as NSString).appendingPathComponent("ida64"))
                    guard hasIDA else { continue }

                    let isPatched = fm.fileExists(atPath: (macosDir as NSString).appendingPathComponent(dylibName))

                    var isActivated = false
                    let licApp = (macosDir as NSString).appendingPathComponent("idapro.hexlic")
                    if fm.fileExists(atPath: licApp),
                       let data = try? Data(contentsOf: URL(fileURLWithPath: licApp)),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let payload = json["payload"] as? [String: Any],
                       let licenses = payload["licenses"] as? [[String: Any]],
                       let firstLic = licenses.first,
                       let owner = firstLic["owner"] as? String,
                       owner == "auth" {
                        isActivated = true
                    }

                    results.append(IDAAppInfo(
                        path: realPath,
                        version: version,
                        isPatched: isPatched,
                        isActivated: isActivated
                    ))
                }
            }
        }

        return results
    }

    static func install(app: IDAAppInfo, progress: @escaping (String) -> Void, completion: @escaping (Bool, String) -> Void) {
        let macosDir = app.macosDir
        let fm = FileManager.default
        let needsAdmin = PrivilegeHelper.needsAdminRights(for: macosDir)

        DispatchQueue.global(qos: .userInitiated).async {
            var messages: [String] = []
            var tempFiles: [String] = []

            progress("正在准备翻译库...")
            let dylibDest = (macosDir as NSString).appendingPathComponent(dylibName)
            let dylibData = Data(IDABundle.translateLibData)
            let tmpDir = NSTemporaryDirectory() + "ida_install_\(UUID().uuidString)"
            
            do {
                try fm.createDirectory(atPath: tmpDir, withIntermediateDirectories: true)
                tempFiles.append(tmpDir)
                
                let tmpDylib = (tmpDir as NSString).appendingPathComponent(dylibName)
                try dylibData.write(to: URL(fileURLWithPath: tmpDylib))
                
                progress("正在准备翻译文件...")
                let translations = IDABundle.translations
                let jsonData = try JSONSerialization.data(withJSONObject: translations, options: [.prettyPrinted])
                let tmpJson = (tmpDir as NSString).appendingPathComponent("ida_translations.json")
                try jsonData.write(to: URL(fileURLWithPath: tmpJson))
                
                progress("正在准备 wrapper 脚本...")
                let binaries = ["ida", "ida64", "idat", "idat64"]
                var wrapperScripts: [(bin: String, path: String)] = []
                for bin in binaries {
                    let binPath = (macosDir as NSString).appendingPathComponent(bin)
                    guard fm.fileExists(atPath: binPath) else { continue }
                    
                    let backupPath = (macosDir as NSString).appendingPathComponent("\(bin)\(wrapperSuffix)")
                    var isDir: ObjCBool = false
                    if fm.fileExists(atPath: binPath, isDirectory: &isDir) && !isDir.boolValue {
                        let isWrapper = isShellScript(path: binPath)
                        if isWrapper && fm.fileExists(atPath: backupPath) {
                            continue
                        }
                    }
                    
                    let wrapper = """
#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
export DYLD_INSERT_LIBRARIES="$DIR/\(dylibName)"
exec "$DIR/\(bin)\(wrapperSuffix)" "$@"
"""
                    let tmpWrapper = (tmpDir as NSString).appendingPathComponent("wrapper_\(bin)")
                    try wrapper.write(toFile: tmpWrapper, atomically: true, encoding: .utf8)
                    try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tmpWrapper)
                    wrapperScripts.append((bin, tmpWrapper))
                }
                
                if needsAdmin {
                    progress("需要管理员权限，正在请求授权...")
                    
                    var scriptLines = ["#!/bin/bash", "set -e"]
                    scriptLines.append("MACOS_DIR=\"\(macosDir.replacingOccurrences(of: "\"", with: "\\\""))\"")
                    scriptLines.append("TMP_DIR=\"\(tmpDir.replacingOccurrences(of: "\"", with: "\\\""))\"")
                    
                    scriptLines.append("cp \"$TMP_DIR/\(dylibName)\" \"$MACOS_DIR/\(dylibName)\"")
                    scriptLines.append("chmod 755 \"$MACOS_DIR/\(dylibName)\"")
                    
                    scriptLines.append("cp \"$TMP_DIR/ida_translations.json\" \"$MACOS_DIR/ida_translations.json\"")
                    
                    for (bin, _) in wrapperScripts {
                        let backupPath = (macosDir as NSString).appendingPathComponent("\(bin)\(wrapperSuffix)")
                        scriptLines.append("if [ ! -f \"\(backupPath)\" ]; then")
                        scriptLines.append("  mv \"$MACOS_DIR/\(bin)\" \"\(backupPath)\"")
                        scriptLines.append("fi")
                        scriptLines.append("cp \"$TMP_DIR/wrapper_\(bin)\" \"$MACOS_DIR/\(bin)\"")
                        scriptLines.append("chmod 755 \"$MACOS_DIR/\(bin)\"")
                    }
                    
                    scriptLines.append("codesign --force --deep --sign - \"$MACOS_DIR/\(dylibName)\" 2>/dev/null || true")
                    for (bin, _) in wrapperScripts {
                        scriptLines.append("codesign --force --deep --sign - \"$MACOS_DIR/\(bin)\" 2>/dev/null || true")
                    }
                    scriptLines.append("codesign --force --deep --sign - \"\(app.path)\" 2>/dev/null || true")
                    
                    let script = scriptLines.joined(separator: "\n")
                    let (ok, msg) = PrivilegeHelper.runScriptAsAdmin(script)
                    
                    try? fm.removeItem(atPath: tmpDir)
                    
                    if !ok {
                        completion(false, "安装失败: \(msg)\n" + messages.joined(separator: "\n"))
                        return
                    }
                    
                    messages.append("翻译库已复制")
                    messages.append("翻译文件已写入")
                    for (bin, _) in wrapperScripts {
                        messages.append("已处理: \(bin)")
                    }
                    messages.append("代码签名完成")
                } else {
                    progress("正在安装...")
                    
                    try dylibData.write(to: URL(fileURLWithPath: dylibDest))
                    try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dylibDest)
                    messages.append("翻译库已复制")
                    
                    let jsonDest = (macosDir as NSString).appendingPathComponent("ida_translations.json")
                    try jsonData.write(to: URL(fileURLWithPath: jsonDest))
                    messages.append("翻译文件已写入")
                    
                    for (bin, tmpWrapper) in wrapperScripts {
                        let binPath = (macosDir as NSString).appendingPathComponent(bin)
                        let backupPath = (macosDir as NSString).appendingPathComponent("\(bin)\(wrapperSuffix)")
                        
                        if !fm.fileExists(atPath: backupPath) {
                            try fm.moveItem(atPath: binPath, toPath: backupPath)
                        }
                        if fm.fileExists(atPath: binPath) {
                            try fm.removeItem(atPath: binPath)
                        }
                        try fm.copyItem(atPath: tmpWrapper, toPath: binPath)
                        try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: binPath)
                        messages.append("已处理: \(bin)")
                    }
                    
                    progress("正在重新签名...")
                    let signTargets = [dylibDest] + wrapperScripts.map { (macosDir as NSString).appendingPathComponent($0.bin) }
                    for target in signTargets {
                        guard fm.fileExists(atPath: target) else { continue }
                        _ = runProcess(["codesign", "--force", "--deep", "--sign", "-", target])
                    }
                    _ = runProcess(["codesign", "--force", "--deep", "--sign", "-", app.path])
                    messages.append("代码签名完成")
                    
                    try? fm.removeItem(atPath: tmpDir)
                }
                
                DispatchQueue.main.async {
                    completion(true, messages.joined(separator: "\n"))
                }
                
            } catch {
                try? fm.removeItem(atPath: tmpDir)
                completion(false, "安装失败: \(error.localizedDescription)\n" + messages.joined(separator: "\n"))
            }
        }
    }

    static func uninstall(app: IDAAppInfo, progress: @escaping (String) -> Void, completion: @escaping (Bool, String) -> Void) {
        let macosDir = app.macosDir
        let fm = FileManager.default
        let needsAdmin = PrivilegeHelper.needsAdminRights(for: macosDir)

        DispatchQueue.global(qos: .userInitiated).async {
            var messages: [String] = []
            let binaries = ["ida", "ida64", "idat", "idat64"]

            progress("正在准备卸载...")
            
            if needsAdmin {
                progress("需要管理员权限，正在请求授权...")
                
                var scriptLines = ["#!/bin/bash", "set -e"]
                scriptLines.append("MACOS_DIR=\"\(macosDir.replacingOccurrences(of: "\"", with: "\\\""))\"")
                
                for bin in binaries {
                    let backupPath = (macosDir as NSString).appendingPathComponent("\(bin)\(wrapperSuffix)")
                    let binPath = (macosDir as NSString).appendingPathComponent(bin)
                    scriptLines.append("if [ -f \"\(backupPath)\" ]; then")
                    scriptLines.append("  rm -f \"\(binPath)\"")
                    scriptLines.append("  mv \"\(backupPath)\" \"\(binPath)\"")
                    scriptLines.append("fi")
                }
                
                let dylibPath = (macosDir as NSString).appendingPathComponent(dylibName)
                scriptLines.append("rm -f \"\(dylibPath)\"")
                
                let jsonPath = (macosDir as NSString).appendingPathComponent("ida_translations.json")
                scriptLines.append("rm -f \"\(jsonPath)\"")
                
                for bin in binaries {
                    let binPath = (macosDir as NSString).appendingPathComponent(bin)
                    scriptLines.append("if [ -f \"\(binPath)\" ]; then")
                    scriptLines.append("  codesign --force --deep --sign - \"\(binPath)\" 2>/dev/null || true")
                    scriptLines.append("fi")
                }
                scriptLines.append("codesign --force --deep --sign - \"\(app.path)\" 2>/dev/null || true")
                
                let script = scriptLines.joined(separator: "\n")
                let (ok, msg) = PrivilegeHelper.runScriptAsAdmin(script)
                
                if !ok {
                    completion(false, "卸载失败: \(msg)\n" + messages.joined(separator: "\n"))
                    return
                }
                
                messages.append("已恢复原始文件")
                messages.append("已删除翻译文件")
                messages.append("代码签名完成")
            } else {
                progress("正在恢复原始文件...")
                
                for bin in binaries {
                    let binPath = (macosDir as NSString).appendingPathComponent(bin)
                    let backupPath = (macosDir as NSString).appendingPathComponent("\(bin)\(wrapperSuffix)")
                    
                    if fm.fileExists(atPath: backupPath) {
                        do {
                            if fm.fileExists(atPath: binPath) {
                                try fm.removeItem(atPath: binPath)
                            }
                            try fm.moveItem(atPath: backupPath, toPath: binPath)
                            messages.append("已恢复: \(bin)")
                        } catch {
                            messages.append("恢复失败 \(bin): \(error.localizedDescription)")
                        }
                    }
                }
                
                progress("正在删除翻译文件...")
                let dylibPath = (macosDir as NSString).appendingPathComponent(dylibName)
                if fm.fileExists(atPath: dylibPath) {
                    try? fm.removeItem(atPath: dylibPath)
                    messages.append("已删除翻译库")
                }
                
                let jsonPath = (macosDir as NSString).appendingPathComponent("ida_translations.json")
                if fm.fileExists(atPath: jsonPath) {
                    try? fm.removeItem(atPath: jsonPath)
                    messages.append("已删除翻译文件")
                }
                
                progress("正在重新签名...")
                for bin in binaries {
                    let binPath = (macosDir as NSString).appendingPathComponent(bin)
                    guard fm.fileExists(atPath: binPath) else { continue }
                    _ = runProcess(["codesign", "--force", "--deep", "--sign", "-", binPath])
                }
                _ = runProcess(["codesign", "--force", "--deep", "--sign", "-", app.path])
                messages.append("代码签名完成")
            }

            DispatchQueue.main.async {
                completion(true, messages.joined(separator: "\n"))
            }
        }
    }

    private static func isShellScript(path: String) -> Bool {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return false }
        if data.count < 2 { return false }
        return data[0] == 0x23 && data[1] == 0x21
    }

    static func runProcess(_ args: [String]) -> (Int32, String, String) {
        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = args

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        do {
            try process.run()
            process.waitUntilExit()

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
