(function () {
  const TS = "tracker-tracker";
  const BADGE_CLASS = "ts-tracker-badge";
  const ATTR_THREAD = "data-ts-thread-id";

  /** @type {ReturnType<typeof setTimeout> | null} */
  let scanDebounce = null;
  /** @type {string | null} */
  let lastThreadId = null;

  function getThreadIdFromHash() {
    const h = (location.hash || "").split("?")[0];
    const segments = h.split("/").filter(Boolean);
    for (let i = segments.length - 1; i >= 0; i--) {
      const seg = segments[i];
      if (/^[A-Za-z0-9:_-]{10,}$/.test(seg) && !/^(inbox|sent|drafts|all|spam|trash|starred|important|snoozed)$/i.test(seg)) {
        return seg;
      }
    }
    return null;
  }

  /**
   * @param {HTMLElement} el
   * @returns {string | null}
   */
  function threadIdFromRow(el) {
    const legacy = el.getAttribute("data-legacy-thread-id");
    if (legacy) return legacy;
    const oid = el.getAttribute("data-thread-id");
    if (oid) return oid;
    const jslog = el.getAttribute("jslog");
    if (jslog) {
      const m = jslog.match(/thread[_:]([A-Za-z0-9:_-]+)/i);
      if (m) return m[1];
    }
    return null;
  }

  function placeholderUrl() {
    try {
      return chrome.runtime.getURL("blocked-pixel.png");
    } catch {
      return "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7";
    }
  }

  /**
   * @param {HTMLElement} root
   * @returns {{ findings: Array<{ kind: string; detail: string; url?: string }> }}
   */
  function scanAndBlock(root) {
    const { findings } = self.TrackerScan.scanDom(root);
    const ph = placeholderUrl();

    root.querySelectorAll("img").forEach((img) => {
      const candidates = self.TrackerScan.imageCandidateUrls(img);
      let shouldBlock = false;
      for (const url of candidates) {
        const m = self.TrackerScan.matchUrl(url);
        if (m) {
          shouldBlock = true;
          break;
        }
      }
      const w = img.width || Number(img.getAttribute("width")) || 0;
      const h = img.height || Number(img.getAttribute("height")) || 0;
      const style = (img.getAttribute("style") || "").toLowerCase();
      const tiny = (w > 0 && w <= 5 && h > 0 && h <= 5) || /(?:^|;|\s)(?:width|max-width)\s*:\s*1px|(?:^|;|\s)(?:height|max-height)\s*:\s*1px/.test(style);
      if (tiny && candidates.some((u) => /^https?:\/\//i.test(u))) {
        shouldBlock = true;
      }
      if (shouldBlock && !img.dataset.tsBlocked) {
        img.dataset.tsBlocked = "1";
        if (img.src && !img.src.startsWith("data:")) img.dataset.tsOriginalSrc = img.src;
        img.src = ph;
        img.removeAttribute("srcset");
      }
    });

    return { findings };
  }

  /**
   * @param {HTMLElement} root
   */
  function deepScan(root) {
    const merged = [];
    const seen = new Set();
    const add = (arr) => {
      for (const f of arr) {
        const k = `${f.kind}|${f.detail}|${f.url || ""}`;
        if (!seen.has(k)) {
          seen.add(k);
          merged.push(f);
        }
      }
    };

    const { findings } = scanAndBlock(root);
    add(findings);

    root.querySelectorAll("iframe").forEach((frame) => {
      try {
        const doc = frame.contentDocument;
        if (doc && doc.body) {
          const inner = scanAndBlock(doc.body);
          add(inner.findings);
        }
      } catch {
        /* cross-origin */
      }
    });

    return merged;
  }

  /**
   * @param {string} threadId
   * @param {Array<{ kind: string; detail: string; url?: string }>} findings
   */
  function persistFindings(threadId, findings) {
    if (!threadId || !findings.length) return;
    const key = `ts:${threadId}`;
    chrome.storage.local.get([key], (prev) => {
      const existing = (prev && prev[key]) || { findings: [], updated: 0 };
      const map = new Map();
      for (const f of existing.findings) {
        map.set(`${f.kind}|${f.detail}|${f.url || ""}`, f);
      }
      for (const f of findings) {
        map.set(`${f.kind}|${f.detail}|${f.url || ""}`, f);
      }
      const next = { findings: [...map.values()], updated: Date.now() };
      chrome.storage.local.set({ [key]: next });
    });
  }

  function scheduleScan(threadId) {
    if (scanDebounce) clearTimeout(scanDebounce);
    scanDebounce = setTimeout(() => {
      scanDebounce = null;
      const body = document.body;
      if (!body) return;
      const findings = deepScan(body);
      if (threadId && findings.length) persistFindings(threadId, findings);
      if (window.self === window.top) decorateListRows();
    }, 400);
  }

  /**
   * @param {Array<{ kind: string; detail: string; url?: string }>} findings
   */
  function formatTooltip(findings) {
    const lines = ["Tracker Tracker — blocked / detected:"];
    const byKind = {};
    for (const f of findings) {
      if (!byKind[f.kind]) byKind[f.kind] = [];
      byKind[f.kind].push(f.detail + (f.url ? `\n  ${f.url}` : ""));
    }
    for (const kind of Object.keys(byKind)) {
      lines.push("");
      lines.push(kind.replace(/_/g, " ") + ":");
      byKind[kind].forEach((d) => lines.push(" • " + d.replace(/\n/g, "\n   ")));
    }
    return lines.join("\n");
  }

  /** @type {HTMLDivElement | null} */
  let floatTipEl = null;

  function hideFloatTip() {
    if (floatTipEl) {
      floatTipEl.hidden = true;
      floatTipEl.textContent = "";
    }
  }

  /**
   * @param {HTMLElement} badge
   * @param {string} text
   */
  function showFloatTip(badge, text) {
    if (!floatTipEl) {
      floatTipEl = document.createElement("div");
      floatTipEl.className = "ts-float-tip";
      floatTipEl.setAttribute("role", "tooltip");
      document.body.appendChild(floatTipEl);
    }
    floatTipEl.textContent = text;
    floatTipEl.hidden = false;
    floatTipEl.style.position = "fixed";
    const r = badge.getBoundingClientRect();
    const maxW = Math.min(420, window.innerWidth - 24);
    floatTipEl.style.maxWidth = maxW + "px";
    let left = r.left;
    let top = r.bottom + 8;
    if (left + maxW > window.innerWidth - 12) left = window.innerWidth - maxW - 12;
    if (left < 8) left = 8;
    const estH = 180;
    if (top + estH > window.innerHeight) top = Math.max(8, r.top - estH - 8);
    floatTipEl.style.left = left + "px";
    floatTipEl.style.top = top + "px";
  }

  function ensureBadgeOnRow(row, threadId) {
    if (!threadId) return;
    const key = `ts:${threadId}`;
    chrome.storage.local.get([key], (data) => {
      const entry = data[key];
      if (!entry || !entry.findings || !entry.findings.length) {
        const badge = row.querySelector("." + BADGE_CLASS);
        if (badge) badge.remove();
        row.removeAttribute(ATTR_THREAD);
        return;
      }

      row.setAttribute(ATTR_THREAD, threadId);
      const tipText = formatTooltip(entry.findings);
      let badge = row.querySelector("." + BADGE_CLASS);
      if (!badge) {
        badge = document.createElement("span");
        badge.className = BADGE_CLASS;
        badge.setAttribute("role", "img");
        badge.setAttribute("aria-label", "This thread contains detected trackers");
        const host =
          row.querySelector("span.bqe, span.bog, td.yf") ||
          row.querySelector("td.yx, td.xY, td.apU") ||
          row.querySelector("td") ||
          row;
        host.appendChild(badge);
      }
      badge.title = tipText;
      badge.textContent = String(entry.findings.length);
      badge.onmouseenter = () => showFloatTip(badge, tipText);
      badge.onmouseleave = () => hideFloatTip();
    });
  }

  function decorateListRows() {
    const selectors = [
      "tr[data-legacy-thread-id]",
      "tr[role='row'][data-legacy-thread-id]",
      "div[role='row'][data-legacy-thread-id]",
      "div[role='listitem'][data-legacy-thread-id]",
    ];
    const seen = new Set();
    for (const sel of selectors) {
      document.querySelectorAll(sel).forEach((row) => {
        const id = threadIdFromRow(row);
        if (!id || seen.has(id)) return;
        seen.add(id);
        ensureBadgeOnRow(row, id);
      });
    }
  }

  function initTopFrame() {
    window.addEventListener("message", (ev) => {
      if (ev.source !== window && ev.data && ev.data.source === TS && Array.isArray(ev.data.findings)) {
        const tid = getThreadIdFromHash() || lastThreadId;
        if (tid && ev.data.findings.length) persistFindings(tid, ev.data.findings);
      }
    });

    const obs = new MutationObserver(() => {
      const tid = getThreadIdFromHash();
      lastThreadId = tid || lastThreadId;
      scheduleScan(lastThreadId);
    });
    obs.observe(document.documentElement, { childList: true, subtree: true, attributes: true, attributeFilter: ["href", "src"] });

    window.addEventListener("hashchange", () => {
      lastThreadId = getThreadIdFromHash() || lastThreadId;
      scheduleScan(lastThreadId);
    });

    document.addEventListener(
      "scroll",
      () => {
        hideFloatTip();
      },
      true
    );

    chrome.storage.onChanged.addListener(() => {
      decorateListRows();
    });

    lastThreadId = getThreadIdFromHash();
    scheduleScan(lastThreadId);
    decorateListRows();
  }

  function initChildFrame() {
    const run = () => {
      try {
        if (!document.body) return;
        const findings = deepScan(document.body);
        if (findings.length && window.top) {
          window.top.postMessage({ source: TS, findings }, "https://mail.google.com");
        }
      } catch {
        /* ignore */
      }
    };
    const start = () => {
      if (!document.body) return;
      const obs = new MutationObserver(() => run());
      obs.observe(document.body, { childList: true, subtree: true });
      run();
    };
    if (document.body) start();
    else {
      const boot = new MutationObserver(() => {
        if (document.body) {
          boot.disconnect();
          start();
        }
      });
      boot.observe(document.documentElement, { childList: true, subtree: true });
    }
  }

  if (window.self === window.top) {
    initTopFrame();
  } else {
    initChildFrame();
  }
})();
