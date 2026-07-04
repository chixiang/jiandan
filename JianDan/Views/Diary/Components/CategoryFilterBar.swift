import SwiftUI
import SwiftData

private let rowHeight: CGFloat = 38

struct CategoryFilterBar: View {
    @Binding var selectedCategoryIDs: Set<String>
    @Binding var selectedMethods: Set<String>
    @Binding var selectedEmotions: Set<Int>
    @Binding var isExpanded: Bool
    @Environment(\.appTheme) private var theme

    @Query(sort: \UserCategory.sortOrder, order: .forward) private var customCategories: [UserCategory]

    var body: some View {
        VStack(spacing: 0) {
            categoryRow

            if isExpanded {
                methodRow
                    .transition(.opacity)

                emotionRow
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }

    // MARK: - 分类

    private var categoryRow: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    FilterChip(
                        label: String(localized: "全部"),
                        isSelected: selectedCategoryIDs.isEmpty,
                        onTap: { selectedCategoryIDs = [] }
                    )

                    ForEach(Category.allCases) { category in
                        FilterChip(
                            label: category.localizedName,
                            iconName: category.icon,
                            isSelected: selectedCategoryIDs.contains(category.rawValue),
                            onTap: { toggleCategory(category.rawValue) }
                        )
                    }

                    if !customCategories.isEmpty {
                        Divider()
                            .frame(height: 16)
                            .background(theme.divider)
                            .padding(.horizontal, 4)

                        ForEach(customCategories, id: \.id) { custom in
                            let sid = AnyCategory.from(userCategory: custom).storageID
                            FilterChip(
                                label: custom.name,
                                iconName: custom.iconName,
                                isSelected: selectedCategoryIDs.contains(sid),
                                onTap: { toggleCategory(sid) }
                            )
                        }
                    }
                }
                .padding(.leading, 16)
                .padding(.trailing, 8)
            }
            .padding(.trailing, 6)

            expandToggle
                .padding(.trailing, 10)
        }
        .frame(height: rowHeight)
    }

    private var expandToggle: some View {
        Button {
            withAnimation { isExpanded.toggle() }
        } label: {
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(AppTypography.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(theme.divider.opacity(0.3))
                .foregroundStyle(theme.secondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 去向

    private var methodRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                FilterChip(
                    label: String(localized: "全部"),
                    isSelected: selectedMethods.isEmpty,
                    onTap: { selectedMethods = [] }
                )

                ForEach(FarewellMethod.allCases) { method in
                    FilterChip(
                        label: method.localizedName,
                        iconName: method.icon,
                        isSelected: selectedMethods.contains(method.rawValue),
                        onTap: { toggleMethod(method.rawValue) }
                    )
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
        }
        .frame(height: rowHeight)
    }

    // MARK: - 心情

    private var emotionRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                FilterChip(
                    label: String(localized: "全部"),
                    isSelected: selectedEmotions.isEmpty,
                    onTap: { selectedEmotions = [] }
                )

                emotionChip(value: 1, label: String(localized: "平静"))
                emotionChip(value: 2, label: String(localized: "复杂"))
                emotionChip(value: 3, label: String(localized: "不舍"))
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
        }
        .frame(height: rowHeight)
    }

    private func emotionChip(value: Int, label: String) -> some View {
        FilterChip(
            label: label,
            isSelected: selectedEmotions.contains(value),
            onTap: { toggleEmotion(value) }
        )
    }

    // MARK: - Toggle

    private func toggleCategory(_ id: String) {
        if selectedCategoryIDs.contains(id) {
            selectedCategoryIDs.remove(id)
        } else {
            selectedCategoryIDs.insert(id)
        }
    }

    private func toggleMethod(_ method: String) {
        if selectedMethods.contains(method) {
            selectedMethods.remove(method)
        } else {
            selectedMethods.insert(method)
        }
    }

    private func toggleEmotion(_ value: Int) {
        if selectedEmotions.contains(value) {
            selectedEmotions.remove(value)
        } else {
            selectedEmotions.insert(value)
        }
    }
}

// MARK: - FilterChip

private struct FilterChip: View {
    @Environment(\.appTheme) private var theme
    let label: String
    var iconName: String? = nil
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                if let icon = iconName {
                    Image(systemName: icon)
                }
                Text(label)
                    .lineLimit(1)
            }
            .font(AppTypography.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? theme.accent : theme.divider.opacity(0.3))
            .foregroundStyle(isSelected ? .white : theme.primaryText)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var ids: Set<String> = ["衣物"]
    @Previewable @State var meths: Set<String> = []
    @Previewable @State var emos: Set<Int> = []
    @Previewable @State var expanded = false
    CategoryFilterBar(
        selectedCategoryIDs: $ids,
        selectedMethods: $meths,
        selectedEmotions: $emos,
        isExpanded: $expanded
    )
    .padding()
    .appTheme(.light)
}