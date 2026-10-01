import Foundation

/// A collapsible header placed above one file of the rendered document.
///
/// A collapsed file is not rendered until the viewer expands it, so hosts can
/// split a large patch into many small files (for example one per hunk) and
/// fold the trivial ones without paying for their syntax highlighting.
/// Toggles are reported through `DiffEvent.didToggleFold`; the viewer's own
/// toggles survive configuration changes but reset when the document changes.
public struct DiffFold: Sendable, Equatable {
  /// Index of the file within the rendered document.
  public var fileIndex: Int
  /// Whether the file starts collapsed.
  public var collapsed: Bool
  /// Primary header text, for example `"L88–90 · +3 −3"`.
  public var label: String
  /// Secondary header text shown after the label.
  public var detail: String?
  /// Free-form host key exposed to the page as `data-tone`; YiTong does not interpret it.
  public var tone: String?

  public init(
    fileIndex: Int,
    collapsed: Bool,
    label: String,
    detail: String? = nil,
    tone: String? = nil
  ) {
    self.fileIndex = fileIndex
    self.collapsed = collapsed
    self.label = label
    self.detail = detail
    self.tone = tone
  }
}
