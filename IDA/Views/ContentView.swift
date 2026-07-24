import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            TopTabBar()

            Divider()

            if appState.currentSection != .about {
                AppSelectorBar()
            }

            ZStack {
                switch appState.currentSection {
                case .localization:
                    LocalizationTabView()
                case .translation:
                    TranslationTabView()
                case .activation:
                    ActivationTabView()
                case .about:
                    AboutTabView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .alert(appState.alertTitle, isPresented: $appState.showAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(appState.alertMessage)
        }
    }
}

// MARK: - 顶部 TabBar (更精致)

struct TopTabBar: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "hammer.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 1) {
                    Text("IDA 汉化工具箱")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Hex-Rays 辅助工具")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.leading, 24)

            Spacer()

            HStack(spacing: 4) {
                ForEach(AppSection.allCases) { section in
                    TabItem(
                        section: section,
                        isSelected: appState.currentSection == section,
                        action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                appState.currentSection = section
                            }
                        }
                    )
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 1)
            )

            Spacer()

            HStack(spacing: 8) {
                Button {
                    appState.scanIDAApps()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .medium))
                        Text("扫描")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.secondary.opacity(0.08))
                    )
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .disabled(appState.isProcessing)
                .help("重新扫描")
            }
            .padding(.trailing, 24)
        }
        .frame(height: 58)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.98))
    }
}

struct TabItem: View {
    let section: AppSection
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: section.icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(section.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
            }
            .foregroundStyle(isSelected ? Color.accentColor : .primary.opacity(0.7))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                isSelected ?
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.12))
                : nil
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 应用选择器 (更漂亮)

struct AppSelectorBar: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 16) {
            if let app = appState.selectedApp {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.accentColor.opacity(0.08))
                            .frame(width: 42, height: 42)

                        AppIconView(appPath: app.path)
                            .frame(width: 36, height: 36)
                            .cornerRadius(8)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(app.displayName)
                            .font(.system(size: 15, weight: .semibold))

                        Text(app.path)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: 240, alignment: .leading)
                    }
                }

                Spacer()

                HStack(spacing: 10) {
                    StatusTag(text: app.localizationStatus, isActive: app.localizationStatus.contains("已"))
                    StatusTag(text: app.activationStatus, isActive: app.activationStatus.contains("已"))
                }

                Menu {
                    ForEach(appState.idaApps) { otherApp in
                        Button(otherApp.displayName) {
                            appState.selectedApp = otherApp
                        }
                    }
                    Divider()
                    Button("重新扫描") {
                        appState.scanIDAApps()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text("切换")
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

            } else {
                HStack(spacing: 14) {
                    Image(systemName: "app.badge")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary.opacity(0.7))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("未选择目标应用")
                            .font(.system(size: 14, weight: .medium))
                        Text("请扫描并选择一个 IDA Professional")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        appState.scanIDAApps()
                    } label: {
                        Label("扫描", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.secondary.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

struct StatusTag: View {
    let text: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isActive ? Color.green : Color.secondary)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(isActive ? .green : .secondary)
        .padding(.horizontal, 9)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(isActive ? Color.green.opacity(0.1) : Color.secondary.opacity(0.08))
        )
    }
}

// MARK: - Tab 内容视图

struct LocalizationTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        Image(systemName: "globe")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                        Text("汉化管理")
                            .font(.system(size: 26, weight: .semibold))
                    }
                    Text("安装或卸载 IDA 的中文界面补丁")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 12)

                if let app = appState.selectedApp {
                    NiceCard {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(app.localizationStatus.contains("已") ? "已安装汉化" : "未安装汉化")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text(app.localizationStatus.contains("已") ? "当前已应用中文翻译" : "尚未应用汉化补丁")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Circle()
                                    .fill(app.localizationStatus.contains("已") ? Color.green : Color.orange)
                                    .frame(width: 10, height: 10)
                            }

                            HStack(spacing: 12) {
                                if app.localizationStatus.contains("已") {
                                    Button {
                                        appState.uninstallLocalization()
                                    } label: {
                                        Label("卸载汉化", systemImage: "trash")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.red)
                                    .controlSize(.large)
                                } else {
                                    Button {
                                        appState.installLocalization()
                                    } label: {
                                        Label("安装汉化", systemImage: "arrow.down.circle.fill")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.large)
                                }
                            }
                            .disabled(appState.isProcessing)
                        }
                    }
                } else {
                    EmptyStateView(message: "请在上方选择一个 IDA 应用")
                }

                NiceCard {
                    LogView()
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 28)
        }
    }
}

struct TranslationTabView: View {
    @StateObject private var manager = TranslationManager()
    @State private var showAdd = false
    @State private var newOriginal = ""
    @State private var newTranslated = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                StatItem(title: "总条目", value: "\(manager.totalCount)")
                StatItem(title: "已翻译", value: "\(manager.translatedCount)")
                StatItem(title: "自定义", value: "\(manager.customCount)")

                Spacer()

