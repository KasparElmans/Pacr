import XCTest
@testable import Located

final class LocatedTests: XCTestCase {
    func testFormatPaceRendersMinutesAndSeconds() {
        XCTAssertEqual(formatPace(minPerKm: 4.75), "04:45 /km")
    }

    func testFormatPaceFallbackForNil() {
        XCTAssertEqual(formatPace(minPerKm: nil), "--:-- /km")
    }
}
