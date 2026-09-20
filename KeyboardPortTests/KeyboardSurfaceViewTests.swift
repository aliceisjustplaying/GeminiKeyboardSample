import UIKit
import XCTest

@MainActor
final class KeyboardSurfaceViewTests: XCTestCase {
  func testOverlappingKeyHandlersSurviveCapitalizationChange() throws {
    let (surface, delegate) = makeSurface()
    surface.applyAutomaticCapitalization(.shifted)
    let first = try button("keyboard-key-Q", in: surface)
    let second = try button("keyboard-key-W", in: surface)
    XCTAssertFalse(first.isExclusiveTouch)
    XCTAssertFalse(second.isExclusiveTouch)
    // This suite is hostless: UIApplication does not dispatch sendActions.
    // Invoke the registered handlers in overlapping down/down/up/up order.
    func dispatch(_ key: KeyboardKeyButton, _ event: UIControl.Event) {
      for target in key.allTargets {
        for action in key.actions(forTarget: target, forControlEvent: event) ?? [] {
          _ = (target as? NSObject)?.perform(NSSelectorFromString(action), with: key)
        }
      }
    }
    dispatch(first, .touchDown)
    dispatch(second, .touchDown)
    dispatch(first, .touchUpInside)
    XCTAssertTrue(first === findButton("keyboard-key-q", in: surface))
    XCTAssertTrue(second === findButton("keyboard-key-w", in: surface))
    dispatch(second, .touchUpInside)
    XCTAssertEqual(delegate.insertedText, ["Q", "w"])
    surface.applyAutomaticCapitalization(.shifted)
    XCTAssertTrue(second === findButton("keyboard-key-W", in: surface))
  }

  func testRowGapRoutesToExpandedKeyHitRegion() throws {
    let (surface, _) = makeSurface()
    let q = try button("keyboard-key-q", in: surface)
    let frame = q.convert(q.bounds, to: surface)
    let point = CGPoint(x: frame.midX, y: frame.maxY + 4)
    XCTAssertTrue(surface.hitTest(point, with: nil) === q)
  }

  func testPortraitKeyFramesMatchAppleReference() throws {
    // IMG_3350: 1206px wide at 3x scale. Reference key frames in points.
    let surface = KeyboardSurfaceView(frame: CGRect(x: 0, y: 0, width: 402, height: 205))
    surface.overrideUserInterfaceStyle = .light
    surface.layoutIfNeeded()
    func frame(_ id: String) throws -> CGRect {
      let key = try button(id, in: surface)
      return key.convert(key.bounds, to: surface)
    }
    let q = try frame("keyboard-key-q")
    let a = try frame("keyboard-key-a")
    let z = try frame("keyboard-key-z")
    let space = try frame("keyboard-space-key")
    let enter = try frame("keyboard-return-key")
    XCTAssertEqual(q.minX, 7, accuracy: 0.5)
    XCTAssertEqual(q.width, 33.4, accuracy: 0.5)
    XCTAssertEqual(q.height, 43, accuracy: 0.5)
    XCTAssertEqual(a.minX, 26.7, accuracy: 0.5)
    XCTAssertEqual(a.width, q.width, accuracy: 0.5)
    XCTAssertEqual(a.minY, 54, accuracy: 0.5)
    XCTAssertEqual(z.minX, 66, accuracy: 0.5)
    XCTAssertEqual(z.width, q.width, accuracy: 0.5)
    XCTAssertEqual(space.minX, 105.5, accuracy: 1)
    XCTAssertEqual(enter.minX, 303, accuracy: 1)
    XCTAssertEqual(enter.maxX, 395, accuracy: 0.5)
    XCTAssertNil(findButton("keyboard-key-.", in: surface))
    let image = UIGraphicsImageRenderer(bounds: surface.bounds).image { context in
      UIColor(red: 0.89, green: 0.89, blue: 0.91, alpha: 1).setFill()
      context.fill(surface.bounds)
      surface.layer.render(in: context.cgContext)
    }
    let attachment = XCTAttachment(image: image)
    attachment.name = "Keyboard portrait reference check"
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  func testTypingConsumesSingleShiftAndUsesUppercaseText() throws {
    let (surface, delegate) = makeSurface()

    surface.activate(try button("keyboard-shift-key", in: surface).key.action)
    XCTAssertNotNil(findButton("keyboard-key-Q", in: surface))

    let q = try button("keyboard-key-Q", in: surface)
    surface.activate(q.key.action)

    XCTAssertEqual(delegate.insertedText, ["Q"])
    XCTAssertEqual(surface.interactionState.capitalization, .lowercase)
    XCTAssertNotNil(findButton("keyboard-key-q", in: surface))
  }

  func testSpaceAndDeleteDispatchExactlyOnceForATap() throws {
    let (surface, delegate) = makeSurface()

    surface.activate(try button("keyboard-space-key", in: surface).key.action)
    surface.activate(try button("keyboard-delete-key", in: surface).key.action)

    XCTAssertEqual(delegate.insertedText, [" "])
    XCTAssertEqual(delegate.deleteCount, 1)
  }

  func testPageKeysRenderNumbersThenSymbols() throws {
    let (surface, _) = makeSurface()

    surface.activate(try button("keyboard-page-key", in: surface).key.action)
    XCTAssertEqual(surface.interactionState.page, .numbers)
    XCTAssertNotNil(findButton("keyboard-key-1", in: surface))

    surface.activate(try button("keyboard-shift-key", in: surface).key.action)
    XCTAssertEqual(surface.interactionState.page, .symbols)
    XCTAssertNotNil(findButton("keyboard-key-[", in: surface))
  }

  func testContextChangesRebuildTheBottomRow() {
    let (surface, _) = makeSurface()

    surface.updateInputContext(
      kind: .email,
      returnKeyType: .send,
      needsInputModeSwitchKey: false
    )
    XCTAssertNotNil(findButton("keyboard-key-@", in: surface))
    XCTAssertNotNil(findButton("keyboard-space-key", in: surface))
    XCTAssertNil(findButton("keyboard-next-keyboard-key", in: surface))
    XCTAssertEqual(findButton("keyboard-return-key", in: surface)?.accessibilityLabel, "send")

    surface.updateInputContext(
      kind: .url,
      returnKeyType: .go,
      needsInputModeSwitchKey: true
    )
    XCTAssertNotNil(findButton("keyboard-key-.com", in: surface))
    XCTAssertNil(findButton("keyboard-space-key", in: surface))
    XCTAssertNotNil(findButton("keyboard-next-keyboard-key", in: surface))
  }

  func testRenderedPhoneLayoutHasNoAmbiguousSubviews() {
    let (surface, _) = makeSurface()
    surface.layoutIfNeeded()
    XCTAssertFalse(allSubviews(of: surface).contains(where: \.hasAmbiguousLayout))
  }

  func testRenderedPhoneLayoutFillsAvailableWidth() throws {
    let (surface, _) = makeSurface()
    surface.layoutIfNeeded()

    let q = try button("keyboard-key-q", in: surface)
    let p = try button("keyboard-key-p", in: surface)
    let qFrame = q.convert(q.bounds, to: surface)
    let pFrame = p.convert(p.bounds, to: surface)

    XCTAssertGreaterThan(qFrame.width, 25)
    XCTAssertLessThan(qFrame.minX, 10)
    XCTAssertGreaterThan(pFrame.maxX, 380)
  }

  func testWideLayoutKeepsTypingKeysAtAUsableSize() throws {
    let surface = KeyboardSurfaceView(frame: CGRect(x: 0, y: 0, width: 1_024, height: 260))
    surface.layoutIfNeeded()

    let q = try button("keyboard-key-q", in: surface)
    XCTAssertLessThan(q.bounds.width, 90)
    XCTAssertFalse(allSubviews(of: surface).contains(where: \.hasAmbiguousLayout))
  }

  func testTrailingAlternateCalloutStartsOnTheBaseCharacterAndStaysOnscreen() {
    let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 220))
    let key = UIView(frame: CGRect(x: 348, y: 90, width: 38, height: 44))
    let callout = KeyboardAlternateCalloutView()
    container.addSubview(key)

