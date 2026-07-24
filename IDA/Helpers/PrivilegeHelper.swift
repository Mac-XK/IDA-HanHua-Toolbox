import Foundation

enum PrivilegeHelper {
    static func runScriptAsAdmin(_ script: String) -> (Bool, String) {
        let tmpPath = NSTemporaryDirectory() + "ida_priv_\(UUID().uuidString).sh"
        do {
            try script.write(toFile: tmpPath, atomically: true, encoding: .utf8)
            defer {
                try? FileManager.default.removeItem(atPath: tmpPath)
            }
            return runAsAdmin(commands: ["/bin/bash '\(escapeForShell(tmpPath))'"])
        } catch {
            return (false, error.localizedDescription)
        }
    }
    
    static func runAsAdmin(commands: [String]) -> (Bool, String) {
        let script = commands.joined(separator: " && ")
        let appleScript = "do shell script \"\(escapeForAppleScript(script))\" with administrator privileges"
        
        var result: (Bool, String) = (false, "未知错误")
        
        DispatchQueue.main.sync {
            var error: NSDictionary?
            if let scriptObject = NSAppleScript(source: appleScript) {
                let output = scriptObject.executeAndReturnError(&error)
                if error != nil {
                    let errNum = error?["NSAppleScriptErrorNumber"] as? Int ?? 0
                    let errMsg = error?["NSAppleScriptErrorMessage"] as? String ?? "未知错误"
                    
                    if errNum == -128 {
                        result = (false, "已取消操作")
                        return
                    }
                    
                    if errNum == -1743 {
                        result = (false, "权限被拒绝。请在系统设置 → 隐私与安全性 → 自动化 中允许本应用控制系统事件。")
                        return
                    }
                    
                    if errNum == -600 {
                        result = (false, "无法启动辅助应用")
                        return
                    }
                    
                    let lowerMsg = errMsg.lowercased()
                    let isAuthError = lowerMsg.contains("authentication")
                        || lowerMsg.contains("password")
                        || lowerMsg.contains("incorrect")
                        || lowerMsg.contains("wrong")
                        || errMsg.contains("授权")
                        || errMsg.contains("认证")
                        || errMsg.contains("密码")
                        || errMsg.contains("不正确")
                    
                    if isAuthError {
                        result = (false, "管理员密码错误（错误码：\(errNum)）\n详细信息：\(errMsg)")
                        return
                    }
                    
                    result = (false, "错误码：\(errNum)\n\(errMsg)")
                    return
                }
                result = (true, output.stringValue ?? "")
            } else {
                result = (false, "无法创建 AppleScript")
            }
        }
        
        return result
    }

    static func copyFileAsAdmin(from src: String, to dst: String) -> (Bool, String) {
        return runAsAdmin(commands: ["cp '\(escapeForShell(src))' '\(escapeForShell(dst))'"])
    }

    static func moveFileAsAdmin(from src: String, to dst: String) -> (Bool, String) {
        return runAsAdmin(commands: ["mv '\(escapeForShell(src))' '\(escapeForShell(dst))'"])
    }

    static func removeFileAsAdmin(_ path: String) -> (Bool, String) {
        return runAsAdmin(commands: ["rm -rf '\(escapeForShell(path))'"])
    }

    static func mkdirAsAdmin(_ path: String) -> (Bool, String) {
        return runAsAdmin(commands: ["mkdir -p '\(escapeForShell(path))'"])
    }

    static func writeDataAsAdmin(_ data: Data, to path: String) -> (Bool, String) {
        let tmpPath = NSTemporaryDirectory() + "ida_tmp_\(UUID().uuidString)"
        do {
            try data.write(to: URL(fileURLWithPath: tmpPath))
            defer {
                try? FileManager.default.removeItem(atPath: tmpPath)
            }
            return runAsAdmin(commands: [
                "mkdir -p '\(escapeForShell((path as NSString).deletingLastPathComponent))'",
                "cp '\(escapeForShell(tmpPath))' '\(escapeForShell(path))'"
            ])
        } catch {
            return (false, error.localizedDescription)
        }
    }

    static func chmodAsAdmin(_ path: String, mode: String) -> (Bool, String) {
        return runAsAdmin(commands: ["chmod \(mode) '\(escapeForShell(path))'"])
    }

    static func codesignAsAdmin(_ path: String) -> (Bool, String) {
        return runAsAdmin(commands: ["codesign --force --deep --sign - '\(escapeForShell(path))'"])
    }

    static func needsAdminRights(for path: String) -> Bool {
        let fm = FileManager.default
        if fm.fileExists(atPath: path) {
            return !fm.isWritableFile(atPath: path)
        }
        let parentDir = (path as NSString).deletingLastPathComponent
        return !fm.isWritableFile(atPath: parentDir)
    }

    private static func escapeForShell(_ str: String) -> String {
        return str.replacingOccurrences(of: "'", with: "'\\''")
    }

    private static func escapeForAppleScript(_ str: String) -> String {
        return str
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
