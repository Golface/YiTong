import type { FoldPayload } from "./protocol";

export const FOLD_CLASS_NAME = "diff-fold";

const EXPANDED_INDICATOR = "▾";
const COLLAPSED_INDICATOR = "▸";

/**
 * Builds the clickable header row for a folded file. Text is inserted as plain
 * text because labels come from patch content (paths, rule reasons).
 */
export function createFoldHeaderElement(fold: FoldPayload, onToggle: () => void): HTMLElement {
  const header = document.createElement("div");
  header.className = FOLD_CLASS_NAME;
  header.setAttribute("role", "button");
  header.tabIndex = 0;
  header.dataset.fileIndex = String(fold.fileIndex);
  if (fold.tone != null) {
    header.dataset.tone = fold.tone;
  }

  const indicator = document.createElement("span");
  indicator.className = "diff-fold-indicator";
  indicator.setAttribute("aria-hidden", "true");
  header.appendChild(indicator);

  const label = document.createElement("span");
  label.className = "diff-fold-label";
  label.textContent = fold.label;
  header.appendChild(label);

  if (fold.detail != null && fold.detail.length > 0) {
    const detail = document.createElement("span");
    detail.className = "diff-fold-detail";
    detail.textContent = fold.detail;
    header.appendChild(detail);
  }

  applyFoldHeaderState(header, fold.collapsed);

  header.addEventListener("click", onToggle);
  header.addEventListener("keydown", (event) => {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      onToggle();
    }
  });

  return header;
}

export function applyFoldHeaderState(header: HTMLElement, collapsed: boolean) {
  header.dataset.collapsed = String(collapsed);
  header.setAttribute("aria-expanded", String(!collapsed));
  const indicator = header.querySelector(".diff-fold-indicator");
  if (indicator != null) {
    indicator.textContent = collapsed ? COLLAPSED_INDICATOR : EXPANDED_INDICATOR;
  }
}