                Button { showAdd = true } label: {
                    Label("添加翻译", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(nsColor: .controlBackgroundColor))

            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("搜索原文或译文...", text: $manager.searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .textBackgroundColor)))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)

            if manager.filteredTranslations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "text.book.closed")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text("没有匹配的翻译")
                        .font(.system(size: 15, weight: .medium))
                    Text(manager.searchText.isEmpty ? "点击右上角添加新词条" : "尝试其他关键词")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(manager.filteredTranslations, id: \.key) { item in
                            TranslationListRow(
                                original: item.key,
                                translated: item.value,
                                isCustom: manager.isCustomTranslation(item.key),
                                onEdit: {},
                                onDelete: { manager.deleteTranslation(original: item.key) }
                            )
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            VStack(spacing: 16) {
                Text("添加新翻译").font(.system(size: 17, weight: .semibold))
                TextEditor(text: $newOriginal).frame(height: 70)
                TextEditor(text: $newTranslated).frame(height: 70)
                HStack {
                    Button("取消") { showAdd = false }.buttonStyle(.bordered)
                    Button("保存") {
                        if manager.addTranslation(original: newOriginal, translated: newTranslated) {
                            showAdd = false
                            newOriginal = ""
                            newTranslated = ""
                        }
                    }.buttonStyle(.borderedProminent)
                        .disabled(newOriginal.isEmpty || newTranslated.isEmpty)
                }
            }
            .padding(24)
            .frame(width: 440)
        }
    }
}

struct ActivationTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                        Text("IDA 激活")
                            .font(.system(size: 26, weight: .semibold))
                    }
                    Text("生成许可证并激活 IDA Professional")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 12)

                if let app = appState.selectedApp {
                    NiceCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(app.activationStatus.contains("已") ? "已激活" : "未激活")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text(app.activationStatus.contains("已") ? "许可证已成功安装" : "请配置信息后进行激活")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Circle()
                                    .fill(app.activationStatus.contains("已") ? Color.green : Color.orange)
                                    .frame(width: 10, height: 10)
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                Text("许可证信息").font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary)
                                VStack(spacing: 10) {
                                    FormRow(label: "用户名", text: $appState.userName)
                                    FormRow(label: "邮箱", text: $appState.userEmail)
                                    FormRow(label: "到期时间", text: $appState.expiryDate)
                                }
                            }

                            Button {
                                appState.activate()
                            } label: {
                                Label("开始激活", systemImage: "key.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .disabled(appState.isProcessing)
                        }
                    }
                } else {
                    EmptyStateView(message: "请在上方选择一个 IDA 应用")
                }

                NiceCard {
                    LogView()
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 28)
        }
    }
}

struct AboutTabView: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle().fill(Color.accentColor.opacity(0.1)).frame(width: 90, height: 90)
                    Image(systemName: "hammer.circle.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                }

                VStack(spacing: 6) {
                    Text("IDA 汉化工具箱")
                        .font(.system(size: 26, weight: .semibold))
                    Text("v1.0  •  简约高效的 IDA 辅助工具")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }

            NiceCard {
                VStack(spacing: 18) {
                    LinkRow(title: "开发者", value: "@XcodeXK")
                    Divider().opacity(0.3)

                    // GitHub 部分 - 两个可点击链接
                    HStack(alignment: .top, spacing: 0) {
                        Text("GitHub")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .frame(width: 70, alignment: .leading)

                        VStack(alignment: .leading, spacing: 4) {
                            Link(destination: URL(string: "https://github.com/pxx917144686")!) {
                                Text("https://github.com/pxx917144686")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.accentColor)
                            }

                            Link(destination: URL(string: "https://github.com/Mac-XK")!) {
                                Text("https://github.com/Mac-XK")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: 380)

            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - 通用美化组件

struct NiceCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.secondary.opacity(0.08), lineWidth: 1)
            )
    }
}

struct StatItem: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 18, weight: .semibold))
            Text(title).font(.system(size: 11)).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
    }
}

struct TranslationListRow: View {
    let original: String
    let translated: String
    let isCustom: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(original).font(.system(size: 13, weight: .medium))
                Text(translated).font(.system(size: 13)).foregroundStyle(.secondary)
            }
            Spacer()
            if isCustom {
                Button(action: onDelete) {
                    Image(systemName: "trash").foregroundStyle(.red)
                }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 9)
    }
}

struct FormRow: View {
    let label: String
    @Binding var text: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)

            TextField("", text: $text)
                .textFieldStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(nsColor: .textBackgroundColor))
                )
        }
    }
}

struct EmptyStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "app.badge")
                .font(.system(size: 28))
                .foregroundStyle(.secondary.opacity(0.5))
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct LogView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "terminal")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Text("操作日志")
                    .font(.system(size: 13, weight: .medium))
            }

            ScrollView {
                Text(appState.logOutput.isEmpty ? "暂无操作记录..." : appState.logOutput)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
            .frame(height: 160)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .textBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

struct AppIconView: View {
    let appPath: String
    @State private var iconImage: NSImage?

    var body: some View {
        Group {
            if let image = iconImage {
                Image(nsImage: image).resizable().scaledToFit()
            } else {
                Image(systemName: "app.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear { loadIcon() }
        .onChange(of: appPath) { _ in loadIcon() }
    }

    private func loadIcon() {
        iconImage = NSWorkspace.shared.icon(forFile: appPath)
    }
}

struct LinkRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)

            if value.hasPrefix("http") {
                Link(destination: URL(string: value)!) {
                    Text(value).foregroundStyle(Color.accentColor)
                }
            } else {
                Text(value)
            }
        }
    }
}
