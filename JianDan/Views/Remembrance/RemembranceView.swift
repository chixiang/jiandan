import SwiftUI
import SwiftData

/// 怀念 · 减单
///
/// 随机展示一件已告别物品的详情，风格简洁高级。
/// 每次进入或点击 shuffle 按钮随机抽取一件。
struct RemembranceView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \FarewellRecord.farewellDate, order: .reverse) private var records: [FarewellRecord]

    @State private var record: FarewellRecord?

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    emptyView
                } else if let record {
                    detailScroll(record)
                } else {
                    emptyView
                }
            }
            .background(theme.background)
            .navigationTitle("怀念")
            .toolbar {
                if !records.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: pickRandom) {
                            Image(systemName: "shuffle")
                                .foregroundStyle(theme.accent)
                        }
                    }
                }
            }
            .onAppear {
                if record == nil, !records.isEmpty {
                    pickRandom()
                }
            }
            .onChange(of: records.count) { _, _ in
                if record == nil, !records.isEmpty {
                    pickRandom()
                }
            }
        }
    }

    // MARK: - 随机抽取

    private func pickRandom() {
        guard !records.isEmpty else { return }
        record = records.randomElement()
    }

    // MARK: - 详情

    private func detailScroll(_ item: FarewellRecord) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // 照片（hero）
                if let firstPhoto = item.photoFilenames.first,
                   let uiImage = ImageStore.loadImage(filename: firstPhoto) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 280)
                        .clipped()
                        .overlay(alignment: .bottom) {
                            LinearGradient(
                                colors: [.clear, theme.background],
                                startPoint: .top, endPoint: .bottom
                            )
                            .frame(height: 80)
                        }
                }

                VStack(alignment: .leading, spacing: 24) {
                    // 名称
                    Text(item.name)
                        .font(.system(size: 28, weight: .regular, design: .serif))
                        .foregroundStyle(theme.primaryText)
                        .padding(.top, item.photoFilenames.isEmpty ? 8 : 0)

                    // 日期与陪伴
                    HStack(spacing: 16) {
                        Label(
                            item.farewellDate.formatted(.dateTime.year().month().day()),
                            systemImage: "calendar"
                        )
                        if let days = item.companionshipDays {
                            Text("陪伴了 \(days) 天")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(theme.secondary)

                    // 分类 + 方式（浅色 chip）
                    HStack(spacing: 8) {
                        pill(item.category.displayName, icon: item.category.iconName)
                        pill(item.method.rawValue, icon: item.method.icon)
                        Spacer(minLength: 0)
                    }

                    // 购入信息（如果有）
                    if let price = item.purchasePrice, price > 0 {
                        infoRow(icon: "yensign", text: "¥\(String(format: "%.0f", price))")
                    }
                    if let detail = item.recipientDetail, !detail.isEmpty {
                        infoRow(icon: "arrow.right", text: detail)
                    }

                    // 减单一言
                    if let letter = item.farewellLetter, !letter.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Divider()
                                .overlay(theme.divider)

                            Text(letter)
                                .font(.system(size: 17, design: .serif))
                                .italic()
                                .foregroundStyle(theme.primaryText)
                                .lineSpacing(8)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Divider()
                                .overlay(theme.divider)
                        }
                    }

                    // 当时心情
                    if let emotion = item.emotionValue {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("当时心情")
                                .font(AppTypography.caption)
                                .foregroundStyle(theme.secondary)
                            HStack(spacing: 8) {
                                ForEach(1...5, id: \.self) { i in
                                    Circle()
                                        .fill(i <= emotion ? theme.accent : theme.divider)
                                        .frame(width: 10, height: 10)
                                }
                                Text(emotionLabel(emotion))
                                    .font(.subheadline)
                                    .foregroundStyle(theme.primaryText)
                                    .padding(.leading, 4)
                            }
                        }
                    }

                    // 底部分隔
                    Spacer(minLength: 60)

                    // shuffle 按钮
                    HStack {
                        Spacer()
                        Button(action: pickRandom) {
                            HStack(spacing: 8) {
                                Image(systemName: "shuffle")
                                Text("换一件")
                            }
                            .font(.subheadline)
                            .foregroundStyle(theme.accent)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(theme.cardBackground)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(theme.divider, lineWidth: 0.5)
                            )
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, item.photoFilenames.isEmpty ? 0 : -8)
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - 辅助

    private func pill(_ text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption)
        .foregroundStyle(theme.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(theme.cardBackground)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(theme.divider, lineWidth: 0.5)
        )
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(theme.secondary)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(theme.primaryText)
        }
    }

    private func emotionLabel(_ value: Int) -> String {
        switch value {
        case 1: return "轻松"
        case 2: return "释然"
        case 3: return "平静"
        case 4: return "复杂"
        case 5: return "不舍"
        default: return ""
        }
    }

    // MARK: - 空态

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(theme.secondary)
            Text("还没有告别记录")
                .font(AppTypography.body)
                .foregroundStyle(theme.secondary)
            Text("在「减单」Tab 记下第一件物品，\\n怀念就会出现在这里")
                .font(AppTypography.caption)
                .foregroundStyle(theme.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxHeight: .infinity)
    }
}

#Preview {
    RemembranceView()
        .environment(\.appTheme, AppTheme(mode: .light))
        .modelContainer(for: FarewellRecord.self, inMemory: true)
}