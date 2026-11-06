# TODO: Admin Dashboard & User Management

Goal: let the **admin_developer** create, edit and deactivate users from the app
(no more Rails console / `reset_password.sh`), and let every user change their own password.

## Decisions
- Only `admin_developer` can access the Admin area (checked on the server, not only hidden in the nav).
- Users are **never deleted**: they are **deactivated** (cannot log in). Their comments, deleted-lawsuit
  records and PaperTrail history stay linked.
- `kt_id` = **Kosovo Telecom employee ID**: required, positive integer, **unique**.
- `role` becomes **required** (removes the "no role = can edit" gap).
- Password:
  - **On create** (by admin): Devise default, min **6** characters (e.g. `123456` is allowed).
  - **On edit** (by admin or by the user themselves): min **8** characters.
- An admin_developer cannot deactivate themselves or remove their own admin_developer role (no lockout).

## Steps (each step = its own git step)

### Step 1: Admin Dashboard
- [x] `Admin::BaseController`: only `admin_developer`, otherwise redirect with an alert
- [x] `/admin` dashboard page: cards for **Users** (active/inactive count) and **Deleted Lawsuits**
- [x] Nav link **Admin** (only for admin_developer)

### Step 2: Users (back end)
- [x] Migration: `active` boolean (default `true`, not null), unique index on `kt_id`
- [x] `User` model: role required, `kt_id` unique, min 8 password on update
- [x] `UserPolicy` (admin_developer only)
- [x] `Admin::UsersController`: index, new, create, edit, update (blank password = keep the old one)
- [x] Routes under `/admin/users`

### Step 3: Users (front end)
- [x] Users list: name, surname, email, KT ID, role, status, "Ndrysho"
- [x] Create/edit form (role dropdown, "ID e Punonjësit (KT)", password + confirmation)
- [x] Validation errors shown in the form

### Step 4: Deactivation (back end)
- [x] Devise `active_for_authentication?`: inactive users cannot log in (clear message)
- [x] Activate / deactivate action, blocked for your own account

### Step 5: Deactivation (front end)
- [x] Activate/Deactivate button + status badge in the users list
- [x] Inactive users visually marked

### Step 6: Change own password (back end)
- [x] `ProfilesController#edit/update`: requires current password, new one min 8 characters

### Step 7: Change own password (front end)
- [x] "Ndrysho Fjalëkalimin" page, linked from the user name at the bottom of the nav

### Step 8: Verify in Docker
- [x] `docker-compose build && docker-compose up -d` (runs the migration)
- [x] Test as admin_developer and operator; test an inactive user login
- [ ] Test as `admin` (no admin user in the Docker/Postgres DB yet; create one from the Users screen)

## Later / optional (not in this TODO)
- Password complexity (letter + number)
- Lock account after 5 failed logins (`lockable`)
- Auto logout after 30 min idle (`timeoutable`)
- New role **Përfaqësues** (lawyer) for requests #6–7
