#!/usr/bin/env bash
set -euo pipefail

INPUT="content/resume/_index.md"
OUTPUT_DIR="static/downloads"
BASENAME="Ted-Strall-Resume"

mkdir -p "$OUTPUT_DIR"

if ! command -v pandoc &>/dev/null; then
  echo "❌ pandoc not found. Install it from https://pandoc.org"
  exit 1
fi

echo "📄 Generating resume formats..."

# DOCX
pandoc "$INPUT" -o "$OUTPUT_DIR/${BASENAME}.docx"
echo "✅ DOCX generated"

# TXT
pandoc "$INPUT" -t plain --wrap=none -o "$OUTPUT_DIR/${BASENAME}.txt"
echo "✅ TXT generated"

# PDF (optional)
if command -v xelatex &>/dev/null; then
  pandoc "$INPUT" \
    --pdf-engine=xelatex \
    --template="$(dirname "$0")/resume-template.tex" \
    -o "$OUTPUT_DIR/${BASENAME}.pdf"
  echo "✅ PDF generated using xelatex"
else
  echo "⚠️  PDF skipped: xelatex not found. Install TeX engine for PDF support."
fi

echo "🎉 All available formats generated!"
