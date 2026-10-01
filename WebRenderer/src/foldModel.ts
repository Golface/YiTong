import type { FoldPayload, FoldToggledPayload } from "./protocol";

export type FoldStates = Map<number, FoldPayload>;

/**
 * Indexes host folds by file. Folds pointing outside `fileCount` are dropped so
 * a stale fold list can never break rendering; when two folds target the same
 * file the later one wins.
 *
 * `previous` carries the viewer's own toggles across a re-render of the same
 * document (for example a configuration change), so the payload's initial
 * `collapsed` value only applies to files the viewer has not touched.
 */
export function buildFoldStates(
  folds: readonly FoldPayload[] | undefined,
  fileCount: number,
  previous?: FoldStates,
): FoldStates {
  const states: FoldStates = new Map();

  for (const fold of folds ?? []) {
    if (!Number.isInteger(fold.fileIndex) || fold.fileIndex < 0 || fold.fileIndex >= fileCount) {
      continue;
    }

    const collapsed = previous?.get(fold.fileIndex)?.collapsed ?? fold.collapsed;
    states.set(fold.fileIndex, { ...fold, collapsed });
  }

  return states;
}

export function isFileCollapsed(states: FoldStates, fileIndex: number): boolean {
  return states.get(fileIndex)?.collapsed ?? false;
}

/**
 * Flips the fold for `fileIndex` in place and returns the event to report.
 * Files without a fold have no header to toggle, so they return `undefined`.
 */
export function toggleFold(states: FoldStates, fileIndex: number): FoldToggledPayload | undefined {
  const fold = states.get(fileIndex);
  if (fold == null) {
    return undefined;
  }

  const collapsed = !fold.collapsed;
  states.set(fileIndex, { ...fold, collapsed });
  return { fileIndex, collapsed };
}
