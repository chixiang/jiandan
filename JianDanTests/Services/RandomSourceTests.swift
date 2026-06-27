import XCTest
@testable import JianDan

/// `RandomSource` 协议的两个实现测试
///
/// `SystemRandomSource` 直接用系统随机源；`StubRandomSource` 用于测试注入。
final class RandomSourceTests: XCTestCase {

    // MARK: - SystemRandomSource

    func testSystemRandomSourceRespectsRange() {
        var source = SystemRandomSource()
        let upper = 5
        for _ in 0..<200 {
            let v = source.nextInt(upperBound: upper)
            XCTAssertGreaterThanOrEqual(v, 0)
            XCTAssertLessThan(v, upper)
        }
    }

    func testSystemRandomSourceUpperBound1() {
        var source = SystemRandomSource()
        for _ in 0..<50 {
            XCTAssertEqual(source.nextInt(upperBound: 1), 0)
        }
    }

    func testSystemRandomSourceUpperBound0() {
        // 文档约定：upperBound == 0 返回 0
        var source = SystemRandomSource()
        XCTAssertEqual(source.nextInt(upperBound: 0), 0)
    }

    func testSystemRandomSourceVariety() {
        // 100 次随机抽 10 个 slot，至少出现 2 种不同值
        var source = SystemRandomSource()
        var seen = Set<Int>()
        for _ in 0..<100 {
            seen.insert(source.nextInt(upperBound: 10))
        }
        XCTAssertGreaterThanOrEqual(seen.count, 2)
    }

    // MARK: - StubRandomSource

    func testStubRandomSourceReturnsSequenceInOrder() {
        var stub = StubRandomSource(sequence: [0, 5, 9])
        XCTAssertEqual(stub.nextInt(upperBound: 10), 0)
        XCTAssertEqual(stub.nextInt(upperBound: 10), 5)
        XCTAssertEqual(stub.nextInt(upperBound: 10), 9)
    }

    func testStubRandomSourceFallsBackAfterSequence() {
        var stub = StubRandomSource(sequence: [3], fallback: 7)
        _ = stub.nextInt(upperBound: 10)  // 消耗 3
        // 序列耗尽，回退到 fallback
        XCTAssertEqual(stub.nextInt(upperBound: 10), 7)
        XCTAssertEqual(stub.nextInt(upperBound: 10), 7)
    }

    func testStubRandomSourceEmptySequenceUsesFallback() {
        var stub = StubRandomSource(sequence: [], fallback: 4)
        XCTAssertEqual(stub.nextInt(upperBound: 10), 4)
    }

    func testStubRandomSourceHandlesNegative() {
        // 负数应被 modulo 处理为非负数
        var stub = StubRandomSource(sequence: [-1, -11], fallback: 0)
        let v1 = stub.nextInt(upperBound: 10)
        let v2 = stub.nextInt(upperBound: 10)
        XCTAssertGreaterThanOrEqual(v1, 0)
        XCTAssertGreaterThanOrEqual(v2, 0)
        XCTAssertLessThan(v1, 10)
        XCTAssertLessThan(v2, 10)
    }

    func testStubRandomSourceModuloApplies() {
        // 序列里的值会被 mod upperBound
        var stub = StubRandomSource(sequence: [15, 23])
        XCTAssertEqual(stub.nextInt(upperBound: 10), 5)  // 15 % 10
        XCTAssertEqual(stub.nextInt(upperBound: 10), 3)  // 23 % 10
    }

    func testStubRandomSourceUpperBound0() {
        var stub = StubRandomSource(sequence: [42], fallback: 0)
        XCTAssertEqual(stub.nextInt(upperBound: 0), 0)
    }
}