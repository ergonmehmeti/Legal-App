# TODO: "Statusi Final i Lëndës"

Created 2026-11-13, branch `emehmeti/add_field_to_lawsuit`.

## Decisions (2026-11-13)
- New field on every lawsuit, **all categories**, always shown in the form, **optional** (can stay empty).
- Options: Aprovohet Padia / Aprovohet pjesërisht Padia / Refuzohet Padia.
- Only on the lawsuit page (Detajet), New and Edit. **Not** in the tables, filters or the CSV.

## Steps
- [x] Migration `20261113090000_add_final_status_to_lawsuits`: `lawsuits.final_status` (string, empty).
      Existing lawsuits stay empty, no data changes. `db/schema.rb` by hand
- [x] `Lawsuit::FINAL_STATUSES` (key stored, label shown: a label can be fixed later without touching
      data); empty = nil; only these 3 keys are accepted; `final_status_label`
- [x] Form (new / edit): dropdown after "Statusi i Lendes", empty choice "—" (also clears it)
- [x] Lawsuit page: box "Statusi Final i Lëndës" (label or N/A), same for every category
- [x] Permitted in `lawsuit_params`; editing stays admin only (policy unchanged)
- [x] Tested in Docker (rolled back): 38 checks (form in all 9 categories, save / show / edit per category,
      clear, unknown value rejected, not in the table)
- [x] Check in the browser (OK, 2026-11-13)
- [ ] Deploy: backup → `git pull` → `sudo docker-compose build` → `down` → `up -d` → `tailwindcss:build`
      → `restart` (1 migration, adds an empty column)
