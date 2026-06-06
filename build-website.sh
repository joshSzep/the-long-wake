#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/website"
CHAPTER_SOURCE="$SCRIPT_DIR/chapters/01-waking/01.md"
COVER_SOURCE="$SCRIPT_DIR/cover.png"
PDF_SOURCE="$SCRIPT_DIR/The Long Wake.pdf"
EPUB_SOURCE="$SCRIPT_DIR/The Long Wake.epub"
OUTPUT_HTML="$OUTPUT_DIR/index.html"
OUTPUT_COVER="$OUTPUT_DIR/cover.png"
OUTPUT_PDF="$OUTPUT_DIR/The Long Wake.pdf"
OUTPUT_EPUB="$OUTPUT_DIR/The Long Wake.epub"

require_file() {
    local path="$1"

    if [ ! -f "$path" ]; then
        echo "Error: required file not found: $path" >&2
        exit 1
    fi
}

markdown_to_html() {
    awk '
    function escape_html(text, escaped) {
        escaped = text
        gsub(/&/, "\\&amp;", escaped)
        gsub(/</, "\\&lt;", escaped)
        gsub(/>/, "\\&gt;", escaped)
        gsub(/\"/, "\\&quot;", escaped)
        return escaped
    }

    function trim(text) {
        sub(/^[[:space:]]+/, "", text)
        sub(/[[:space:]]+$/, "", text)
        return text
    }

    function flush_paragraph(escaped) {
        if (paragraph != "") {
            escaped = escape_html(trim(paragraph))
            print "<p>" escaped "</p>"
            paragraph = ""
        }
    }

    BEGIN {
        paragraph = ""
    }

    /^[[:space:]]*$/ {
        flush_paragraph()
        next
    }

    /^---[[:space:]]*$/ {
        flush_paragraph()
        print "<div class=\"chapter-break\" aria-hidden=\"true\"></div>"
        next
    }

    /^### / {
        flush_paragraph()
        print "<h4>" escape_html(substr($0, 5)) "</h4>"
        next
    }

    /^## / {
        flush_paragraph()
        print "<h3>" escape_html(substr($0, 4)) "</h3>"
        next
    }

    /^# / {
        flush_paragraph()
        print "<h2>" escape_html(substr($0, 3)) "</h2>"
        next
    }

    {
        line = trim($0)

        if (paragraph == "") {
            paragraph = line
        } else {
            paragraph = paragraph " " line
        }
    }

    END {
        flush_paragraph()
    }
    ' "$1"
}

require_file "$CHAPTER_SOURCE"
require_file "$COVER_SOURCE"
require_file "$PDF_SOURCE"
require_file "$EPUB_SOURCE"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

cp "$COVER_SOURCE" "$OUTPUT_COVER"
cp "$PDF_SOURCE" "$OUTPUT_PDF"
cp "$EPUB_SOURCE" "$OUTPUT_EPUB"

CHAPTER_HTML="$(markdown_to_html "$CHAPTER_SOURCE")"

