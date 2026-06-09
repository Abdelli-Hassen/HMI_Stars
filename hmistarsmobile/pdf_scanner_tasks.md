# PDF Scanner Improvement Tasks

## Problems to Fix
- [ ] PDF has photo background (0.08 opacity image bleed) → should be pure white
- [ ] Current B&W filter uses simple global threshold → poor quality, loses table lines
- [ ] OCR text positioned incorrectly → layout broken, tables missing
- [ ] PDF preview shows background instead of clean document
- [ ] No invisible OCR text layer for searchability

## Implementation Plan

### Task 1 — Remove background image from PDF
- Remove the `pw.Positioned` background image (0.08 opacity) from the PDF page
- PDF should start with a pure white A4 page

### Task 2 — Implement proper adaptive thresholding (Sauvola method)
- Use integral image (summed area table) for O(n) performance
- Local neighborhood comparison: pixel darker than local mean × (1 - k) → black, else white
- Window size: 31px, k = 0.15
- Result: pure white background, crisp dark text, visible table borders/lines
- Replace the current simple global threshold in the 'bw' filter

### Task 3 — Fix PDF generation (clean white A4)
- White A4 background (no image background at all)
- Full-bleed thresholded image (fills page, fits proportionally)
- No opacity tricks

### Task 4 — Add invisible OCR text layer
- Run ML Kit OCR after processing
- Add text blocks as invisible (white color, opacity=0) overlay on top of image
- Makes PDF searchable while looking clean visually

### Task 5 — Better PDF preview in scanner
- Preview should show the adaptive threshold result for 'bw' filter
- Not just the globally thresholded version

### Task 6 — Update handbook
- Mark all tasks complete in scanner_tasks.md

## Status
- [ ] Task 1: Remove background image from PDF
- [ ] Task 2: Adaptive thresholding implementation
- [ ] Task 3: Clean white A4 PDF
- [ ] Task 4: Invisible OCR text layer
- [ ] Task 5: Preview accuracy
- [ ] Task 6: Handbook update
