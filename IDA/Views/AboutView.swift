import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Simple Logo
            VStack(spacing: 16) {
                Image(systemName: "hammer.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary.opacity(0.7))

                Text("IDA 汉化工具箱")
                    .font(.system(size: 26, weight: .semibold))
            }

            // Info Card
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    AboutRow(
                        icon: "person.fill",
                        title: "开发者",
                        subtitle: "@XcodeXK"
                    )

                    Divider()

                    AboutLinkRow(
                        icon: "link",
                        title: "GitHub",
                        urls: [
                            "https://github.com/pxx917144686",
                            "https://github.com/Mac-XK"
                        ]
                    )
                }
                .padding(20)
            }
            .frame(maxWidth: 420)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
            )

            Text("用于 IDA Pro 的汉化与激活辅助工具")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

struct AboutRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

struct AboutLinkRow: View {
    let icon: String
    let title: String
    let urls: [String]

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))

                ForEach(urls, id: \.self) { url in
                    Link(url, destination: URL(string: url)!)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.accentColor)
                }
            }

            Spacer()
        }
    }
}
