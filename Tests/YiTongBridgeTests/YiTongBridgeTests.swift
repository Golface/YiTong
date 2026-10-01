import XCTest
@testable import YiTongBridge

final class YiTongBridgeTests: XCTestCase {
  func testProtocolVersionIsOne() {
    XCTAssertEqual(YiTongBridgeSchema.protocolVersion, 1)
  }

  func testBridgeCodecRoundTripsStubMessage() throws {
    let message = YiTongBridgeMessage(id: "msg-1", type: "initialize")
    let data = try YiTongBridgeCodec.encode(message)
    let decoded = try YiTongBridgeCodec.decode(YiTongBridgeMessage.self, from: data)

    XCTAssertEqual(decoded, message)
  }

  func testInitializeEnvelopeRoundTrips() throws {
    let payload = YiTongInitializePayload(
      rendererVersion: "1.0.11+yitong.1",
      platform: .ios,
      resolvedAppearance: .dark,
      features: YiTongBridgeFeatureFlags(selection: true, workerMode: false)
    )
    let message = YiTongBridgeOutgoingEnvelope(
      id: "msg-1",
      type: .initialize,
      payload: payload
    )

    let data = try YiTongBridgeCodec.encode(message)
    let decoded = try YiTongBridgeCodec.decode(
      YiTongBridgeOutgoingEnvelope<YiTongInitializePayload>.self,
      from: data
    )

    XCTAssertEqual(decoded, message)
  }

  func testReadyEnvelopeDecodes() throws {
    let json = """
    {
      "protocolVersion": 1,
      "id": "evt-1",
      "type": "ready",
      "payload": {
        "rendererVersion": "0.1.0-placeholder"
      }
    }
    """

    let decoded = try YiTongBridgeCodec.decode(
      YiTongBridgeIncomingEnvelope<YiTongReadyPayload>.self,
      from: Data(json.utf8)
    )

    XCTAssertEqual(decoded.type, .ready)
    XCTAssertEqual(decoded.payload.rendererVersion, "0.1.0-placeholder")
  }

  func testProtocolVersionMismatchFailsDecoding() {
    let json = """
    {
      "protocolVersion": 999,
      "id": "evt-1",
      "type": "ready",
      "payload": {
        "rendererVersion": "0.1.0-placeholder"
      }
    }
    """

    XCTAssertThrowsError(
      try YiTongBridgeCodec.decode(
        YiTongBridgeIncomingEnvelope<YiTongReadyPayload>.self,
        from: Data(json.utf8)
      )
    )
  }

  func testUpdateConfigurationEnvelopeRoundTrips() throws {
    let payload = YiTongBridgeConfigurationPayload(
      diffStyle: .unified,
      diffIndicators: .classic,
      showsLineNumbers: false,
      showsChangeBackgrounds: false,
      wrapsLines: true,
      showsFileHeaders: false,
      inlineChangeStyle: .char,
      allowsSelection: false,
      resolvedAppearance: .light
    )
    let message = YiTongBridgeOutgoingEnvelope(
      id: "msg-2",
      type: .updateConfiguration,
      payload: payload
    )

    let data = try YiTongBridgeCodec.encode(message)
    let decoded = try YiTongBridgeCodec.decode(
      YiTongBridgeOutgoingEnvelope<YiTongBridgeConfigurationPayload>.self,
      from: data
    )

    XCTAssertEqual(decoded, message)
  }

  func testRenderDocumentEnvelopeRoundTripsFileBasedDocument() throws {
    let payload = YiTongRenderDocumentPayload(
      document: YiTongBridgeDocumentPayload(
        identifier: "document-files",
        title: "Files",
        patch: "diff --git a/a.txt b/a.txt",
        files: [
          YiTongBridgeFilePayload(
            oldPath: "a.txt",
            newPath: "a.txt",
            oldContents: "before\n",
            newContents: "after\n"
          ),
        ]
      ),
      configuration: YiTongBridgeConfigurationPayload(
        diffStyle: .split,
        diffIndicators: .bars,
        showsLineNumbers: true,
        showsChangeBackgrounds: true,
        wrapsLines: false,
        showsFileHeaders: true,
        inlineChangeStyle: .wordAlt,
        allowsSelection: true,
        resolvedAppearance: .dark
      )
    )
    let message = YiTongBridgeOutgoingEnvelope(
      id: "msg-files",
      type: .renderDocument,
      payload: payload
    )

    let data = try YiTongBridgeCodec.encode(message)
    let decoded = try YiTongBridgeCodec.decode(
      YiTongBridgeOutgoingEnvelope<YiTongRenderDocumentPayload>.self,
      from: data
    )

    XCTAssertEqual(decoded, message)
  }

