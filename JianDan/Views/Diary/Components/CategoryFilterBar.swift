import SwiftUI
import SwiftData

struct CategoryFilterBar: View {
    @Binding var selectedStorageIDs: Set<String>
    @Environment(\.appTheme) private var theme

    @Query(sort: \UserCategory.sortOrder, order: .forward) private var customCategories: [UserCategory]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                FilterChip(
                    label: "全部",
                    isSelected: selectedStorageIDs.isEmpty,
                    onTap: { selectedStorageIDs = [] }
                )

                ForEach(Category.allCases) { category in
                    FilterChip(
                        label: category.rawValue,
                        iconName: category.icon,
                        isSelected: selectedStorageIDs.contains(category.rawValue),
                        onTap: { toggle(category.rawValue) }
                    )
                }

                if !customCategories.isEmpty {
                    Divider()
                        .frame(height: 16)
                        .padding(.horizontal, 4)

                    ForEach(customCategories, id: \.id) { custom in
                        let sid = AnyCategory.from(userCategory: custom).storageID
                        FilterChip(
                            label: custom.name,
                            iconName: custom.iconName,
                            isSelected: selectedStorageIDs.contains(sid),
                            onTap: { toggle(sid) }
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private func toggle(_ storageID: String) {
        if selectedStorageIDs.contains(storageID) {
            selectedStorageIDs.remove(storageID)
        } else {
            selectedStorageIDs.insert(storageID)
        }
    }
}

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
            .font(.caption)
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
    CategoryFilterBar(selectedStorageIDs: $ids)
        .padding()
        .appTheme(.light)
}
