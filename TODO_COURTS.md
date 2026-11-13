# TODO: Courts (Gjykatat) managed in the UI

Created 2026-11-12. Do it **after** the Përfaqësues Ligjor deploy (TODO_LAWYER.md Step 8), on its own branch.

## Goal
Add / rename / deactivate courts from the app, without a developer or a deploy.

## Today
- The list is hard-coded in `app/models/lawsuit.rb` (`enum court:`), 12 values.
- Each lawsuit stores the court's **full name as text** in `lawsuits.court` (e.g. "Gjykata Themelore").
- A name that is not in the list is still in the database but the app shows it as empty.
- The CSV export prints the enum key (e.g. `themelore`), not the name.

## Plan (safe way: no lawsuit data is converted)
- New table `courts`: `name` (unique), `active` (boolean), `position` (order in the dropdown).
  Filled once with the 12 current names, in the current order.
- `lawsuits.court` **stays a text column with the same values**. No `court_id`, no conversion of the
  ~700 live lawsuits.
- The dropdown reads active courts from the table; the lawsuit keeps storing the name.
- Deactivated court: hidden in the dropdown for new choices, old lawsuits still show the name
  (better than today: no more "empty").
- Renaming a court also updates the lawsuits with the old name (one transaction).
- PaperTrail on `Court` (who added / renamed / deactivated, when).

## Decisions (2026-11-12)
- Only **Admin Developer** manages courts, inside the Admin area (like Users).
- **No delete**, only deactivate (a court used by old lawsuits can never be lost).

## Steps (each step = its own git step)

### Step 0: Check live data (read only, on the server, before anything else)
- [ ] `sudo docker-compose exec -T app bin/rails runner 'p ActiveRecord::Base.connection.select_rows("SELECT court, COUNT(*) FROM lawsuits GROUP BY court ORDER BY 2 DESC")'`
- [ ] Every name must be one of the 12 names (or empty). Anything else: decide what to do with it
      first (add it as a court, or fix those lawsuits).

### Step 1: Courts table (back end)
- [x] Migration `20261112120000_create_courts` (name unique not null, active default true, position)
      + filled with the 12 current names (positions 10, 20, ... 120, same order as the old list)
- [x] Safety net in the migration: a name used by lawsuits but not in the list is added as an
      **inactive** court (position 1000), so nothing is hidden. Lawsuits are never changed.
- [x] `db/schema.rb` by hand (production does not dump it), version 2026_11_12_120000
- [x] Model `Court`: name cleaned (extra spaces), present, unique (any case), max 150;
      `scope :active`, `scope :ordered`; `has_paper_trail`; destroy is blocked;
      rename also renames it in the lawsuits (`after_update`, same transaction); `lawsuits_count`
- [x] Migrated locally; tested in Docker (rolled back): 12 checks (rename → lawsuits follow, other
      lawsuits untouched, PaperTrail, duplicates, destroy blocked, deactivate, safety net)
- Note: the `enum court` in Lawsuit is still used until Step 2

### Step 2: Lawsuit uses the table (back end + form)
- [x] Removed `enum court:` from `Lawsuit`. Empty court = nil. A newly chosen court must be an active
      court (`court_must_be_active`); an old value (e.g. deactivated later) stays valid while unchanged
- [x] `_form.html.erb`: options = `Court.active.ordered` names + the lawsuit's current court even if
      deactivated (value = name, saved as text like before)
- [x] Plain text instead of `enum_value(:court)`: `_lawsuits_table`, `categories/_lendet_arbitrazhit_form`,
      `_lendet_permbarimore_form`, `_kontestet_palet_treta_form`, `_kontestet_punes_form`
- [x] CSV export: no code change, `lawsuit.court` now gives the full name ("Gjykata Themelore")
      instead of the key (`themelore`). Tell the legal team (small visible change)
- [x] Tested in Docker (rolled back): 17 checks (table / show / edit / new, save, unknown court rejected,
      empty → nil, deactivated court kept on its lawsuit but not offered to others, rename, CSV)
- Same as before: the court dropdown has no empty choice once a court is set (`prompt` only shows when empty)

### Step 3: Admin page "Gjykatat" (front end)
- [x] Routes `admin/courts` (index, new, create, edit, update, `toggle_active`). No destroy route
- [x] `Admin::CourtsController` (admin_developer only via `Admin::BaseController`)
- [x] List: Renditja, Emri, Lëndë (count, also archived), Statusi, Ndrysho / Çaktivizo / Aktivizo
      (with a confirm that says how many lawsuits keep the name)
- [x] Form (new / edit): Emri + Renditja (new = at the end, last + 10); edit shows how many lawsuits use
      it and that a rename changes them too; notice after rename says how many lawsuits were renamed
- [x] Admin dashboard: "Gjykatat" card (total, aktive, joaktive) + "Menaxho Gjykatat"
- [x] Error messages in Albanian (`config/locales/en.yml` court / lawsuit.court + messages in `Court`)
- [x] Tested in Docker (rolled back): 20 checks (admin / operator / legal rep blocked, list, create,
      order in the lawsuit dropdown, duplicate, rename → lawsuits + PaperTrail, deactivate / activate)

### Step 4: Verify in Docker
- [x] Old lawsuits show the same court as before (table, show, edit, CSV)
- [x] Add a court → shows in the dropdown; deactivate → gone from the dropdown, old lawsuits still show it
- [x] Rename → lawsuits with the old name show the new one; PaperTrail has the change
- Checked by the user in the browser on 2026-11-12: OK

### Review fixes (2026-11-12)
- [x] Capitals ignored everywhere: unique index on `LOWER(name)` (`index_courts_on_lower_name`), the
      migration's safety net skips spelling variants of known courts (adds an unknown name only once),
      `Court.lawsuits_named` / `lawsuits_count` and the Admin counts ignore capitals, a rename also fixes
      lawsuits with another spelling. Tested: 8 checks

### Step 5: Deploy
- [ ] Backup first (pg_dump + rsync storage, as in the deploy checklist)
- [ ] Step 0 query again right before deploying
- [ ] `git pull` → `sudo docker-compose build` → `down` → `up -d` → `tailwindcss:build` → `restart`
- [ ] Step 0 query again after: same counts as before (nothing in lawsuits changed)
