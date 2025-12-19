# Pre-Production Cleanup Instructions

## 🗑️ Temporary Content to Remove

This document explains how to remove all temporary/personal content before releasing the app to
production.

---

## Quick Checklist

Before releasing to Play Store / App Store:

- [ ] Remove 'Rhyl Specific' section from `menu_items.dart`
- [ ] Remove 'Photos - User' section from `menu_items.dart`
- [ ] Delete `assets/temp/` folder
- [ ] Remove temp assets line from `pubspec.yaml`
- [ ] Delete `lib/temp_content_to_remove.dart`
- [ ] Delete this file (`CLEANUP_INSTRUCTIONS.md`)
- [ ] Run `flutter clean`
- [ ] Test app thoroughly
- [ ] Verify no broken images

---

## Step-by-Step Instructions

### 1️⃣ Edit `lib/screens/menu_items.dart`

**Remove Section 1: 'Rhyl Specific' (lines ~335-384)**

Delete everything from:

```dart
// ============================================================================
// TEMPORARY SECTION - REMOVE BEFORE PRODUCTION
```

To (and including):

```dart
// ============================================================================
// END OF TEMPORARY SECTION - 'Rhyl Specific'
// ============================================================================
```

**Remove Section 2: 'Photos - User' (lines ~414-467)**

Delete everything from:

```dart
// ============================================================================
// TEMPORARY SECTION - REMOVE BEFORE PRODUCTION
```

To (and including):

```dart
// ============================================================================
// END OF TEMPORARY SECTION - 'Photos - User'
// ============================================================================
```

---

### 2️⃣ Delete the Assets Folder

Delete the entire folder:

```
assets/temp/
```

This contains all the Rhyl-specific and personal test images.

---

### 3️⃣ Edit `pubspec.yaml`

Remove the temp assets line (line ~74):

**BEFORE:**

```yaml
assets:
  - assets/
  - assets/displayimages/
  - assets/temp/  # TEMPORARY - Remove before production
```

**AFTER:**

```yaml
assets:
  - assets/
  - assets/displayimages/
```

---

### 4️⃣ Delete Temporary Files

Delete these files:

- `lib/temp_content_to_remove.dart`
- `CLEANUP_INSTRUCTIONS.md` (this file)

---

### 5️⃣ Clean and Test

```bash
flutter clean
flutter pub get
flutter run
```

**Test checklist:**

- ✅ App launches without errors
- ✅ All remaining lesson categories work
- ✅ No broken image references
- ✅ Upload Images functionality works
- ✅ Category creation works
- ✅ Backup/Restore works
- ✅ No references to Rhyl or personal content

---

## What Remains After Cleanup

After cleanup, users will have:

### Built-in Categories:

1. In Car
2. Moving off / Junctions
3. Roundabouts
4. Maneuvers
5. Driving
6. Blank Sheets
7. Misc Sheets

### User Features:

- ✅ Upload custom images
- ✅ Create custom categories
- ✅ Organize images by category
- ✅ Backup/restore functionality
- ✅ Share images between devices

---

## Notes

- The temp images are YOUR personal teaching materials from Rhyl area
- They're safe to delete - users will create their own custom content
- The app's upload/category system will work perfectly without them
- The built-in lesson images remain intact

---

## Questions?

If unsure about any step, the code comments in `menu_items.dart` clearly mark what to remove!

---

**Remember:** Once you remove this content and test, you're ready for production! 🚀
