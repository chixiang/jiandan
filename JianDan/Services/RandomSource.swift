import Foundation

/// 随机源抽象：用于「冷启动随机选短文」等场景
///
/// 设计动机：
/// - 默认实现 `SystemRandomSource` 使用 `SystemRandomNumberGenerator`，生产环境使用
/// - 测试时可注入 `StubRandomSource` 预置序列，确定性断言
///
/// 协议边界：
/// - 只暴露 `nextInt(upperBound:)`，不暴露原始 UInt64，避免误用
/// - 上限参数必须 > 0；调用方保证（如 `QuoteRepository.randomQuote` 内部已 guard）
/// - 标记 `mutating` 以允许 stub 实现修改内部状态
protocol RandomSource {
    mutating func nextInt(upperBound: Int) -> Int
}

/// 默认实现：使用系统级加密安全随机源
struct SystemRandomSource: RandomSource {
    func nextInt(upperBound: Int) -> Int {
        // upperBound == 0 的防御：理论上调用方已保证，但万一传入 0 也安全
        guard upperBound > 0 else { return 0 }
        var generator = SystemRandomNumberGenerator()
        return Int.random(in: 0..<upperBound, using: &generator)
    }
}

/// 测试用 stub：按预置数组依次返回，耗尽后回退到 0
struct StubRandomSource: RandomSource {
    private var sequence: [Int]
    private var fallback: Int = 0

    init(sequence: [Int], fallback: Int = 0) {
        self.sequence = sequence
        self.fallback = fallback
    }

    mutating func nextInt(upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        guard !sequence.isEmpty else { return fallback % upperBound }
        let value = sequence.removeFirst()
        return ((value % upperBound) + upperBound) % upperBound  // 处理负数
    }
}