{
cat <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>The Long Wake</title>
  <meta name="description" content="The Long Wake by Joshua Szepietowski. A quiet, interior science fiction novel about waking decades too soon aboard an interstellar colony ship.">
  <link rel="icon" type="image/png" href="cover.png">
  <link rel="apple-touch-icon" href="cover.png">
  <style>
    :root {
      color-scheme: dark;
      --bg: #04070c;
      --bg-deep: #020409;
      --panel: rgba(15, 21, 30, 0.62);
      --panel-strong: rgba(18, 24, 34, 0.82);
      --line: rgba(170, 186, 204, 0.16);
      --line-strong: rgba(170, 186, 204, 0.3);
      --text: #d8dee8;
      --muted: #93a0b1;
      --faint: #6c7888;
      --glow: rgba(151, 184, 214, 0.18);
      --glow-strong: rgba(182, 212, 236, 0.28);
      --shadow: 0 24px 80px rgba(0, 0, 0, 0.48);
      --serif: "Iowan Old Style", "Palatino Linotype", "Book Antiqua", Palatino, "Times New Roman", serif;
      --sans: "Avenir Next", Avenir, "Helvetica Neue", Helvetica, Arial, sans-serif;
      --max-width: 1120px;
      --copy-width: 760px;
      --header-height: 78px;
      --ease: 900ms cubic-bezier(0.16, 1, 0.3, 1);
    }

    * {
      box-sizing: border-box;
    }

    html {
      scroll-behavior: smooth;
      background: var(--bg-deep);
    }

    body {
      margin: 0;
      min-height: 100vh;
      background:
        radial-gradient(circle at 20% 18%, rgba(73, 94, 120, 0.15), transparent 28%),
        radial-gradient(circle at 78% 12%, rgba(67, 85, 112, 0.12), transparent 24%),
        radial-gradient(circle at 50% 120%, rgba(35, 47, 65, 0.45), transparent 44%),
        linear-gradient(180deg, #07101b 0%, #04070c 30%, #020409 100%);
      color: var(--text);
      font-family: var(--sans);
      line-height: 1.8;
      letter-spacing: 0.01em;
      overflow-x: hidden;
    }

    body::before,
    body::after {
      content: "";
      position: fixed;
      inset: 0;
      pointer-events: none;
      z-index: 0;
    }

    body::before {
      background:
        linear-gradient(180deg, rgba(4, 7, 12, 0.06), rgba(4, 7, 12, 0.22)),
        repeating-linear-gradient(
          0deg,
          rgba(255, 255, 255, 0.014) 0,
          rgba(255, 255, 255, 0.014) 1px,
          transparent 1px,
          transparent 3px
        );
      opacity: 0.5;
      mix-blend-mode: soft-light;
      animation: grain-shift 14s steps(10) infinite;
    }

    body::after {
      background:
        radial-gradient(circle at 15% 25%, rgba(179, 202, 224, 0.05) 0 1px, transparent 2px),
        radial-gradient(circle at 68% 18%, rgba(179, 202, 224, 0.04) 0 1px, transparent 2px),
        radial-gradient(circle at 78% 62%, rgba(179, 202, 224, 0.04) 0 1px, transparent 2px),
        radial-gradient(circle at 30% 72%, rgba(179, 202, 224, 0.03) 0 1px, transparent 2px),
        radial-gradient(circle at 50% 50%, rgba(255, 255, 255, 0.015), transparent 42%);
      opacity: 0.36;
      animation: drift-stars 26s linear infinite;
    }

    a {
      color: inherit;
      text-decoration: none;
    }

    img {
      display: block;
      max-width: 100%;
    }

    canvas#ambient {
      position: fixed;
      inset: 0;
      width: 100%;
      height: 100%;
      pointer-events: none;
      opacity: 0.42;
      z-index: 0;
    }

    .site-header {
      position: fixed;
      top: 20px;
      left: 50%;
      width: min(calc(100% - 28px), var(--max-width));
      transform: translateX(-50%);
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 24px;
      padding: 16px 22px;
      border: 1px solid rgba(181, 199, 220, 0.12);
      border-radius: 18px;
      background: rgba(9, 14, 22, 0.52);
      backdrop-filter: blur(16px) saturate(120%);
      -webkit-backdrop-filter: blur(16px) saturate(120%);
      box-shadow: 0 10px 40px rgba(0, 0, 0, 0.22);
      z-index: 20;
      transition: opacity 360ms ease, transform 360ms ease, background 360ms ease, border-color 360ms ease;
    }

    .site-header.is-dim {
      opacity: 0.68;
      transform: translateX(-50%) translateY(-4px);
      background: rgba(9, 14, 22, 0.38);
      border-color: rgba(181, 199, 220, 0.08);
    }

    .brand {
      display: flex;
      flex-direction: column;
      gap: 3px;
      min-width: 0;
    }

    .brand-link {
      display: inline-flex;
      flex-direction: column;
      gap: 3px;
      color: inherit;
      transition: opacity 240ms ease, text-shadow 240ms ease;
    }

    .brand-link:hover,
    .brand-link:focus-visible {
      opacity: 0.96;
      text-shadow: 0 0 16px rgba(190, 210, 230, 0.16);
    }

    .brand-title {
      margin: 0;
      font-family: var(--serif);
      font-size: clamp(1.1rem, 1rem + 0.9vw, 1.55rem);
      font-weight: 400;
      letter-spacing: 0.08em;
      text-transform: uppercase;
      white-space: nowrap;
    }

    .brand-author {
      color: var(--muted);
      font-size: 0.82rem;
      letter-spacing: 0.18em;
      text-transform: uppercase;
    }

    .header-nav {
      display: flex;
      align-items: center;
      justify-content: flex-end;
      gap: 14px;
      flex-wrap: wrap;
    }

    .header-nav a {
      position: relative;
      color: var(--muted);
      font-size: 0.74rem;
      letter-spacing: 0.18em;
      text-transform: uppercase;
      transition: color 240ms ease, text-shadow 240ms ease;
    }

    .header-nav a::after {
      content: "";
      position: absolute;
      left: 0;
      bottom: -7px;
      width: 100%;
      height: 1px;
      background: linear-gradient(90deg, transparent, rgba(200, 218, 235, 0.75), transparent);
      transform: scaleX(0.3);
      transform-origin: center;
      opacity: 0;
      transition: transform 280ms ease, opacity 280ms ease;
    }

    .header-nav a:hover,
    .header-nav a:focus-visible {
      color: var(--text);
      text-shadow: 0 0 18px rgba(174, 204, 230, 0.18);
    }

    .header-nav a:hover::after,
    .header-nav a:focus-visible::after {
      transform: scaleX(1);
      opacity: 1;
    }

    main {
      position: relative;
      z-index: 1;
    }

    section {
      position: relative;
    }

    .hero {
      min-height: 100vh;
      display: grid;
      align-items: center;
      padding: calc(var(--header-height) + 72px) 24px 72px;
      overflow: clip;
    }

    .hero::before {
      content: "";
      position: absolute;
      inset: 12% -8% auto;
      height: 58%;
      background:
        radial-gradient(circle at center, rgba(120, 145, 173, 0.15), transparent 42%),
        radial-gradient(circle at center, rgba(255, 255, 255, 0.03), transparent 60%);
      filter: blur(26px);
      pointer-events: none;
    }

    .hero-inner {
      width: min(100%, var(--max-width));
      margin: 0 auto;
      display: grid;
      grid-template-columns: minmax(280px, 440px) minmax(300px, 1fr);
      gap: clamp(28px, 6vw, 88px);
      align-items: center;
    }

    .cover-wrap {
      position: relative;
      justify-self: center;
      width: min(100%, 380px);
      transform: translate3d(0, 0, 0);
      will-change: transform;
    }

    .cover-wrap::before,
    .cover-wrap::after {
      content: "";
      position: absolute;
      inset: auto 8% -7% 8%;
      height: 26%;
      border-radius: 999px;
      background: radial-gradient(circle, rgba(140, 174, 205, 0.22), transparent 72%);
      filter: blur(26px);
      z-index: -1;
    }

    .cover-wrap::after {
      inset: 10% -6% auto;
      height: 45%;
      background: radial-gradient(circle, rgba(132, 154, 181, 0.1), transparent 74%);
      filter: blur(40px);
    }

    .cover-shell {
      position: relative;
      border-radius: 28px;
      overflow: hidden;
      background: linear-gradient(180deg, rgba(219, 229, 237, 0.06), rgba(90, 111, 133, 0.02));
      border: 1px solid rgba(201, 216, 232, 0.12);
      box-shadow: var(--shadow);
    }

    .cover-shell::after {
      content: "";
      position: absolute;
      inset: 0;
      background:
        linear-gradient(135deg, rgba(255, 255, 255, 0.1), transparent 22%),
        linear-gradient(180deg, transparent 55%, rgba(4, 8, 15, 0.18));
      mix-blend-mode: screen;
      pointer-events: none;
    }

    .hero-copy {
      max-width: 640px;
    }

    .eyebrow {
      margin: 0 0 18px;
      color: var(--muted);
      font-size: 0.76rem;
      letter-spacing: 0.32em;
      text-transform: uppercase;
    }

    .hero-title {
      margin: 0;
      font-family: var(--serif);
      font-size: clamp(3.4rem, 7vw, 6.5rem);
      font-weight: 400;
      line-height: 0.92;
      letter-spacing: 0.03em;
      text-wrap: balance;
    }

    .hero-tagline {
      margin: 26px 0 0;
      max-width: 18ch;
      color: #eef3fa;
      font-family: var(--serif);
      font-size: clamp(1.28rem, 1rem + 1.2vw, 2rem);
      font-weight: 400;
      line-height: 1.4;
      letter-spacing: 0.02em;
      text-wrap: balance;
    }

    .hero-summary {
      margin: 22px 0 0;
      max-width: 54ch;
      color: var(--muted);
      font-size: clamp(1rem, 0.94rem + 0.35vw, 1.12rem);
    }

    .hero-actions {
      display: flex;
      align-items: center;
      gap: 16px;
      flex-wrap: wrap;
      margin-top: 34px;
    }

    .button,
    .ghost-link {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      min-height: 48px;
      padding: 0 20px;
      border-radius: 999px;
      font-size: 0.78rem;
      letter-spacing: 0.18em;
      text-transform: uppercase;
      transition: transform 260ms ease, border-color 260ms ease, background 260ms ease, box-shadow 260ms ease, color 260ms ease;
    }

    .button {
      color: #f1f5fb;
      background: linear-gradient(180deg, rgba(164, 190, 214, 0.13), rgba(164, 190, 214, 0.06));
      border: 1px solid rgba(189, 210, 230, 0.18);
      box-shadow: 0 0 0 1px rgba(196, 216, 235, 0.06) inset, 0 0 24px rgba(136, 166, 196, 0.12);
    }

    .ghost-link {
      color: var(--muted);
      border: 1px solid rgba(196, 216, 235, 0.08);
      background: rgba(196, 216, 235, 0.03);
    }

    .button:hover,
    .button:focus-visible,
    .ghost-link:hover,
    .ghost-link:focus-visible {
      transform: translateY(-1px);
    }

    .button:hover,
    .button:focus-visible {
      border-color: rgba(205, 225, 243, 0.3);
      background: linear-gradient(180deg, rgba(176, 202, 226, 0.18), rgba(176, 202, 226, 0.08));
      box-shadow: 0 0 0 1px rgba(216, 231, 246, 0.07) inset, 0 0 34px rgba(140, 171, 201, 0.18);
    }

    .ghost-link:hover,
    .ghost-link:focus-visible {
      color: var(--text);
      border-color: rgba(196, 216, 235, 0.18);
      background: rgba(196, 216, 235, 0.05);
    }

    .section-shell {
      width: min(100%, calc(var(--copy-width) + 120px));
      margin: 0 auto;
      padding: 0 24px;
    }

    .section-label {
      margin: 0 0 16px;
      color: var(--faint);
      font-size: 0.74rem;
      letter-spacing: 0.28em;
      text-transform: uppercase;
    }

    .chapter-section {
      padding: 52px 0 88px;
    }

    .chapter-frame {
      position: relative;
      padding: clamp(28px, 4vw, 48px);
      border: 1px solid var(--line);
      border-radius: 30px;
      background:
        linear-gradient(180deg, rgba(13, 19, 28, 0.78), rgba(9, 14, 22, 0.74)),
        radial-gradient(circle at top, rgba(176, 198, 219, 0.04), transparent 34%);
      backdrop-filter: blur(8px);
      box-shadow: 0 34px 90px rgba(0, 0, 0, 0.28);
    }

    .chapter-frame::before {
      content: "";
      position: absolute;
      inset: 16px;
      border-radius: 22px;
      border: 1px solid rgba(190, 209, 228, 0.05);
      pointer-events: none;
    }

    .chapter-body {
      width: min(100%, var(--copy-width));
      margin: 0 auto;
      color: #d5dde7;
      font-size: clamp(1.04rem, 0.98rem + 0.26vw, 1.14rem);
      line-height: 1.95;
    }

    .chapter-body h2,
    .chapter-body h3,
    .chapter-body h4 {
      margin: 0 0 1.4rem;
      color: #eef3f9;
      font-family: var(--serif);
      font-weight: 400;
      line-height: 1.16;
      letter-spacing: 0.02em;
    }

    .chapter-body h2 {
      font-size: clamp(2rem, 1.6rem + 1.4vw, 3rem);
      text-align: center;
      margin-bottom: 2.5rem;
    }

    .chapter-body h3 {
      font-size: 1.35rem;
      color: #dce6f1;
      margin-top: 2.6rem;
    }

    .chapter-body h4 {
      font-size: 1.18rem;
      color: #d5e1ee;
      margin-top: 2.2rem;
    }

    .chapter-body p {
      margin: 0 0 1.55rem;
      color: var(--text);
    }

    .chapter-body .chapter-break {
      width: 92px;
      height: 1px;
      margin: 2.8rem auto;
      background: linear-gradient(90deg, transparent, rgba(210, 223, 238, 0.4), transparent);
      box-shadow: 0 0 18px rgba(181, 201, 221, 0.08);
    }

    .download-section {
      padding: 28px 24px 104px;
    }

    .download-card {
      width: min(100%, 760px);
      margin: 0 auto;
      padding: clamp(28px, 4vw, 44px);
      text-align: center;
      border: 1px solid var(--line);
      border-radius: 28px;
      background: linear-gradient(180deg, rgba(10, 15, 23, 0.72), rgba(8, 11, 18, 0.78));
      box-shadow: 0 24px 70px rgba(0, 0, 0, 0.22);
    }

    .download-card h2 {
      margin: 0;
      font-family: var(--serif);
      font-size: clamp(2rem, 1.65rem + 1vw, 2.8rem);
      font-weight: 400;
      line-height: 1.15;
      letter-spacing: 0.02em;
    }

    .download-card p {
      margin: 18px auto 0;
      max-width: 36ch;
      color: var(--muted);
      font-size: 1rem;
    }

    .footer {
      padding: 0 24px 42px;
    }

    .footer-inner {
      width: min(100%, var(--max-width));
      margin: 0 auto;
      padding-top: 20px;
      border-top: 1px solid rgba(184, 203, 223, 0.08);
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 18px;
      color: var(--faint);
      font-size: 0.8rem;
      letter-spacing: 0.08em;
      text-transform: uppercase;
      flex-wrap: wrap;
    }

    .footer-links {
      display: flex;
      gap: 18px;
      flex-wrap: wrap;
    }

    .footer a {
      transition: color 240ms ease, text-shadow 240ms ease;
    }

    .footer a:hover,
    .footer a:focus-visible {
      color: var(--text);
      text-shadow: 0 0 14px rgba(189, 210, 230, 0.16);
    }

    .reveal {
      opacity: 1;
      transform: none;
    }

    @keyframes grain-shift {
      0% { transform: translate3d(0, 0, 0); }
      20% { transform: translate3d(-1%, 1%, 0); }
      40% { transform: translate3d(1%, -1.2%, 0); }
      60% { transform: translate3d(-0.8%, 0.6%, 0); }
      80% { transform: translate3d(0.6%, -0.6%, 0); }
      100% { transform: translate3d(0, 0, 0); }
    }

    @keyframes drift-stars {
      0% { transform: translate3d(0, 0, 0) scale(1); }
      50% { transform: translate3d(-1%, 1.2%, 0) scale(1.01); }
      100% { transform: translate3d(0, 0, 0) scale(1); }
    }

    @media (max-width: 900px) {
      .site-header {
        top: 14px;
        width: calc(100% - 20px);
        padding: 14px 16px;
      }

      .hero {
        padding-top: calc(var(--header-height) + 56px);
      }

      .hero-inner {
        grid-template-columns: 1fr;
        text-align: center;
      }

      .hero-copy {
        max-width: 100%;
      }

      .hero-tagline,
      .hero-summary {
        margin-left: auto;
        margin-right: auto;
      }

      .hero-actions {
        justify-content: center;
      }

      .footer-inner {
        justify-content: center;
        text-align: center;
      }
    }

    @media (max-width: 640px) {
      .site-header {
        border-radius: 16px;
      }

      .header-nav {
        gap: 10px 14px;
      }

      .header-nav a,
      .button,
      .ghost-link,
      .footer-inner {
        letter-spacing: 0.14em;
      }

      .hero-title {
        font-size: clamp(2.8rem, 15vw, 4.2rem);
      }

      .chapter-frame,
      .download-card {
        border-radius: 24px;
      }
    }

    @media (prefers-reduced-motion: reduce) {
      html {
        scroll-behavior: auto;
      }

      *,
      *::before,
      *::after {
        animation-duration: 0.01ms !important;
        animation-iteration-count: 1 !important;
        transition-duration: 0.01ms !important;
      }

      .reveal,
      .reveal.is-visible {
        opacity: 1;
        transform: none;
      }
    }
  </style>
</head>
<body>
  <canvas id="ambient" aria-hidden="true"></canvas>

  <header class="site-header" id="site-header">
    <div class="brand">
      <a class="brand-link" href="#top" aria-label="Back to top">
        <p class="brand-title">The Long Wake</p>
        <span class="brand-author">Joshua Szepietowski</span>
      </a>
    </div>
    <nav class="header-nav" aria-label="Primary">
      <a href="The%20Long%20Wake.pdf" download>Download PDF</a>
      <a href="The%20Long%20Wake.epub" download>Download EPUB</a>
      <a href="https://github.com/joshSzep/the-long-wake" target="_blank" rel="noreferrer">GitHub Repo</a>
      <a href="https://joshszep.com" target="_blank" rel="noreferrer">joshszep.com</a>
    </nav>
  </header>

  <main>
    <section class="hero" id="top">
      <div class="hero-inner reveal">
        <div class="cover-wrap" data-parallax="0.045">
          <div class="cover-shell">
            <img src="cover.png" alt="Cover of The Long Wake by Joshua Szepietowski">
          </div>
        </div>
        <div class="hero-copy">
          <p class="eyebrow">A novel by Joshua Szepietowski</p>
          <h1 class="hero-title">The Long Wake</h1>
          <p class="hero-tagline">One man wakes decades too soon, alone inside a ship built not to notice.</p>
          <p class="hero-summary">An interior science fiction novel of cryogenic failure, procedural indifference, and the slow return of motion in a future that has not arrived yet.</p>
          <div class="hero-actions">
            <a class="button" href="#chapter">Read Chapter One</a>
            <a class="ghost-link" href="The%20Long%20Wake.pdf" download>Download PDF</a>
            <a class="ghost-link" href="The%20Long%20Wake.epub" download>Download EPUB</a>
          </div>
        </div>
      </div>
    </section>

    <section class="chapter-section" id="chapter">
      <div class="section-shell reveal">
        <p class="section-label">Chapter One</p>
        <article class="chapter-frame">
          <div class="chapter-body">
EOF
printf '%s\n' "$CHAPTER_HTML"
cat <<'EOF'
          </div>
        </article>
      </div>
    </section>

    <section class="download-section">
      <div class="download-card reveal">
        <p class="section-label">Full Text</p>
        <h2>Read the full novel</h2>
        <p>The complete manuscript is available as a PDF or EPUB, with the same silence, weight, and distance carried through the rest of the journey.</p>
        <div class="hero-actions" style="justify-content:center; margin-top:28px;">
          <a class="button" href="The%20Long%20Wake.pdf" download>Download PDF</a>
          <a class="ghost-link" href="The%20Long%20Wake.epub" download>Download EPUB</a>
        </div>
      </div>
    </section>
  </main>

  <footer class="footer">
    <div class="footer-inner">
      <span>The Long Wake</span>
      <div class="footer-links">
        <a href="https://github.com/joshSzep/the-long-wake" target="_blank" rel="noreferrer">GitHub</a>
        <a href="https://joshszep.com" target="_blank" rel="noreferrer">joshszep.com</a>
      </div>
    </div>
  </footer>

  <script>
    (() => {
      const header = document.getElementById('site-header');
      const parallaxNodes = document.querySelectorAll('[data-parallax]');
      const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

      const updateHeader = () => {
        header.classList.toggle('is-dim', window.scrollY > 48);
      };

      updateHeader();
      window.addEventListener('scroll', updateHeader, { passive: true });

      document.querySelectorAll('a[href^="#"]').forEach((link) => {
        link.addEventListener('click', (event) => {
          const targetId = link.getAttribute('href');
          const target = targetId ? document.querySelector(targetId) : null;

          if (!target) {
            return;
          }

          event.preventDefault();
          target.scrollIntoView({ behavior: prefersReducedMotion ? 'auto' : 'smooth', block: 'start' });
        });
      });

      if (!prefersReducedMotion) {
        const updateParallax = () => {
          const scrollY = window.scrollY;
          parallaxNodes.forEach((node) => {
            const factor = Number(node.getAttribute('data-parallax')) || 0;
            node.style.transform = `translate3d(0, ${scrollY * factor}px, 0)`;
          });
        };

        updateParallax();
        window.addEventListener('scroll', updateParallax, { passive: true });
      }

      const canvas = document.getElementById('ambient');
      const context = canvas.getContext('2d', { alpha: true });

      if (!context) {
        return;
      }

      let animationFrameId = 0;
      let width = 0;
      let height = 0;
      let stars = [];
      let drift = 0;

      const createStars = () => {
        const count = Math.max(20, Math.min(54, Math.round((width * height) / 44000)));
        stars = Array.from({ length: count }, () => ({
          x: Math.random() * width,
          y: Math.random() * height,
          radius: Math.random() * 1.25 + 0.25,
          alpha: Math.random() * 0.18 + 0.04,
          velocity: Math.random() * 0.018 + 0.004
        }));
      };

      const resize = () => {
        const scale = Math.min(window.devicePixelRatio || 1, 2);
        width = window.innerWidth;
        height = window.innerHeight;
        canvas.width = Math.floor(width * scale);
        canvas.height = Math.floor(height * scale);
        canvas.style.width = `${width}px`;
        canvas.style.height = `${height}px`;
        context.setTransform(scale, 0, 0, scale, 0, 0);
        createStars();
      };

      const render = () => {
        context.clearRect(0, 0, width, height);

        const gradient = context.createRadialGradient(width * 0.5, height * 0.2, 0, width * 0.5, height * 0.5, Math.max(width, height) * 0.75);
        gradient.addColorStop(0, 'rgba(142, 173, 202, 0.025)');
        gradient.addColorStop(1, 'rgba(4, 7, 12, 0)');
        context.fillStyle = gradient;
        context.fillRect(0, 0, width, height);

        drift += 0.0024;

        stars.forEach((star, index) => {
          const offset = Math.sin(drift + index) * 10;
          const y = (star.y + drift * 10 * star.velocity + offset * 0.03) % (height + 20);
          const x = star.x + Math.cos(drift + index * 0.2) * 0.6;

          context.beginPath();
          context.fillStyle = `rgba(208, 224, 239, ${star.alpha})`;
          context.arc(x, y - 10, star.radius, 0, Math.PI * 2);
          context.fill();
        });

        if (!prefersReducedMotion) {
          animationFrameId = window.requestAnimationFrame(render);
        }
      };

      resize();
      window.addEventListener('resize', resize);

      if (prefersReducedMotion) {
        render();
      } else {
        animationFrameId = window.requestAnimationFrame(render);
      }

      window.addEventListener('beforeunload', () => {
        if (animationFrameId) {
          window.cancelAnimationFrame(animationFrameId);
        }
      });
    })();
  </script>
</body>
</html>
EOF
} > "$OUTPUT_HTML"

echo "Built website in: $OUTPUT_DIR"
