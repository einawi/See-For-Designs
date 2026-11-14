# See For Designs

## What it does
See For Designs is an offline woodworking catalog that extracts and organizes designs directly from DWG CAD files stored on your phone. It locally analyzes CAD geometry to extract visual previews and bounding dimensions in millimeters, adding them to an alphabetical catalog. Users can inspect dimensions, resolve duplicate designs, and export printable client-ready PDF specification sheets.

## Screens
* **Catalog Screen (Home):** Displays an A–Z grid of design cards showing thumbnail previews, names, and dimensions (mm); includes a search bar, a link to the Trash screen, and a floating "+" button to pick DWG files from device storage.
* **Design Detail Screen:** Shows an expanded design preview, exact dimensions (W × H × D in mm), creation date, DWG file name, a "Move to Trash" button, and an "Export PDF" button.
* **Duplicate Conflict Dialog:** Appears when an imported design matches an existing item; displays side-by-side previews with options: "Keep Existing", "Replace with New", or "Keep Both".
* **Trash Screen:** Lists soft-deleted designs with options to "Restore" back to the catalog or "Delete Permanently".

## Data and features
* **Local Storage:** SQLite/Isar database storing design records (title, millimeter dimensions, file path, active/trashed state) alongside extracted thumbnail images and DWG files in app storage.
* **DWG Parsing & Alerts:** Parses CAD vectors locally to compute millimeter bounding dimensions and generate image previews. Dispatches a local completion notification upon success or a descriptive error dialog if the file is unreadable.
* **PDF Export:** Generates a clean, single-page printable PDF layout containing the design title, preview, and millimeter dimensions via the native share sheet.

## Look and feel
* **Theme:** Midnight dark mode with deep navy/slate backgrounds (`#0B0F19`, `#1E293B`) and electric blue accents (`#38BDF8`).
* **Typography & Icon:** Clean, monospaced-accented sans-serif typography for clear technical measurements. The app icon features a minimalist letter "S".

## Left out of the first version
* Cloud synchronization or multi-user accounts.
* Interactive 3D CAD orbit/layer editing inside the app.
* Direct DWG geometry manipulation or re-exporting back to CAD.

---
Made with AIy. Build it on GitHub from the AIy app, or run `flutter create --platforms android .` once and then `flutter run`.
