# Scanner Feature Tasks Checklist

- [x] Cache original image bytes in memory to avoid redundant re-reads on filter changes.
- [x] Implement high-quality CamScanner-style background removal (soft-thresholding filter to make background pure white and text dark/black).
- [x] Fix navigation race condition in `_handleSave()` (call `Navigator.pop` before triggering `onScanCompleted` so the bottom sheet opens correctly).
- [x] Translate all strings in the scanner view to support bilingual English/French translation.
- [x] Ensure that selecting option filters doesn't re-trigger image capturing/picking.