  func testTeardownEnvelopeRoundTrips() throws {
    let message = YiTongBridgeOutgoingEnvelope(
      id: "msg-3",
      type: .teardown,
      payload: YiTongEmptyPayload()
    )

    let data = try YiTongBridgeCodec.encode(message)
    let decoded = try YiTongBridgeCodec.decode(
      YiTongBridgeOutgoingEnvelope<YiTongEmptyPayload>.self,
      from: data
    )

    XCTAssertEqual(decoded, message)
  }

  func testLineActivatedEnvelopeDecodes() throws {
    let json = """
    {
      "protocolVersion": 1,
      "id": "evt-3",
      "type": "lineActivated",
      "payload": {
        "fileIndex": 1,
        "oldPath": "Sources/Old.swift",
        "newPath": "Sources/New.swift",
        "side": "new",
        "number": 42,
        "kind": "addition"
      }
    }
    """

    let decoded = try YiTongBridgeCodec.decode(
      YiTongBridgeIncomingEnvelope<YiTongLineActivatedPayload>.self,
      from: Data(json.utf8)
    )

    XCTAssertEqual(decoded.type, .lineActivated)
    XCTAssertEqual(decoded.payload.fileIndex, 1)
    XCTAssertEqual(decoded.payload.side, .new)
    XCTAssertEqual(decoded.payload.kind, .addition)
  }

  func testSelectionChangedEnvelopeDecodesNilSelection() throws {
    let json = """
    {
      "protocolVersion": 1,
      "id": "evt-4",
      "type": "selectionChanged",
      "payload": {
        "selection": null
      }
    }
    """

    let decoded = try YiTongBridgeCodec.decode(
      YiTongBridgeIncomingEnvelope<YiTongSelectionChangedPayload>.self,
      from: Data(json.utf8)
    )

    XCTAssertEqual(decoded.type, .selectionChanged)
    XCTAssertNil(decoded.payload.selection)
  }

  func testRenderDocumentEnvelopeRoundTripsAnnotations() throws {
    let payload = YiTongRenderDocumentPayload(
      document: YiTongBridgeDocumentPayload(
        identifier: "document-annotated",
        title: nil,
        patch: "diff --git a/a.txt b/a.txt"
      ),
      configuration: makeConfiguration(),
      annotations: [
        YiTongBridgeAnnotationPayload(
          id: "thread-1",
          fileIndex: 0,
          side: .new,
          lineNumber: 7,
          kind: "discussion",
          html: "<p>Looks good</p>"
        ),
        YiTongBridgeAnnotationPayload(
          id: "draft-1",
          fileIndex: 1,
          side: .old,
          lineNumber: 3,
          text: "Plain text note"
        ),
      ]
    )
    let message = YiTongBridgeOutgoingEnvelope(
      id: "msg-annotated",
      type: .renderDocument,
      payload: payload
    )

    let data = try YiTongBridgeCodec.encode(message)
    let decoded = try YiTongBridgeCodec.decode(
      YiTongBridgeOutgoingEnvelope<YiTongRenderDocumentPayload>.self,
      from: data
    )

    XCTAssertEqual(decoded, message)
  }

  func testRenderDocumentPayloadDecodesWithoutAnnotationsKey() throws {
    let json = """
    {
      "document": { "identifier": "document-legacy", "patch": "diff --git a/a.txt b/a.txt" },
      "configuration": {
        "diffStyle": "split",
        "diffIndicators": "bars",
        "showsLineNumbers": true,
        "showsChangeBackgrounds": true,
        "wrapsLines": false,
        "showsFileHeaders": true,
        "inlineChangeStyle": "wordAlt",
        "allowsSelection": true,
        "resolvedAppearance": "light"
      }
    }
    """

    let decoded = try YiTongBridgeCodec.decode(YiTongRenderDocumentPayload.self, from: Data(json.utf8))

    XCTAssertEqual(decoded.document.identifier, "document-legacy")
    XCTAssertEqual(decoded.annotations, [])
  }

  func testRenderDocumentEnvelopeEncodesAnnotationsKeyWhenEmpty() throws {
    let payload = YiTongRenderDocumentPayload(
      document: YiTongBridgeDocumentPayload(identifier: "document-empty", title: nil, patch: "diff"),
      configuration: makeConfiguration()
    )

    let data = try YiTongBridgeCodec.encode(payload)
    let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

    XCTAssertEqual((object["annotations"] as? [Any])?.count, 0)
  }

