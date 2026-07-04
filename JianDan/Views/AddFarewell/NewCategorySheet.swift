import SwiftUI
import SwiftData

/// 新建自定义分类 sheet
///
/// - 名称：TextField，trim 后非空，长度 1...UserCategory.nameMaxLength
/// - 图标：24 个常用 SF Symbol 网格（避免 SF Symbol picker 过于发散）
/// - 保存：合法后插入 UserCategory 并 dismiss
struct NewCategorySheet: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var selectedIcon: String = NewCategorySheet.defaultIcons.first ?? "tag"

    /// 表单是否合法
    private var canSave: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= UserCategory.nameMaxLength
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("名称") {
                    TextField("如：数码配件", text: $name)
                        .submitLabel(.done)
                    Text("\(name.trimmingCharacters(in: .whitespacesAndNewlines).count) / \(UserCategory.nameMaxLength)")
                        .appFont(.caption)
                        .foregroundStyle(theme.secondary)
                }

                Section("图标") {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6),
                        spacing: 8
                    ) {
                        ForEach(NewCategorySheet.defaultIcons, id: \.self) { icon in
                            IconChoiceButton(
                                iconName: icon,
                                isSelected: icon == selectedIcon,
                                onTap: { selectedIcon = icon }
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("预览") {
                    HStack {
                        Image(systemName: selectedIcon)
                            .foregroundStyle(theme.primaryText)
                        Text(previewName)
                            .foregroundStyle(theme.primaryText)
                    }
                    .appFont(.body)
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("新分类")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save)
                        .disabled(!canSave)
                }
            }
        }
    }

    private var previewName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? String(localized: "未命名") : trimmed
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= UserCategory.nameMaxLength else { return }
        let new = UserCategory(name: trimmed, iconName: selectedIcon)
        modelContext.insert(new)
        try? modelContext.save()
        dismiss()
    }
}

/// 图标选择按钮
private struct IconChoiceButton: View {
    @Environment(\.appTheme) private var theme
    let iconName: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: iconName)
                .font(.title3)
                .frame(width: 44, height: 44)
                .background(
                    isSelected ? theme.accent.opacity(0.2) : Color(.systemGray6)
                )
                .foregroundStyle(isSelected ? theme.accent : theme.primaryText)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(isSelected ? theme.accent : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}

extension NewCategorySheet {
    /// 24 个常用 SF Symbol，覆盖断舍离场景
    static let defaultIcons: [String] = [
        "tag", "bag", "scissors", "heart", "star", "bolt",
        "leaf", "flame", "drop", "snowflake", "sun.max", "moon",
        "gift", "calendar", "bookmark", "pencil", "paintbrush", "wand.and.stars",
        "wrench.and.screwdriver", "key", "lock", "camera", "headphones", "printer"
    ]
}

#Preview {
    NewCategorySheet()
        .modelContainer(for: [UserCategory.self, FarewellRecord.self], inMemory: true)
}