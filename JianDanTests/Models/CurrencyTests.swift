import XCTest
@testable import JianDan

/// `Currency` 模型测试
@MainActor
final class CurrencyTests: XCTestCase {

    // MARK: - 枚举完整性

    func testAllCasesCount() {
        XCTAssertEqual(Currency.allCases.count, 5)
    }

    func testRawValuesAreISO4217Codes() {
        let expected: Set<String> = ["CNY", "USD", "EUR", "JPY", "GBP"]
        let actual = Set(Currency.allCases.map(\.rawValue))
        XCTAssertEqual(actual, expected)
    }

    // MARK: - 显示名

    func testDisplayNamesAreLocalizedChinese() {
        XCTAssertEqual(Currency.cny.displayName, "人民币")
        XCTAssertEqual(Currency.usd.displayName, "美元")
        XCTAssertEqual(Currency.eur.displayName, "欧元")
        XCTAssertEqual(Currency.jpy.displayName, "日元")
        XCTAssertEqual(Currency.gbp.displayName, "英镑")
    }

    // MARK: - 符号

    func testSymbols() {
        XCTAssertEqual(Currency.cny.symbol, "¥")
        XCTAssertEqual(Currency.usd.symbol, "$")
        XCTAssertEqual(Currency.eur.symbol, "€")
        XCTAssertEqual(Currency.jpy.symbol, "¥")
        XCTAssertEqual(Currency.gbp.symbol, "£")
    }

    func testCNYAndJPYShareSymbol() {
        // SF Symbols 未提供 ¥ 的区分图标，文档化这一约束
        XCTAssertEqual(Currency.cny.symbol, Currency.jpy.symbol)
    }

    // MARK: - SF Symbol 图标

    func testIconsAreSFSymbols() {
        for currency in Currency.allCases {
            XCTAssertFalse(currency.icon.isEmpty, "\(currency) icon should not be empty")
            XCTAssertFalse(currency.iconCircle.isEmpty, "\(currency) iconCircle should not be empty")
            XCTAssertTrue(currency.iconCircle.hasSuffix(".circle"),
                          "\(currency) iconCircle should end with .circle")
        }
    }

    func testCNYAndJPYShareIcon() {
        XCTAssertEqual(Currency.cny.icon, Currency.jpy.icon)
    }

    // MARK: - Identifiable

    func testIdMatchesRawValue() {
        for currency in Currency.allCases {
            XCTAssertEqual(currency.id, currency.rawValue)
        }
    }

    // MARK: - Codable

    func testCodableRoundTrip() throws {
        for currency in Currency.allCases {
            let encoded = try JSONEncoder().encode(currency)
            let decoded = try JSONDecoder().decode(Currency.self, from: encoded)
            XCTAssertEqual(decoded, currency)
        }
    }
}

/// `CurrencyManager` 持久化测试
@MainActor
final class CurrencyManagerTests: XCTestCase {

    private let key = "app.currency"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: key)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: key)
        super.tearDown()
    }

    // MARK: - 默认态

    func testDefaultCurrencyIsCNYWhenUserDefaultsEmpty() {
        UserDefaults.standard.removeObject(forKey: key)
        let manager = CurrencyManager()
        XCTAssertEqual(manager.currency, .cny)
    }

    func testCorruptedUserDefaultsValueFallsBackToCNY() {
        UserDefaults.standard.set("not-a-valid-currency", forKey: key)
        let manager = CurrencyManager()
        XCTAssertEqual(manager.currency, .cny)
    }

    // MARK: - didSet 写入

    func testDidSetWritesImmediately() {
        let manager = CurrencyManager()
        manager.currency = .usd
        XCTAssertEqual(UserDefaults.standard.string(forKey: key), "USD")
    }

    func testDidSetWritesAllCurrencies() {
        for currency in Currency.allCases {
            let manager = CurrencyManager()
            manager.currency = currency
            XCTAssertEqual(UserDefaults.standard.string(forKey: key), currency.rawValue)
        }
    }

    // MARK: - 持久化

    func testPersistsAcrossInstances() {
        let writer = CurrencyManager()
        writer.currency = .eur

        let reader = CurrencyManager()
        XCTAssertEqual(reader.currency, .eur)
    }

    func testAllCurrenciesRoundTripViaUserDefaults() {
        for currency in Currency.allCases {
            UserDefaults.standard.set(currency.rawValue, forKey: key)
            let manager = CurrencyManager()
            XCTAssertEqual(manager.currency, currency, "Currency \(currency.rawValue) should round-trip")
        }
    }

    // MARK: - 修改不影响其他状态

    func testCurrencyChangeIsObservableViaNewInstance() {
        let first = CurrencyManager()
        first.currency = .gbp

        let second = CurrencyManager()
        XCTAssertEqual(second.currency, .gbp)
    }
}