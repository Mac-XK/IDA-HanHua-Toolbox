import Foundation
import SwiftUI
import Combine

enum AppSection: String, CaseIterable, Identifiable {
    case localization = "汉化管理"
    case translation = "翻译管理"
    case activation = "IDA激活"
    case about = "关于"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .localization: return "globe"
        case .translation: return "character.book.closed.fill"
        case .activation: return "key.fill"
        case .about: return "info.circle"
        }
    }
}

struct IDAAppModel: Identifiable, Equatable {
    let id = UUID()
    let path: String
    let version: String
    let localizationStatus: String
    let activationStatus: String

    var name: String {
        (path as NSString).lastPathComponent
    }

    var displayName: String {
        "IDA Professional \(version)"
    }

    static func == (lhs: IDAAppModel, rhs: IDAAppModel) -> Bool {
        lhs.path == rhs.path
    }
}

@MainActor
class AppState: ObservableObject {
    @Published var currentSection: AppSection = .localization
    @Published var idaApps: [IDAAppModel] = []
    @Published var selectedApp: IDAAppModel?
    @Published var isProcessing = false
    @Published var logOutput = ""
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""

    @Published var userName = "MacXK"
    @Published var userEmail = "admin@hex-rays.com"
    @Published var expiryDate = "2033-12-31 23:59:59"

    init() {
        scanIDAApps()
    }

    func scanIDAApps() {
        isProcessing = true
        logOutput = "正在扫描 IDA 应用..."

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let apps = IDALocalizer.detectApps()
            let models = apps.map { info in
                IDAAppModel(
                    path: info.path,
                    version: info.version,
                    localizationStatus: info.isPatched ? "已汉化" : "未汉化",
                    activationStatus: info.isActivated ? "已激活" : "未激活"
                )
            }

            DispatchQueue.main.async {
                guard let self = self else { return }
                self.idaApps = models
                if !models.isEmpty && self.selectedApp == nil {
                    self.selectedApp = models[0]
                }
                self.logOutput += "\n✅ 找到 \(models.count) 个 IDA 应用"
                self.isProcessing = false
            }
        }
    }

    private func findIDAAppInfo(from model: IDAAppModel) -> IDAAppInfo? {
        let all = IDALocalizer.detectApps()
        return all.first { $0.path == model.path }
    }

    func installLocalization() {
        guard let app = selectedApp else { return }
        isProcessing = true
        logOutput = "正在为 \(app.displayName) 安装汉化..."

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            guard let info = self.findIDAAppInfo(from: app) else {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.logOutput += "\n❌ 未找到对应 IDA 应用"
                    self.isProcessing = false
                }
                return
            }

            IDALocalizer.install(app: info, progress: { msg in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.logOutput += "\n\(msg)"
                }
            }, completion: { success, message in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if success {
                        self.logOutput += "\n✅ 汉化安装成功\n\(message)"
                        self.showSuccess(title: "汉化安装成功", message: message)
                    } else {
                        self.logOutput += "\n❌ 安装失败\n\(message)"
                        self.showError(title: "安装失败", message: message)
                    }
                    self.scanIDAApps()
                }
            })
        }
    }

    func uninstallLocalization() {
        guard let app = selectedApp else { return }
        isProcessing = true
        logOutput = "正在为 \(app.displayName) 卸载汉化..."

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            guard let info = self.findIDAAppInfo(from: app) else {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.logOutput += "\n❌ 未找到对应 IDA 应用"
                    self.isProcessing = false
                }
                return
            }

            IDALocalizer.uninstall(app: info, progress: { msg in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.logOutput += "\n\(msg)"
                }
            }, completion: { success, message in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if success {
                        self.logOutput += "\n✅ 汉化已卸载\n\(message)"
                        self.showSuccess(title: "汉化已卸载", message: message)
                    } else {
                        self.logOutput += "\n❌ 卸载失败\n\(message)"
                        self.showError(title: "卸载失败", message: message)
                    }
                    self.scanIDAApps()
                }
            })
        }
    }

    func activate() {
        guard let app = selectedApp else { return }
        isProcessing = true
        logOutput = "正在激活 \(app.displayName)..."

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            guard let info = self.findIDAAppInfo(from: app) else {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.logOutput += "\n❌ 未找到对应 IDA 应用"
                    self.isProcessing = false
                }
                return
            }

            IDAActivator.activate(
                app: info,
                userName: self.userName,
                userEmail: self.userEmail,
                expiryDate: self.expiryDate,
                progress: { msg in
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.logOutput += "\n\(msg)"
                    }
                },
                completion: { success, message in
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        if success {
                            self.logOutput += "\n✅ 激活成功\n\(message)"
                            self.showSuccess(title: "激活成功", message: message)
                        } else {
                            self.logOutput += "\n❌ 激活失败\n\(message)"
                            self.showError(title: "激活失败", message: message)
                        }
                        self.scanIDAApps()
                    }
                }
            )
        }
    }

    private func showSuccess(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }

    private func showError(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}
