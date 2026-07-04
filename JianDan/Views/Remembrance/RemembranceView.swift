import SwiftUI
import SwiftData

/// 怀念 · 告别清单
///
/// 杂志感居中排版，图片作为卡片嵌入内容区而非通栏 hero，
/// 兼顾横竖图兼容与紧凑布局。
struct RemembranceView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(CurrencyManager.self) private var currencyManager

    @Query(sort: \FarewellRecord.farewellDate, order: .reverse) private var records: [FarewellRecord]

    @State private var record: FarewellRecord?
    @State private var showingEmptyAlert = false
    @State private var transitionEdge: Edge = .bottom
    @State private var imageAppeared = false
    @State private var revealedLetterCount = 0

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    emptyView
                } else if let record {
                    detailView(record)
                        .id(record.id)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .move(edge: transitionEdge)),
                            removal: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .move(edge: transitionEdge.opposite))
                        ))
                } else {
                    emptyView
                }
            }
            .background(theme.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        if records.isEmpty {
                            showingEmptyAlert = true
                        } else {
                            pickRandom()
                        }
                    }) {
                        Image(systemName: "shuffle")
                            .appFont(.caption)
                            .foregroundStyle(theme.accent)
                            .symbolEffect(.bounce, value: record?.id)
                    }
                }
            }
            .alert("还没有告别记录", isPresented: $showingEmptyAlert) {
                Button("好的", role: .cancel) { }
            } message: {
                Text("先去「告别清单」Tab 记下第一件物品吧")
            }
            .onAppear {
                if record == nil, !records.isEmpty { pickRandom() }
            }
            .onChange(of: records.count) { _, _ in
                if record == nil, !records.isEmpty { pickRandom() }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.3), value: record?.id)
            .sensoryFeedback(.impact(weight: .light), trigger: record?.id)
        }
    }

    private func pickRandom() {
        guard !records.isEmpty else { return }
        let newRecord = records.randomElement()!
        // 根据新旧记录在排序列表中的相对位置决定翻页方向
        if let current = record,
           let oldIdx = records.firstIndex(where: { $0.id == current.id }),
           let newIdx = records.firstIndex(where: { $0.id == newRecord.id }) {
            // records 按 farewellDate desc 排序；index 大 = 时间更早
            // 视觉上：翻到「更旧」从左滑入，翻到「更新」从右滑入
            transitionEdge = newIdx > oldIdx ? .leading : .trailing
        } else {
            transitionEdge = .bottom  // 首次进入
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.3)) {
            record = newRecord
        }
    }

    // MARK: - 详情

    private func detailView(_ item: FarewellRecord) -> some View {
        ScrollView {
            VStack(spacing: .lg) {
                // ---- 图片卡片（嵌入内容区） ----
                if let firstPhoto = item.photoFilenames.first,
                   let uiImage = ImageStore.loadImage(filename: firstPhoto) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 280)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                        .shadow(color: theme.needsShadow ? .black.opacity(0.06) : .clear, radius: 8, y: 2)
                        .scaleEffect(imageAppeared ? 1 : 1.02)
                        .animation(.easeOut(duration: 0.4), value: imageAppeared)
                        .padding(.horizontal, .md)
                        .padding(.top, .lg)
                        .task(id: item.id) {
                            imageAppeared = false
                            try? await Task.sleep(for: .milliseconds(30))
                            withAnimation(.easeOut(duration: 0.4)) {
                                imageAppeared = true
                            }
                        }
                }

                // ---- 名称 ----
                Text(item.name)
                    .appFont(.largeTitle)
                    .foregroundStyle(theme.primaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, .xl)
                    .padding(.top, .lg)

                // ---- 装饰分隔 ----
                Rectangle()
                    .fill(theme.divider)
                    .frame(width: 32, height: 0.5)

                // ---- 日期 + 陪伴天数 ----
                HStack(spacing: .xs) {
                    HStack(spacing: 4) {
                        if let purchase = item.purchaseDate {
                            Text(purchase, format: .dateTime.year().month().day())
                        } else {
                            Text("某天")
                        }
                        Text("~")
                        Text(item.farewellDate, format: .dateTime.year().month().day())
                    }
                    .appFont(.caption)
                    if let days = item.companionshipDays {
                        Text("·")
                        Text("陪伴我 \(days) 天")
                            .appFont(.caption)
                    }
                }
                .foregroundStyle(theme.secondary)

                // ---- 分类 · 方式 · 价格 ----
                HStack(spacing: .xs) {
                    pill(item.category.displayName, icon: item.category.iconName)
                    pill(item.method.localizedName, icon: item.method.icon)
                    if let price = item.purchasePrice, price > 0 {
                        pill(String(format: "%.2f", price), icon: currencyManager.currency.icon)
                    }
                }

                // ---- 去向详情 ----
                if let detail = item.recipientDetail, !detail.isEmpty {
                    Label(detail, systemImage: "arrow.right")
                        .appFont(.caption)
                        .foregroundStyle(theme.secondary)
                }

                // ---- 当时心情 ----
                if let emotion = item.emotionValue {
                    HStack(spacing: .xs) {
                        ForEach(1...3, id: \.self) { i in
                            Circle()
                                .fill(i <= emotion ? theme.accent : theme.divider)
                                .frame(width: 8, height: 8)
                        }
                        Text(emotionLabel(emotion))
                            .appFont(.caption)
                            .foregroundStyle(theme.secondary)
                            .padding(.leading, 4)
                    }
                }

                // ---- 告别留言（pull-quote） ----
                if let letter = item.farewellLetter, !letter.isEmpty {
                    VStack(spacing: .md) {
                        Rectangle()
                            .fill(theme.divider)
                            .frame(width: 24, height: 0.5)

                        revealedLetter("“\(letter)”")
                            .appFont(.body)
                            .italic()
                            .lineSpacing(8)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 300)
                            .fixedSize(horizontal: false, vertical: true)

                        Rectangle()
                            .fill(theme.divider)
                            .frame(width: 24, height: 0.5)
                    }
                    .task(id: item.id) {
                        revealedLetterCount = 0
                        let total = "“\(letter)”".count
                        guard total > 0 else { return }
                        for i in 0..<total {
                            try? await Task.sleep(for: .milliseconds(30))
                            revealedLetterCount = i + 1
                        }
                    }
                }

                // 底部留白
                Color.clear
                    .frame(height: .xs)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, .screenPadding)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - 辅助

    private func pill(_ text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .appFont(.caption)
            Text(text)
                .appFont(.caption)
        }
        .foregroundStyle(theme.secondary)
        .padding(.horizontal, .sm)
        .padding(.vertical, 5)
        .background(theme.cardBackground)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(theme.divider, lineWidth: 0.5)
        )
    }

    private func emotionLabel(_ value: Int) -> String {
        switch value {
        case 1: return String(localized: "平静")
        case 2: return String(localized: "复杂")
        case 3: return String(localized: "不舍")
        default: return ""
        }
    }

    /// 逐字构建金句文本：用 AttributedString 控制每个字符的 opacity，
    /// 实现类似 SplashQuoteView 的逐字揭示效果。
    private func revealedLetter(_ text: String) -> Text {
        var attr = AttributedString(text)
        for (index, _) in attr.characters.enumerated() {
            let start = attr.index(attr.startIndex, offsetByCharacters: index)
            let end = attr.index(afterCharacter: start)
            attr[start..<end].foregroundColor = index < revealedLetterCount
                ? theme.primaryText
                : theme.primaryText.opacity(0)
        }
        return Text(attr)
    }

    private var emptyView: some View {
        VStack(spacing: .md) {
            Spacer()
            Image(systemName: "heart")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(theme.secondary)
            Text("还没有告别记录")
                .appFont(.body)
                .foregroundStyle(theme.secondary)
            Text("在「告别清单」Tab 记下第一件物品，\n怀念就会出现在这里")
                .appFont(.caption)
                .foregroundStyle(theme.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    RemembranceView()
        .environment(\.appTheme, AppTheme(mode: .light))
        .environment(CurrencyManager())
        .modelContainer(for: FarewellRecord.self, inMemory: true)
}

private extension Edge {
    /// 用于 #11C 翻页方向感：返回对侧 edge，让 transition 的 insertion/removal 方向相反。
    var opposite: Edge {
        switch self {
        case .leading: return .trailing
        case .trailing: return .leading
        case .top: return .bottom
        case .bottom: return .top
        }
    }
}