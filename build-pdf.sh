#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANUSCRIPT="$SCRIPT_DIR/MANUSCRIPT.md"
BUILD_MANUSCRIPT_SCRIPT="$SCRIPT_DIR/build-manuscript.sh"
COVER_IMAGE="$SCRIPT_DIR/cover.png"
OUTPUT_PDF="$SCRIPT_DIR/The Long Wake.pdf"

if ! command -v pandoc >/dev/null 2>&1; then
    echo "Error: pandoc is required but was not found in PATH." >&2
    exit 1
fi

if ! command -v pdflatex >/dev/null 2>&1; then
    echo "Error: pdflatex is required but was not found in PATH." >&2
    exit 1
fi

if [ ! -f "$BUILD_MANUSCRIPT_SCRIPT" ]; then
    echo "Error: missing build script: $BUILD_MANUSCRIPT_SCRIPT" >&2
    exit 1
fi

if [ ! -f "$COVER_IMAGE" ]; then
    echo "Error: missing cover image: $COVER_IMAGE" >&2
    exit 1
fi

bash "$BUILD_MANUSCRIPT_SCRIPT"

if [ ! -f "$MANUSCRIPT" ]; then
    echo "Error: manuscript build did not produce $MANUSCRIPT" >&2
    exit 1
fi

TMP_DIR="$(mktemp -d)"
PDF_BODY="$TMP_DIR/manuscript-for-pdf.md"
LATEX_HEADER="$TMP_DIR/header.tex"
LATEX_BEFORE_BODY="$TMP_DIR/before-body.tex"

cleanup() {
    rm -rf "$TMP_DIR"
}

trap cleanup EXIT

awk '
/^# The Long Wake[[:space:]]*$/ {
    next
}

/^## / {
    part_title = substr($0, 4)
    printf("\\part*{%s}\n", part_title)
    printf("\\thispagestyle{empty}\n")
    printf("\\markboth{}{}\n\n")
    next
}

/^### / {
    chapter_title = substr($0, 5)
    printf("\\chapter*{%s}\n", chapter_title)
    printf("\\markboth{%s}{%s}\n\n", chapter_title, chapter_title)
    next
}

/^---[[:space:]]*$/ {
    next
}

{
    print
}
' "$MANUSCRIPT" > "$PDF_BODY"

cat > "$LATEX_HEADER" <<'EOF'
\usepackage[T1]{fontenc}
\usepackage[utf8]{inputenc}
\usepackage{mathpazo}
\usepackage{graphicx}
\usepackage{xcolor}
\usepackage{geometry}
\usepackage{fancyhdr}
\usepackage{hyperref}
\usepackage{titlesec}

\geometry{
  paperwidth=6in,
  paperheight=9in,
  top=0.85in,
  bottom=0.9in,
  inner=0.85in,
  outer=0.75in,
  headheight=14pt,
  headsep=18pt,
  footskip=24pt
}

\definecolor{chapterink}{HTML}{22313F}

\linespread{1.08}
\setlength{\parindent}{1.25em}
\setlength{\parskip}{0pt}
\clubpenalty=10000
\widowpenalty=10000
\displaywidowpenalty=10000
\raggedbottom

\pagestyle{fancy}
\fancyhf{}
\fancyhead[LE,RO]{\thepage}
\fancyhead[LO,RE]{\nouppercase{\leftmark}}
\renewcommand{\headrulewidth}{0.4pt}
\renewcommand{\footrulewidth}{0pt}

\fancypagestyle{plain}{
  \fancyhf{}
  \fancyhead[LE,RO]{\thepage}
  \fancyhead[LO,RE]{\nouppercase{\leftmark}}
  \renewcommand{\headrulewidth}{0.4pt}
  \renewcommand{\footrulewidth}{0pt}
}

\titleformat{\part}[display]
  {\normalfont\huge\bfseries\color{chapterink}}
  {}
  {0pt}
  {\centering}

\titlespacing*{\part}{0pt}{0pt}{3\baselineskip}

\titleformat{\chapter}[display]
  {\normalfont\LARGE\bfseries\color{chapterink}}
  {}
  {0pt}
  {\centering}

\titlespacing*{\chapter}{0pt}{0pt}{2\baselineskip}

\hypersetup{
  pdftitle={The Long Wake},
  pdfauthor={},
  colorlinks=false,
  hidelinks
}
EOF

cat > "$LATEX_BEFORE_BODY" <<'EOF'
\newgeometry{margin=0in}
\thispagestyle{empty}
\noindent\includegraphics[width=\paperwidth,height=\paperheight]{cover.png}
\restoregeometry
\clearpage
\pagenumbering{arabic}
\setcounter{page}{1}
EOF

(
    cd "$SCRIPT_DIR"
    pandoc "$PDF_BODY" \
        --from markdown+raw_tex \
        --standalone \
        --pdf-engine=pdflatex \
        --include-in-header "$LATEX_HEADER" \
        --include-before-body "$LATEX_BEFORE_BODY" \
        --variable documentclass=book \
        --variable classoption=openany \
        --metadata lang=en-US \
        --output "$OUTPUT_PDF"
)

echo "Built PDF: $OUTPUT_PDF"