  func testUpdateAnnotationsEnvelopeRoundTrips() throws {
    let message = YiTongBridgeOutgoingEnvelope(
      id: "msg-annotations",
      type: .updateAnnotations,
      payload: YiTongUpdateAnnotationsPayload(
        annotations: [
          YiTongBridgeAnnotationPayload(id: "thread-1", fileIndex: 0, side: .new, lineNumber: 7, html: "<p>Hi</p>"),
        ]
      )
    )

    let data = try YiTongBridgeCodec.encode(message)
    let decoded = try YiTongBridgeCodec.decode(
      YiTongBridgeOutgoingEnvelope<YiTongUpdateAnnotationsPayload>.self,
      from: data
    )

    XCTAssertEqual(decoded, message)
    XCTAssertEqual(decoded.type, .updateAnnotations)
  }

  func testAnnotationActivatedEnvelopeDecodes() throws {
    let json = """
    {
      "protocolVersion": 1,
      "id": "evt-5",
      "type": "annotationActivated",
      "payload": {
        "id": "thread-1",
        "action": "reply",
        "kind": "discussion",
        "fileIndex": 0,
        "side": "new",
        "lineNumber": 7
      }
    }
    """

    let decoded = try YiTongBridgeCodec.decode(
      YiTongBridgeIncomingEnvelope<YiTongAnnotationActivatedPayload>.self,
      from: Data(json.utf8)
    )

    XCTAssertEqual(decoded.type, .annotationActivated)
    XCTAssertEqual(
      decoded.payload,
      YiTongAnnotationActivatedPayload(
        id: "thread-1",
        action: "reply",
        kind: "discussion",
        fileIndex: 0,
        side: .new,
        lineNumber: 7
      )
    )
  }


  func testRenderDocumentEnvelopeRoundTripsFolds() throws {
    let message = YiTongBridgeOutgoingEnvelope(
      id: "msg-folded",
      type: .renderDocument,
      payload: YiTongRenderDocumentPayload(
        document: YiTongBridgeDocumentPayload(
          identifier: "document-folded",
          title: nil,
          patch: "diff --git a/a.txt b/a.txt",
          folds: [
            YiTongBridgeFoldPayload(fileIndex: 0, collapsed: true, label: "L88–90 · +3 −3", detail: "R1 · docs", tone: "R1"),
            YiTongBridgeFoldPayload(fileIndex: 1, collapsed: false, label: "L10–24 · +12 −2"),
          ]
        ),
        configuration: makeConfiguration()
      )
    )

    let data = try YiTongBridgeCodec.encode(message)
    let decoded = try YiTongBridgeCodec.decode(
      YiTongBridgeOutgoingEnvelope<YiTongRenderDocumentPayload>.self,
      from: data
    )
    XCTAssertEqual(decoded, message)

    let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    let payload = try XCTUnwrap(object["payload"] as? [String: Any])
    let document = try XCTUnwrap(payload["document"] as? [String: Any])
    let folds = try XCTUnwrap(document["folds"] as? [[String: Any]])
    XCTAssertEqual(folds.first?["fileIndex"] as? Int, 0)
    XCTAssertEqual(folds.first?["collapsed"] as? Bool, true)
    XCTAssertEqual(folds.first?["label"] as? String, "L88–90 · +3 −3")
    XCTAssertEqual(folds.first?["detail"] as? String, "R1 · docs")
    XCTAssertEqual(folds.first?["tone"] as? String, "R1")
    XCTAssertNil(folds.last?["detail"])
  }

  func testRenderDocumentWithoutFoldsOmitsFoldsKey() throws {
    let payload = YiTongRenderDocumentPayload(
      document: YiTongBridgeDocumentPayload(identifier: "document-plain", title: nil, patch: "diff"),
      configuration: makeConfiguration()
    )

    let data = try YiTongBridgeCodec.encode(payload)
    let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    let document = try XCTUnwrap(object["document"] as? [String: Any])

    XCTAssertNil(document["folds"])
  }

  func testFoldToggledEnvelopeDecodes() throws {
    let json = """
    {
      "protocolVersion": 1,
      "id": "evt-9",
      "type": "foldToggled",
      "payload": { "fileIndex": 3, "collapsed": false }
    }
    """

    let decoded = try YiTongBridgeCodec.decode(
      YiTongBridgeIncomingEnvelope<YiTongFoldToggledPayload>.self,
      from: Data(json.utf8)
    )

    XCTAssertEqual(decoded.type, .foldToggled)
    XCTAssertEqual(decoded.payload, YiTongFoldToggledPayload(fileIndex: 3, collapsed: false))
  }

  private func makeConfiguration() -> YiTongBridgeConfigurationPayload {
    YiTongBridgeConfigurationPayload(
      diffStyle: .split,
      diffIndicators: .bars,
      showsLineNumbers: true,
      showsChangeBackgrounds: true,
      wrapsLines: false,
      showsFileHeaders: true,
      inlineChangeStyle: .wordAlt,
      allowsSelection: true,
      resolvedAppearance: .light
    )
  }
}
