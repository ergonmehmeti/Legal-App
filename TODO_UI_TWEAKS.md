# TODO: Hide "Ndrysho" without edit rights + "Load more" comments

## Decisions
- "Ndrysho" (edit) is shown only to roles that can edit a lawsuit (`LawsuitPolicy#update?`:
  admin and admin_developer). Operators no longer see it.
- The edit page itself is also closed for those roles (typing the URL redirects back),
  so the button and the page follow the same rule.
- Details page: the 3 newest comments by default, "Shfaq më shumë" shows the rest.
- No database changes.

## Steps (each step = its own git step)

### Step 1: Hide "Ndrysho" without edit rights
- [x] Back end: `LawsuitsController#edit` uses `authorize` (same rule as saving)
- [x] Front end: "Ndrysho" in the lawsuits list and on the details page only if `policy(lawsuit).update?`

### Step 2: Comments: 3 by default, load more (front end)
- [x] Details page renders all comments (newest first), shows the first 3
- [x] "Shfaq më shumë (N)" button reveals the rest, "Shfaq më pak" hides them again

### Step 3: Verify in Docker
- [x] admin_developer / admin / operator: Ndrysho visibility, edit URL as operator
- [x] Lawsuit with 0, 3 and more than 3 comments
