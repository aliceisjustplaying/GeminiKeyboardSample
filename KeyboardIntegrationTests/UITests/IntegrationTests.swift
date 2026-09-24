import XCTest
final class IntegrationTests: XCTestCase {
  func testSpaceAfterWordAndShortDrags() {
    let app = XCUIApplication()
    app.launch()
    XCTAssertTrue(app.keys["D"].waitForExistence(timeout: 10))
    app.keys["D"].tap()
    for letter in ["o", "i", "n", "g"] { app.keys[letter].tap() }
    let editor = app.textViews["keyboard-test-editor"]
    let space = app.keys["space"]
    space.tap()
    XCTAssertEqual(editor.value as? String, "Doing ")
    app.keys["a"].tap()
    let start = space.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    start.press(forDuration: 0.01, thenDragTo: start.withOffset(CGVector(dx: 12, dy: -8)), withVelocity: .fast, thenHoldForDuration: 0)
    XCTAssertEqual(editor.value as? String, "Doing a ")
    app.keys["b"].tap()
    space.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.12)).tap()
    XCTAssertEqual(editor.value as? String, "Doing a b ")
  }

  func testKeyboardTypingAndVoiceControls() {
    let app = XCUIApplication()
    app.launch()
    let lowercase = app.buttons["keyboard-lowercase-button"]
    XCTAssertTrue(lowercase.waitForExistence(timeout: 10))

    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = "KeyboardKit integration"
    attachment.lifetime = .keepAlways
    add(attachment)
    XCTAssertTrue(app.buttons["keyboard-dictate-button"].exists)
    XCTAssertTrue(app.buttons["keyboard-translate-button"].exists)
    app.buttons["Toggle recording preview"].tap()
    XCTAssertFalse(app.keys["Q"].exists)
    XCTAssertTrue(lowercase.isHittable)
    app.buttons["Toggle recording preview"].tap()
    XCTAssertTrue(app.keys["Q"].waitForExistence(timeout: 3))
    let oldValue = lowercase.value as? String

    lowercase.tap()
    XCTAssertNotEqual(lowercase.value as? String, oldValue)
    lowercase.tap()
    let q = app.keys["Q"].firstMatch
    XCTAssertTrue(q.exists)
    q.tap()
    app.keys["w"].firstMatch.tap()
    app.keys["e"].firstMatch.tap()
    XCTAssertEqual(app.textViews["keyboard-test-editor"].value as? String, "Qwe")
    app.keys["Keyboard Type - emojis"].tap()
    XCTAssertTrue(app.buttons["😀"].waitForExistence(timeout: 3))
    app.buttons["😀"].tap()
    app.buttons["Back to letters"].tap()
    XCTAssertTrue(lowercase.waitForExistence(timeout: 3))
    XCTAssertTrue(app.keys["q"].isHittable)
    XCTAssertEqual(app.textViews["keyboard-test-editor"].value as? String, "Qwe😀")
    if lowercase.value as? String != "On" { lowercase.tap() }
    app.buttons["Insert sample transcript"].tap()
    XCTAssertEqual(app.textViews["keyboard-test-editor"].value as? String, "Qwe😀 hello world")

  }
}
