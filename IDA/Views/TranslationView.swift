import SwiftUI

struct TranslationView: View {
    @StateObject private var manager = TranslationManager()
    @State private var showAddSheet = false
    @State private var newOriginal = ""
    @State private var newTranslated = ""
    @State private var showDeleteConfirm = false
    @State private var itemToDelete: String?
    @State private var showEditSheet = false
    @State private var editingOriginal = ""
    @State private var editingTranslated = ""

    var body: some View {
        VStack(spacing: 0) {
            // Top Stats + Action Bar
            HStack(spacing: 12) {
                CleanStatCard(title: "总条目", value: "\(manager.totalCount)", icon: "text.book.closed")
                CleanStatCard(title: "已翻译", value: "\(manager.translatedCount)", icon: "checkmark.circle")
                CleanStatCard(title: "自定义", value: "\(manager.customCount)", icon: "pencil")

                Spacer()

                Button {
                    showAddSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("添加翻译")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(nsColor: .controlBackgroundColor))

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("搜索原文或译文", text: $manager.searchText)
                    .textFieldStyle(.plain)

                if !manager.searchText.isEmpty {
                    Button {
                        manager.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .textBackgroundColor))
            )
            .padding(.horizontal, 24)
            .padding(.vertical, 12)

            // List
            Group {
                if manager.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if manager.filteredTranslations.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 28))
                            .foregroundStyle(.secondary.opacity(0.5))
                        Text("没有匹配的翻译")
                            .font(.system(size: 14, weight: .medium))
                        Text(manager.searchText.isEmpty ? "点击右上角添加新翻译条目" : "尝试其他搜索词")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(manager.filteredTranslations, id: \.key) { item in
                                CleanTranslationRow(
                                    original: item.key,
                                    translated: item.value,
                                    isCustom: manager.isCustomTranslation(item.key),
                                    onEdit: {
                                        editingOriginal = item.key
                                        editingTranslated = item.value
                                        showEditSheet = true
                                    },
                                    onDelete: {
                                        itemToDelete = item.key
                                        showDeleteConfirm = true
                                    }
                                )
                                Divider()
                                    .padding(.leading, 16)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $showAddSheet) {
            CleanTranslationSheet(
                title: "添加翻译",
                original: $newOriginal,
                translated: $newTranslated,
                onCancel: {
                    showAddSheet = false
                    newOriginal = ""
                    newTranslated = ""
                },
                onSave: {
                    if manager.addTranslation(original: newOriginal, translated: newTranslated) {
                        showAddSheet = false
                        newOriginal = ""
                        newTranslated = ""
                    }
                }
            )
        }
        .sheet(isPresented: $showEditSheet) {
            CleanTranslationSheet(
                title: "编辑翻译",
                original: $editingOriginal,
                translated: $editingTranslated,
                onCancel: {
                    showEditSheet = false
                },
                onSave: {
                    if manager.updateTranslation(original: editingOriginal, newTranslated: editingTranslated) {
                        showEditSheet = false
                    }
                },
                isEditing: true
            )
        }
        .alert("确认删除", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                if let key = itemToDelete {
                    manager.deleteTranslation(original: key)
                }
                itemToDelete = nil
            }
        } message: {
            if let key = itemToDelete {
                Text("确定要删除这个翻译条目吗？\n\n\(key)")
            }
        }
    }
}

// MARK: - Clean Components

struct CleanStatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .textBackgroundColor))
        )
    }
}

struct CleanTranslationRow: View {
    let original: String
    let translated: String
    let isCustom: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 14) {
            if isCustom {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.yellow)
            } else {
                Color.clear.frame(width: 14)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(original)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(translated)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if isHovered {
                HStack(spacing: 8) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)

                    if isCustom {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 13))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.red)
                    }
                }
                .padding(.trailing, 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 11)
        .background(isHovered ? Color.accentColor.opacity(0.04) : Color.clear)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onEdit()
        }
    }
}

struct CleanTranslationSheet: View {
    let title: String
    @Binding var original: String
    @Binding var translated: String
    let onCancel: () -> Void
    let onSave: () -> Void
    var isEditing: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(20)

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("原文（英文）")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)

                    TextEditor(text: $original)
                        .font(.system(size: 14))
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(nsColor: .textBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                        )
                        .frame(minHeight: 70)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("译文（中文）")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)

                    TextEditor(text: $translated)
                        .font(.system(size: 14))
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(nsColor: .textBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                        )
                        .frame(minHeight: 70)
                }

                HStack {
                    Spacer()

                    Button("取消", action: onCancel)
                        .buttonStyle(.bordered)

                    Button(isEditing ? "保存修改" : "添加") {
                        onSave()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(original.isEmpty || translated.isEmpty)
                }
                .padding(.top, 8)
            }
            .padding(20)
        }
        .frame(width: 480)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
