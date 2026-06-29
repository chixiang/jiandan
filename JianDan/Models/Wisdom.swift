import Foundation

/// 一条古典极简金句（Phase 1 内置静态内容，Phase 2 可改远端）
///
/// 设计为值类型 + Codable，未来从 JSON 加载时无需改 model 定义。
/// 不是 `@Model`：纯只读内容，不进 SwiftData。
struct Wisdom: Identifiable, Hashable, Codable {
    /// 唯一 ID（便于 Phase 2 远端增量同步）
    let id: String
    /// 金句正文（中文）
    let text: String
    /// 出处 / 作者（中文）
    let attribution: String
    /// 可选分类标签
    let category: String?
    /// 英文正文
    let textEn: String?
    /// 英文出处
    let attributionEn: String?
    /// 日文正文
    let textJa: String?
    /// 日文出处
    let attributionJa: String?

    init(id: String, text: String, attribution: String, category: String? = nil,
         textEn: String? = nil, attributionEn: String? = nil,
         textJa: String? = nil, attributionJa: String? = nil) {
        precondition(!text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Wisdom text cannot be empty")
        precondition(text.count <= Self.textMaxLength, "Wisdom text too long (max \(Self.textMaxLength))")
        precondition(!attribution.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Wisdom attribution cannot be empty")
        precondition(attribution.count <= Self.attributionMaxLength, "Wisdom attribution too long (max \(Self.attributionMaxLength))")

        self.id = id
        self.text = text
        self.attribution = attribution
        self.category = category
        self.textEn = textEn
        self.attributionEn = attributionEn
        self.textJa = textJa
        self.attributionJa = attributionJa
    }

    static let textMaxLength = 200
    static let attributionMaxLength = 80

    /// 根据当前语言返回对应正文
    func localizedText(for language: AppLanguage) -> String {
        let lang = language.resolvedForCurrentSystem
        switch lang {
        case .zhHans: return text
        case .en: return textEn ?? text
        case .ja: return textJa ?? text
        case .system: return text
        }
    }

    /// 根据当前语言返回对应出处
    func localizedAttribution(for language: AppLanguage) -> String {
        let lang = language.resolvedForCurrentSystem
        switch lang {
        case .zhHans: return attribution
        case .en: return attributionEn ?? attribution
        case .ja: return attributionJa ?? attribution
        case .system: return attribution
        }
    }
}

/// 内置金句库（Phase 1 静态；Phase 2 可改为远端拉取 + 本地缓存）
enum WisdomLibrary {
    static let all: [Wisdom] = [
        Wisdom(
            id: "wang-wei-1",
            text: "行到水穷处，坐看云起时。",
            attribution: "王维·《终南别业》",
            category: "处世"
        ),
        Wisdom(
            id: "laozi-1",
            text: "少则得，多则惑。",
            attribution: "老子·《道德经》",
            category: "治学"
        ),
        Wisdom(
            id: "zhuangzi-1",
            text: "物与我皆无尽也，而又何羡乎？",
            attribution: "苏轼·《前赤壁赋》（引庄子意）",
            category: "心境"
        ),
        Wisdom(
            id: "zhongyong-1",
            text: "素富贵，行乎富贵；素患难，行乎患难。",
            attribution: "《中庸》",
            category: "处世"
        ),
        Wisdom(
            id: "mencius-1",
            text: "万物皆备于我矣。反身而诚，乐莫大焉。",
            attribution: "孟子·《尽心上》",
            category: "心境"
        ),
        Wisdom(
            id: "hanfeizi-1",
            text: "去甚，去奢，去泰。",
            attribution: "韩非子·《解老》",
            category: "治事"
        ),
        Wisdom(
            id: "sushi-1",
            text: "此心安处是吾乡。",
            attribution: "苏轼·《定风波》",
            category: "心境"
        ),
        Wisdom(
            id: "zhuanzi-2",
            text: "朴素而天下莫能与之争美。",
            attribution: "庄子·《天道》",
            category: "美学"
        ),
        Wisdom(
            id: "fajia-1",
            text: "俭节则昌，淫佚则亡。",
            attribution: "墨子·《辞过》",
            category: "治事"
        ),
        Wisdom(
            id: "weizheng-1",
            text: "不矜细行，终累大德。",
            attribution: "《尚书·旅獒》",
            category: "修身"
        ),
    ]
}