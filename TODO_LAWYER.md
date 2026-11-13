# TODO: Role "Përfaqësues Ligjor" (legal representative), view-only access to assigned lawsuits

Goal: a legal representative (përfaqësues ligjor) can **only view the lawsuits they are assigned to**.
Nothing else in the app is visible to them. Admins assign representatives. Nothing changes for the
3 existing roles / accounts.

## Decisions (answers from the legal team, 2026-11-12)
- **New 4th role**, shown as **"Përfaqësues Ligjor"**.
  Code: `enum role: { admin_developer: 0, admin: 1, operator: 2, legal_representative: 3 }`
  (no migration for the role itself: `role` is an integer column).
- **View only (Q1, Q2):** a legal representative can open their lawsuits and see all details,
  PDFs and existing comments. They **cannot** create, edit, delete, upload/hide PDFs or
  add comments. (Adding comments may come later: not now.)
- **Operator (Q3):** can **create** new lawsuits (as today), **cannot edit** them (as today).
  We make this explicit in `LawsuitPolicy#create?` instead of "no check at all".
- **Everything else hidden (Q4):** no Provizionimet page, no CSV export, no Admin area,
  no deleted lawsuits, no "Krijo Lëndë". Blocked on the server too (typing the URL redirects).
- **Navbar (Q4):** shows **only the categories** in which they have at least one lawsuit.
  Opening another category by URL redirects to Kryefaqja.
- **Kryefaqja (Q4):** one small overview with only their categories and counts, e.g.
  "Kontestet e Punës: 5", "Lëndët Penale: 3". Categories with 0 lawsuits are not shown.
  No assigned lawsuits at all → message "Nuk keni lëndë të caktuara."
- **Representatives shown (Q5):** the lawsuit page and the lawsuits table show the
  representatives' names (visible to all roles).
- **Users (Q7):** created by admin_developer in the Admin area (existing users page, new role in
  the dropdown).
- **Several representatives per lawsuit:** join table `lawsuit_representatives`
  (`lawsuit_id`, `user_id`, `is_primary`).
  - **One primary** ("Përfaqësuesi kryesor") per lawsuit, optional **secondary** ones
    ("Përfaqësues të tjerë") for big special cases. Usually only one.
  - Primary and secondary have the **same access** (view). "Primary" is only information,
    shown first / marked in the UI.
  - A lawsuit may have **no** representative (true for all 500–1000 existing ones at first).
- **Who assigns:** `admin` and `admin_developer`, in the lawsuit form (new and edit).
  The operator's create form doesn't show the field (an admin assigns afterwards).
- **Removing** a representative: they stop seeing the lawsuit immediately.
- **Who can be assigned (changed 2026-11-12):** every role **except Admin Developer**
  (Admin, Operator, Përfaqësues Ligjor). Access stays by **role**: being assigned only limits a
  Përfaqësues Ligjor; an assigned Operator still sees all and edits none, an assigned Admin still
  sees and edits all. The dropdowns show the role next to each name.
- Migration is **additive only** (one new empty table): safe on production.

## Steps (each step = its own git step)

### Step 1: Role "Përfaqësues Ligjor" (back end)
- [x] `User`: add `legal_representative: 3` to the role enum
- [x] `User#role_label`: "Admin Developer", "Admin", "Operator", "Përfaqësues Ligjor"
      (used instead of `role.titleize`)
- [x] `User.assignable_representatives` scope: active users of every role except admin_developer
      (for the dropdowns; was "only legal_representative" until the 2026-11-12 change)
- [x] `LawsuitPolicy#update?`: lists the roles that can edit (admin, admin_developer) instead of
      "everyone except operator", so the new role can't edit (same result for existing roles)

### Step 2: Role in the Admin area (front end)
- [x] Users form: the role dropdown uses `role_label`
- [x] Users list + dashboard counts per role: use `role_label`

