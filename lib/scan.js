/**
 * Scans a root element for trackers; returns structured findings.
 */
(function () {
  const P = self.PixelCrushPatterns;
  if (!P) {
    console.error("[PixelCrush] PixelCrushPatterns not loaded");
  }

  /**
   * @param {string} url
   * @returns {{ type: string, detail: string } | null}
   */
  function matchUrl(url) {
    if (!url || typeof url !== "string") return null;
    if (!P || !P.TRACKER_HOST_SUBSTRINGS) return null;
    const lower = url.toLowerCase();
    try {
      const u = new URL(url, "https://invalid.example/");
      const host = u.hostname.toLowerCase();
      const full = u.href.toLowerCase();

      for (const sub of P.TRACKER_HOST_SUBSTRINGS) {
        if (host.includes(sub) || full.includes(sub)) {
          return { type: "known_tracker_host", detail: sub };
        }
      }

      const searchLower = u.search.toLowerCase();
      for (const key of P.TRACKING_QUERY_KEYS) {
        if (searchLower.includes(key.toLowerCase())) {
          return { type: "tracking_query", detail: key };
        }
      }
      const qs = u.searchParams.toString().toLowerCase();
      for (const sub of P.TRACKING_QUERY_SUBSTRINGS) {
        if (qs.includes(sub)) {
          return { type: "tracking_query", detail: sub };
        }
      }
    } catch {
      for (const sub of P.TRACKER_HOST_SUBSTRINGS) {
        if (lower.includes(sub)) {
          return { type: "known_tracker_host", detail: sub };
        }
      }
    }
    return null;
  }

  /**
   * Gmail often wraps images; try to extract original URL from proxy URL or attributes.
   * @param {HTMLImageElement} img
   * @returns {string[]}
   */
  function imageCandidateUrls(img) {
    const urls = [];
    if (img.src) urls.push(img.src);
    if (img.srcset) {
      for (const part of img.srcset.split(",")) {
        const u = part.trim().split(/\s+/)[0];
        if (u) urls.push(u);
      }
    }
    for (const attr of ["data-src", "data-original", "data-original-src", "data-saferedirecturl"]) {
      const v = img.getAttribute(attr);
      if (v) urls.push(v);
    }
    /** @type {HTMLAnchorElement | null} */
    const parentA = img.closest("a");
    if (parentA && parentA.href) urls.push(parentA.href);

    const long = img.outerHTML || "";
    const re = /https?:\/\/[^\s"'<>]+/gi;
    let m;
    while ((m = re.exec(long)) !== null) {
      if (m[0].length < 2048) urls.push(m[0]);
    }
    return [...new Set(urls)];
  }

  /**
   * @param {HTMLElement} root
   * @returns {{ findings: Array<{ kind: string, detail: string, url?: string }>, blockedElements: WeakSet<Element> }}
   */
  function scanDom(root) {
    /** @type {Array<{ kind: string, detail: string, url?: string }>} */
    const findings = [];
    const seen = new Set();

    function add(kind, detail, url) {
      const key = `${kind}|${detail}|${url || ""}`;
      if (seen.has(key)) return;
      seen.add(key);
      findings.push({ kind, detail, url });
    }

    root.querySelectorAll("img").forEach((img) => {
      const w = img.width || Number(img.getAttribute("width")) || 0;
      const h = img.height || Number(img.getAttribute("height")) || 0;
      const style = (img.getAttribute("style") || "").toLowerCase();
      const hiddenDim =
        (w > 0 && w <= 5 && h > 0 && h <= 5) ||
        /(?:^|;|\s)(?:width|max-width)\s*:\s*0|(?:^|;|\s)(?:height|max-height)\s*:\s*0/.test(style) ||
        (img.getAttribute("alt") === "" && /display\s*:\s*none|visibility\s*:\s*hidden|opacity\s*:\s*0/.test(style));

      for (const url of imageCandidateUrls(img)) {
        const m = matchUrl(url);
        if (m) {
          add(m.type === "known_tracker_host" ? "tracker_image" : "tracked_url_in_image", m.detail, url);
        }
      }
      if (hiddenDim) {
        const urls = imageCandidateUrls(img);
        const anyExternal = urls.some((u) => /^https?:\/\//i.test(u) && !u.includes("mail.google.com"));
        if (anyExternal || urls.length) {
          add("tracking_pixel", "Small or hidden image (likely tracking pixel)", urls[0]);
        }
      }
    });

    root.querySelectorAll('iframe[src], frame[src]').forEach((el) => {
      const src = el.getAttribute("src") || "";
      const m = matchUrl(src);
      if (m) add("tracker_iframe", m.detail, src);
    });

    root.querySelectorAll('a[href^="http"], a[href^="//"]').forEach((a) => {
      const href = a.getAttribute("href") || "";
      const m = matchUrl(href);
      if (m) add("tracked_link", m.detail, href);
    });

    return { findings, blockedElements: new WeakSet() };
  }

  const g = typeof globalThis !== "undefined" ? globalThis : self;
  g.PixelCrushScan = { scanDom, matchUrl, imageCandidateUrls };
})();