    let rightAnchoredOptions = ["ō", "õ", "ø", "œ", "ö", "ô", "ó", "ò", "o"]
    callout.show(
      options: rightAnchoredOptions,
      above: key,
      in: container,
      anchoredToTrailingEdge: true
    )

    XCTAssertEqual(callout.selectedText, "o")
    XCTAssertLessThanOrEqual(callout.frame.maxX, container.bounds.maxX - 4)
  }

  private func makeSurface() -> (KeyboardSurfaceView, DelegateSpy) {
    let surface = KeyboardSurfaceView(frame: CGRect(x: 0, y: 0, width: 390, height: 220))
    let delegate = DelegateSpy()
    surface.delegate = delegate
    surface.updateInputContext(
      kind: .standard,
      returnKeyType: .default,
      needsInputModeSwitchKey: true
    )
    surface.layoutIfNeeded()
    return (surface, delegate)
  }

  private func button(
    _ identifier: String,
    in surface: KeyboardSurfaceView,
    file: StaticString = #filePath,
    line: UInt = #line
  ) throws -> KeyboardKeyButton {
    try XCTUnwrap(findButton(identifier, in: surface), file: file, line: line)
  }

  private func findButton(
    _ identifier: String,
    in surface: KeyboardSurfaceView
  ) -> KeyboardKeyButton? {
    allSubviews(of: surface)
      .compactMap { $0 as? KeyboardKeyButton }
      .first { $0.accessibilityIdentifier == identifier }
  }

  private func allSubviews(of view: UIView) -> [UIView] {
    view.subviews + view.subviews.flatMap(allSubviews)
  }
}

@MainActor
private final class DelegateSpy: KeyboardSurfaceViewDelegate {
  var insertedText: [String] = []
  var deleteCount = 0
  var cursorOffsets: [Int] = []
  var clickCount = 0

  func keyboardSurface(_ surface: KeyboardSurfaceView, insertText text: String) {
    insertedText.append(text)
  }

  func keyboardSurfaceDeleteBackward(_ surface: KeyboardSurfaceView) {
    deleteCount += 1
  }

  func keyboardSurface(_ surface: KeyboardSurfaceView, adjustTextPositionBy offset: Int) {
    cursorOffsets.append(offset)
  }

  func keyboardSurfacePlayInputClick(_ surface: KeyboardSurfaceView) {
    clickCount += 1
  }

  func keyboardSurface(
    _ surface: KeyboardSurfaceView,
    showInputModeListFrom button: UIButton,
    event: UIEvent
  ) {}
}