### Step 3: Representatives (back end)
- [x] Migration `create_lawsuit_representatives`: `lawsuit_id`, `user_id` (both `null: false`,
      foreign keys), `is_primary` boolean (default `false`, `null: false`), timestamps;
      unique index on `[lawsuit_id, user_id]`; unique partial index on `lawsuit_id`
      `where: "is_primary"` (max. one primary per lawsuit). Named `is_primary`, not `primary`:
      PRIMARY is a reserved word in Postgres. `db/schema.rb` updated by hand (production
      doesn't dump it)
- [x] Model `LawsuitRepresentative` (`belongs_to :lawsuit`, `belongs_to :user`, validation: the
      user must not be admin_developer, `has_paper_trail` so "who assigned whom and
      when" is audited)
- [x] `Lawsuit`: `has_many :lawsuit_representatives, dependent: :destroy`,
      `has_many :representatives, through: :lawsuit_representatives, source: :user`,
      `primary_representative`, `secondary_representatives`
- [x] `Lawsuit#assign_representatives!(primary_id:, secondary_ids:)`: replaces the current
      assignments in one transaction (primary can't also be in secondary; unchanged rows are
      kept, so PaperTrail only records real changes)
- [x] `User`: `has_many :lawsuit_representatives`, `has_many :represented_lawsuits, through: ...`

### Step 4: Access rules (back end)
- [x] `LawsuitPolicy::Scope#resolve`: legal_representative →
      `scope.where(id: LawsuitRepresentative.where(user_id: user.id).select(:lawsuit_id))`
      (subquery: no duplicates, keeps the existing sorting); everyone else → `scope`
- [x] `LawsuitPolicy`: `index?`/`show?` true (the scope does the filtering);
      `create?` → everyone except legal_representative;
      `update?` → admin, admin_developer (unchanged meaning);
      `destroy?`, `destroy_pdf?` unchanged (already admin-only);
      new `assign_representatives?` → admin, admin_developer;
      new `comment?` → everyone except legal_representative
- [x] `LawsuitsController`:
  - `index`: lawsuits from `policy_scope(Lawsuit)` (pass the scope into `important_lawsuits` /
    `filter_by_params` instead of `kept` on the whole table); a legal_representative opening a
    category with none of their lawsuits → redirect to Kryefaqja
  - `show`: `policy_scope(Lawsuit).kept.find` (someone else's lawsuit → same redirect as today
    for "not found")
  - `new`/`create`: `authorize Lawsuit, :create?`; save representatives only if
    `assign_representatives?`
  - `edit`/`update`: unchanged rule (admins), plus saving representatives
- [x] `CommentsController#create`: `authorize lawsuit, :comment?` and only on a lawsuit from
      `policy_scope` (today anyone logged in can post a comment to any lawsuit id)
- [x] `ProvisionsController` (index, export_csv): block legal_representative (redirect + alert)
- [x] `HomeController`: data from `policy_scope(Lawsuit).kept`; for a legal_representative
      only categories with a count > 0
- [x] `ActiveStorageAccessControl::BlockHiddenFiles`: for a legal_representative, `head :not_found`
      unless the file belongs to one of their lawsuits (old PDF links of other lawsuits must
      not open)
- [x] `visible_categories` (in `ApplicationController`, `helper_method`): all categories, or
      for a legal_representative only those with their lawsuits (used by navbar + index check)
- [x] `LawsuitPdfFilesController#set_lawsuit`: lookup through `policy_scope(Lawsuit)`
- [x] Tested in Docker (rolled back): 43 checks as legal representative, admin_developer and
      operator (lists, URLs, PDFs, comments, create, assign/remove representatives)

### Step 5: Navbar + Kryefaqja (front end)
- [x] Navbar: loop over `visible_categories` instead of `Lawsuit.categories`
- [x] Navbar: "Provizionimet" hidden for legal_representative (Admin / deleted lawsuits are
      already admin_developer only)
- [x] Kryefaqja for a legal_representative: a simple list or one small chart,
      "Kategoria: N lëndë", each linking to the category; empty → "Nuk keni lëndë të caktuara."
      Other roles: the current charts, unchanged
- [x] Tested in Docker (rolled back): 15 checks (representative with 2 / 0 lawsuits,
      admin_developer, operator)

### Step 6: Representatives in the lawsuit form + display (front end)
- [x] `_form.html.erb` (only if `policy(@lawsuit).assign_representatives?`):
      "Përfaqësuesi kryesor" = single select (with blank) over `User.assignable_representatives` (label: "Name Surname (Role)");
      "Përfaqësues të tjerë" = one dropdown per person, "+ Shto përfaqësues" adds a dropdown,
      "×" removes one (empty dropdowns and duplicates are ignored when saving)
- [x] Show page: "Përfaqësuesi kryesor: Name Surname" + "Përfaqësues të tjerë: ..." (if any)
- [x] Lawsuits table: "Përfaqësuesi" column with the primary's name
      (+ "(+1)" when there are secondary ones)
- [x] View-only for a legal_representative: no "Krijo Lëndë" (`policy(Lawsuit).create?`),
      no "Ndrysho"/"Delete" (already policy-based), no comment form (there is none on the lawsuit page: comments are only added in
      the new/edit form, which they can't open; the server blocks it too, Step 4)
- [x] Form submit button "Ruaj Ndryshimet": `policy(@lawsuit).update?` instead of
      `!current_user.operator?`
- [x] Form fields in partial `lawsuits/_representatives_fields.html.erb`. Choices = active users
      (all roles except admin_developer) + anyone already assigned (a deactivated one is shown "(joaktiv)" so saving
      never drops them). After a validation error the chosen values stay selected.
- [x] Lawsuits list loads representatives with `preload` (no extra query per row)
- [x] Tested in Docker (rolled back): 29 checks (admin_developer form/save/clear/validation
      error, + / × rows, display, operator, legal representative)

### Step 6b: History of representatives (admins only), added 2026-11-12
- [x] No new table: `LawsuitRepresentative` already has `has_paper_trail`, so every add / remove /
      primary↔secondary switch is in `versions` (date + whodunnit)
- [x] `Lawsuit#representative_history`: rebuilds the periods from those versions (removed rows are found
      through the `lawsuit_id` in their "destroy" version). One row per period with the same role:
      who, Kryesor/Tjetër, from, to (or "aktual"), added by, changed/removed by
- [x] `LawsuitPolicy#view_representative_history?` = admin / admin_developer
- [x] Show page: "Historiku i përfaqësuesve (N)" opens a table under the representatives box;
      operators and legal representatives never see it
- [x] Tested in Docker (rolled back): 12 checks (add → switch → remove → add again, who/when,
      no mixing between lawsuits, visibility per role)
- History only exists from when this is deployed (nothing older to show, the feature is new)

### Step 6c: "Lëndët e Mia" for Admin + Operator, added 2026-11-12
- [x] Navbar item "Lëndët e Mia" right after Kryefaqja (only admin / operator, `LawsuitPolicy#mine?`;
      a legal representative already sees only their own lawsuits, admin_developer can't be assigned)
- [x] Route `GET /lawsuits/mine` → `LawsuitsController#mine`: non-archived lawsuits where the user is
      primary or secondary representative, all categories
- [x] Same table as the category pages (`_lawsuits_table`, `show_category: true`): "Kategoria" column
      instead of "Përfaqësuesi"
- [x] Filters as everywhere (Paditësi, Numri i Lëndës, Statusi "Kryesoret" = active + pending) +
      "Kategoria" (only on this page, only the user's own categories, "Të gjitha" = all)
- [x] Tested in Docker (rolled back): 21 checks (own primary + secondary, not others / archived,
      filters, operator view-only, legal rep + admin_developer blocked, category pages unchanged)

### Step 6d: Small UI changes, added 2026-11-12
- [x] Navbar: logo + "Aplikacioni Ligjor" is the link to Kryefaqja (tooltip), "Kryefaqjaa" row removed
- [x] Kryefaqja charts: whole-number ticks only (no 0.5)
- [x] `plaintiff_label` helper: Lëndët e Mia "Pala" when categories are mixed;
      Përmbarimore labels swapped: TK Kreditor → "Debitori", TK Debitor → "Kreditori" (table, filter, show, new/edit)
- [x] Filters: fields aligned at the bottom (long Penale label), new "Numri TK" search (title) on every lawsuits table
- [x] New court "Gjykata Administrative" (stored as text like the others, no migration). No Gjykata filter (not wanted)

### Step 6e: Category scopes for Përfaqësues Ligjor, added 2026-11-12
- [x] Decision: a Përfaqësues Ligjor can also see ALL lawsuits (read only) of chosen categories, e.g.
      both Përmbarimore ones, besides the lawsuits they are assigned to. Every category can be chosen.
      Other roles: not needed (they see everything already)
- [x] Migration `20261112130000_add_category_scopes_to_users`: `users.category_scopes` (string array,
      default []); `db/schema.rb` by hand. Existing users get [] (no change)
- [x] `User`: scopes cleaned, only valid category keys, cleared for every role except legal_representative
      (PaperTrail on User records changes)
- [x] `LawsuitPolicy::Scope`: assigned lawsuits OR category in `category_scopes` (one rule, so lists, show,
      navbar, Kryefaqja follow); PDFs (`active_storage_access_control.rb`) use the same scope
- [x] `visible_categories`: + scoped categories even with 0 lawsuits; Kryefaqja empty message only when
      nothing is visible
- [x] Admin → user form: "Qasje në kategori të plota" checkboxes, only shown for Përfaqësues Ligjor
      (hidden / shown with the role dropdown); users list shows "+ të gjitha: ..."
- [x] Tested in Docker (rolled back): 22 checks (save / validate scopes, navbar, Kryefaqja, all Kreditore
      lawsuits read only, archived hidden, edit / update blocked, own category still only own lawsuits,
      PDFs, scope removed, role change clears scopes, operators unchanged)
- [x] Kryefaqja for Përfaqësues Ligjor split in two: "Lëndët e mia" ("Lëndët ku jeni caktuar si përfaqësues
      ligjor.", assigned lawsuits only, counts + chart) and "Qasje në këto kategori" (blue, count = all
      lawsuits there). Only category access → no "Lëndët e mia"; nothing at all → "Lëndët e mia" + text +
      "Nuk keni lëndë të caktuara." Tested: 11 checks

### Review fixes (2026-11-12)
- [x] Double save of representatives (double click / two admins): normal message instead of an error page
- [x] Representative history: no JSON cast in SQL (old history rows in another format can't break the page)
- [x] One rule for "lawsuits this user represents": `Lawsuit.represented_by(user)` (policy, Kryefaqja,
      Lëndët e Mia); removed unused `User#represented_lawsuits`, `LawsuitRepresentative.primary/.secondary`
- Not changed (decided): representatives see provisions of lawsuits they can see; Kryefaqja counts all statuses

### Step 7: Verify in Docker
- [ ] Create 2 legal representative users in the Admin area
- [ ] As admin: assign user A as primary on 3 lawsuits in 2 categories, user B as secondary on
      one of them; names show on the lawsuit page and in the table
- [ ] As A: navbar shows only those 2 categories; Kryefaqja shows only those 2 with the right
      counts; lists show only the assigned lawsuits; lawsuit page shows PDFs and comments but
      no Ndrysho / Delete / comment form / Krijo Lëndë
- [ ] As A, by typing URLs: another lawsuit, another category, edit page, new lawsuit,
      Provizionimet, CSV export, /admin → all blocked; a PDF link of another lawsuit → 404
- [ ] As B: sees the shared lawsuit only
- [ ] Remove A from a lawsuit → it disappears for A; deactivate B → login blocked
- [ ] As operator: can create a lawsuit, cannot edit; sees everything as before
- [ ] As admin / admin_developer: everything as before (list, show, edit, PDFs, archive, users)
- [ ] Category scope (6e): give A "Përmbarimore" (both) → sees all Përmbarimore lawsuits read only,
      Kryefaqja shows "Lëndët e mia" + "Qasje në këto kategori"; remove it → gone
- [ ] "Lëndët e Mia" (6c) as admin / operator assigned to a lawsuit; history (6b) as admin

### Step 8: Deploy (together with TODO_COURTS.md, same branch)
- [ ] Commit, push, PR, merge into `main` (done by Ergon)
- [ ] On the server: courts check (TODO_COURTS.md Step 0, read only) and note the counts
- [ ] Backup on the server (pg_dump + rsync `storage/`, see the 2026-11-09 deploy)
- [ ] `git pull` → `sudo docker-compose build` (no `--pull`) → `down` → `up -d` →
      `tailwindcss:build` → `restart`
- [ ] 3 migrations run, none changes existing lawsuits: `lawsuit_representatives` (new empty table),
      `courts` (new table with the 12 courts), `users.category_scopes` (empty list for every user)
- [ ] Courts check again: same counts as before; Admin → Gjykatat shows 12 active courts (+ inactive
      ones only if the check found unknown names)
- [ ] Create the legal representative accounts in the Admin area, assign their lawsuits / categories
- [ ] Tell the legal team: CSV export now shows full court names ("Gjykata Themelore" instead of `themelore`)

## Later (not now)
- Legal representatives may add comments on their own lawsuits (only `comment?` changes).

## Notes
- Found while planning: the home charts count **archived (deleted) lawsuits** too
  (`HomeController` uses `Lawsuit.where`, not `Lawsuit.kept`). Step 4 fixes this for everyone,
  because the counts will come from `policy_scope(Lawsuit).kept`. The numbers on Kryefaqja may
  drop slightly after the deploy: that's the correct count.
- `assign_representatives!` uses `transaction(requires_new: true)`: if one chosen user is invalid
  (e.g. Admin Developer), nothing is changed, even when called inside another transaction.
