import { describe, expect, it } from "vitest";
import { buildFoldStates, isFileCollapsed, toggleFold } from "./foldModel";
import type { FoldPayload } from "./protocol";

const trivial: FoldPayload = {
  fileIndex: 0,
  collapsed: true,
  label: "L88–90 · +3 −3",
  detail: "R1 · docs",
  tone: "R1",
};

const functional: FoldPayload = {
  fileIndex: 2,
  collapsed: false,
  label: "L10–24 · +12 −2",
  tone: "R3",
};

describe("buildFoldStates", () => {
  it("takes the initial collapsed state from the payload", () => {
    const states = buildFoldStates([trivial, functional], 3);

    expect(isFileCollapsed(states, 0)).toBe(true);
    expect(isFileCollapsed(states, 2)).toBe(false);
    expect(states.get(0)).toEqual(trivial);
  });

  it("leaves files without a fold expanded and unfolded", () => {
    const states = buildFoldStates([trivial], 3);

    expect(states.has(1)).toBe(false);
    expect(isFileCollapsed(states, 1)).toBe(false);
  });

  it("returns no folds when the document has none", () => {
    expect(buildFoldStates(undefined, 3).size).toBe(0);
    expect(buildFoldStates([], 3).size).toBe(0);
  });

  it("drops folds that point outside the rendered files", () => {
    const stale: FoldPayload = { ...trivial, fileIndex: 7 };
    const negative: FoldPayload = { ...trivial, fileIndex: -1 };
    const fractional: FoldPayload = { ...trivial, fileIndex: 0.5 };

    const states = buildFoldStates([stale, negative, fractional, functional], 3);

    expect([...states.keys()]).toEqual([2]);
  });

  it("lets the later fold win when two target the same file", () => {
    const replacement: FoldPayload = { ...trivial, collapsed: false, label: "replacement" };

    const states = buildFoldStates([trivial, replacement], 1);

    expect(states.get(0)?.label).toBe("replacement");
    expect(isFileCollapsed(states, 0)).toBe(false);
  });

  it("keeps the viewer's toggles when re-rendering the same document", () => {
    const previous = buildFoldStates([trivial, functional], 3);
    toggleFold(previous, 0);

    const states = buildFoldStates([trivial, functional], 3, previous);

    expect(isFileCollapsed(states, 0)).toBe(false);
    expect(isFileCollapsed(states, 2)).toBe(false);
  });
});

describe("toggleFold", () => {
  it("flips the fold and reports the new state", () => {
    const states = buildFoldStates([trivial], 1);

    expect(toggleFold(states, 0)).toEqual({ fileIndex: 0, collapsed: false });
    expect(isFileCollapsed(states, 0)).toBe(false);
    expect(toggleFold(states, 0)).toEqual({ fileIndex: 0, collapsed: true });
    expect(isFileCollapsed(states, 0)).toBe(true);
  });

  it("ignores files without a fold", () => {
    const states = buildFoldStates([trivial], 2);

    expect(toggleFold(states, 1)).toBeUndefined();
    expect(states.has(1)).toBe(false);
  });
});
