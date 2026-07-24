import SwiftUI

struct ActivationView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("IDA Pro 激活")
                        .font(.system(size: 26, weight: .semibold))
                    Text("生成许可证文件并激活 IDA Professional")
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

                // Activation Config
                if appState.selectedApp != nil {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("许可证信息")
                            .font(.system(size: 14, weight: .semibold))

                        VStack(spacing: 14) {
                            CleanFormField(label: "用户名", value: $appState.userName, icon: "person.fill")
                            CleanFormField(label: "邮箱", value: $appState.userEmail, icon: "envelope.fill")
                            CleanFormField(label: "到期日期", value: $appState.expiryDate, icon: "calendar")
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

                    // Activate Button
                    Button {
                        appState.activate()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "key.fill")
                            Text("开始激活")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(appState.isProcessing || appState.selectedApp == nil)
                }

                // Log
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

struct CleanFormField: View {
    let label: String
    @Binding var value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            TextField("", text: $value)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .textBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                )
        }
    }
}
