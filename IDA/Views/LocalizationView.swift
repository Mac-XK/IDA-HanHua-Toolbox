import SwiftUI

struct LocalizationView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("汉化管理")
                        .font(.system(size: 26, weight: .semibold))
                    Text("为 IDA Professional 安装或移除中文界面补丁")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 24)

                // Selected App
                if let selectedApp = appState.selectedApp {
                    CleanAppCard(app: selectedApp)
                } else {
                    CleanEmptyCard()
                }

                // Action Buttons
                if let app = appState.selectedApp {
                    HStack(spacing: 12) {
                        if app.localizationStatus.contains("已") {
                            Button {
                                appState.uninstallLocalization()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "trash")
                                    Text("卸载汉化")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            .controlSize(.large)
                            .disabled(appState.isProcessing)
                        } else {
                            Button {
                                appState.installLocalization()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.down.circle.fill")
                                    Text("安装汉化")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .disabled(appState.isProcessing)
                        }
                    }
                }

                // Log Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "terminal")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text("操作日志")
                            .font(.system(size: 13, weight: .semibold))
                    }

                    ScrollView {
                        Text(appState.logOutput.isEmpty ? "等待操作..." : appState.logOutput)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                    }
                    .frame(height: 180)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(nsColor: .textBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                    )
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

struct CleanAppCard: View {
    let app: IDAAppModel
    @State private var iconImage: NSImage?

    var body: some View {
        HStack(spacing: 16) {
            // App Icon
            Group {
                if let image = iconImage {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .cornerRadius(8)
                } else {
                    Image(systemName: "app.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                }
            }
            .onAppear { loadIcon() }
            .onChange(of: app.path) { _ in loadIcon() }

            VStack(alignment: .leading, spacing: 5) {
                Text(app.displayName)
                    .font(.system(size: 17, weight: .semibold))

                Text(app.path)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack(spacing: 8) {
                    StatusBadgeClean(text: app.localizationStatus, isActive: app.localizationStatus.contains("已"))
                    StatusBadgeClean(text: app.activationStatus, isActive: app.activationStatus.contains("已"))
                }
            }

            Spacer()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
        )
    }

    private func loadIcon() {
        iconImage = NSWorkspace.shared.icon(forFile: app.path)
    }
}

struct CleanEmptyCard: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "app.badge")
                .font(.system(size: 32))
                .foregroundStyle(.secondary.opacity(0.6))

            Text("未选择 IDA 应用")
                .font(.system(size: 15, weight: .medium))

            Text("请从左侧列表选择一个 IDA Professional 应用")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
        )
    }
}

struct StatusBadgeClean: View {
    let text: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isActive ? Color.green : Color.secondary)
                .frame(width: 5, height: 5)
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
