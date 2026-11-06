# TODO: Delete (hide) PDFs + PDF links require login

Goal: a wrongly uploaded PDF can be removed from a lawsuit **without losing it**.
"Delete" hides the file; the admin_developer can still see it, with who, when and why, and restore it.

## Decisions
- **Who can delete (hide) a PDF:** whoever can edit the lawsuit, i.e. `admin` and `admin_developer`
  (same rule as `LawsuitPolicy#update?`; operators cannot).
- **A reason is required.** Only `admin_developer` sees it.
- **Who sees deleted PDFs and can restore them:** only `admin_developer`.
- **Nothing is physically deleted:** the file stays on disk; it is moved from `pdf_files`
  to a hidden list `deleted_pdf_files`. Existing PDFs are not touched.
- **PDF links require login.** Hidden PDFs open only for `admin_developer`, even from old links.

## Steps (each step = its own git step)

### Step 1: Delete / restore PDF (back end)
- [x] Migration: `pdf_file_deletions` (lawsuit, attachment, deleted_by user, reason, timestamps)
- [x] `PdfFileDeletion` model (+ PaperTrail)
- [x] `Lawsuit`: `has_many_attached :deleted_pdf_files`, `hide_pdf!` / `restore_pdf!`
- [x] `LawsuitPolicy`: `destroy_pdf?` (= can edit), `restore_pdf?` / `view_deleted_pdfs?` (admin_developer)
- [x] `LawsuitPdfFilesController#destroy` (reason required) and `#restore`
- [x] Routes

### Step 2: Delete PDF (front end)
- [x] "Fshi" button next to each PDF in **Ndrysho** (edit form), only for users who can edit the lawsuit
- [x] Confirmation popup with required reason (`lawsuits/_pdf_delete_modal`, rendered outside the lawsuit form)

### Step 3: Deleted PDFs for admin_developer (front end)
- [x] "Dokumentet e Fshira" section on the lawsuit page: file, deleted by, when, reason
- [x] "Rikthe" (restore) button

### Step 4: PDF links require login (back end)
- [x] All `/rails/active_storage/...` links: not logged in → login page
- [x] Hidden PDFs: only admin_developer can open them (others get 404), even from old links

### Step 5: Verify in Docker
- [x] `docker-compose build && docker-compose up -d` (runs the migration)
- [x] Test as admin_developer, admin (temporary test user, rolled back) and operator; test PDF link while logged out

### Step 6: Archived (deleted) lawsuits and their PDFs
- [x] PDFs of an archived lawsuit open only for admin_developer (others get 404, even from old links)
- [x] Archive page shows the lawsuit's hidden PDFs too (who, when, reason), read-only
- [x] Archived lawsuits cannot be edited or saved by typing the URL (`Lawsuit.kept` in edit/update)

## Later / optional
- Server-side PDF checks (only PDF content type, max file size)
