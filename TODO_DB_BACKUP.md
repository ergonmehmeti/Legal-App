# TODO: Automatic backups to another place (off the server)

## Current state (2026-11-09)
- IT takes a snapshot of the whole server every **Monday**. Worst case, we lose up to 7 days of work.
- IT already backs up other databases (SQL Server on Windows) **to tape**.
- The app itself has **no** backups of its own (no script, no cron job).
- Manual backup from the deploy on 2026-11-09 is in `~/backups/` on the server:
  - `legal_app_20261109_1313.dump` (database, 1.1 MB): keep
  - `storage_20261109/` (PDFs, 31 GB): delete after the Monday snapshot of **2026-11-16**
    with `sudo rm -r ~/backups/storage_20261109`

## Goal
Every night, the database **and** the PDFs are backed up **on another machine / on tape**, not only
on this server. At most 1 day of work lost instead of 7.

## What gets backed up (facts for IT)

| What | Where on the server | Size | Changes |
|---|---|---|---|
| Database (PostgreSQL, `legal_app_production`) | runs on the host, not in Docker | ~1 MB | every day |
| Uploaded PDFs | `/home/prileg/LegalApp/Legal-App/storage/` | ~31 GB, 11,000+ files | new files daily, old ones never change |
| Config + secrets | `/home/prileg/LegalApp/Legal-App/.env` | tiny | rarely |
| App code | GitHub (`ergonmehmeti/Legal-App`) | — | already safe, no backup needed |

Server: Ubuntu Linux, user `prileg`. Data: legal case files with personal data, which must stay
inside Kosovo Telecom.

**Important:** don't back up PostgreSQL by copying its data folder (`/var/lib/postgresql`) while it
runs. That copy can be broken. The correct way is a **dump file** (`pg_dump`), which we create
every night (Step 2). IT then only backs up normal files.

## The plan

**Option A (preferred): use IT's existing backup system.**
IT already has backups and tapes for other systems. We make the data easy to back up: every night
a script writes the database dump to a fixed folder. IT adds that folder + the PDF folder to their
normal nightly backup (tape). IT already handles storage, tape rotation, off-site copies and
monitoring, so we don't build a second backup system.

**Option B (only if IT can't do A): our own backup to another machine.**
IT only gives us an empty place on another server/NAS, and we send encrypted backups there
ourselves with the tool **restic** (Step 5).

In both cases: **3-2-1 rule:** 3 copies (live server, IT snapshot, nightly backup),
on 2 different systems, 1 in another place.

## Steps

### Step 1: Message to IT
Send this (or say it in a meeting), then fill in the answers below.

> Hi,
>
> The Legal App server (Ubuntu, used by the legal department, ~1000 lawsuits) is currently
> covered only by the weekly Monday snapshot. If something goes wrong on a Friday, we lose a
> week of the legal team's work. I'd like to add a **nightly backup** to your existing backup
> system (like the SQL databases that go to tape).
>
> What needs to be backed up every night:
> - `/home/prileg/backups/db/` — a database dump file (PostgreSQL, ~1 MB) that a script on the
>   server creates every night at **01:00**. Please back it up **after 01:30**.
> - `/home/prileg/LegalApp/Legal-App/storage/` — uploaded PDF files, ~31 GB, 11,000+ files,
>   growing. Files never change after upload, so incremental backups are small.
> - `/home/prileg/LegalApp/Legal-App/.env` — configuration (contains passwords, treat as secret).
>
> No need to stop anything or install a database agent: the database is already a plain file.
>
> Questions:
> 1. Can you add these folders to your nightly backup (tape or other)? What do you need from
>    me on the server: a backup agent, an SSH/SFTP user, or a network share (SMB/NFS)?
> 2. How long are backups kept (days / weeks / months)?
> 3. Is a copy kept in another location (tapes stored off-site)?
> 4. How do I ask for a restore, and how long does it take? Can you restore a single file
>    (one PDF or the database dump), not only the whole server?
> 5. How many Monday snapshots do you keep, and has a restore of this server ever been tested?
> 6. Can we do a **test restore** together once the backup is running?
> 7. If you can't add it to your system: can you give me ~100 GB on another server/NAS with an
>    SSH/SFTP login, so I can send encrypted backups there myself?
>
> Thanks!

**Answers from IT:**
- [ ] Option A possible? ______ (agent / SFTP user / network share: ______)
- [ ] Retention: ______
- [ ] Off-site copy: ______
- [ ] How to ask for a restore + how long: ______
- [ ] Snapshots kept: ______ / restore ever tested: ______
- [ ] If option B: host ______, user ______, path ______

### Step 2: Nightly database dump on the server (needed for both options)
- [ ] Database password without typing it: create `~/.pgpass` with the line
      `localhost:5432:legal_app_production:legalapp:PASSWORD`, then `chmod 600 ~/.pgpass`
- [ ] Create `~/backup/db_dump.sh`:
```bash
#!/bin/bash
set -euo pipefail
DUMPS=/home/prileg/backups/db
mkdir -p "$DUMPS"
pg_dump -h localhost -U legalapp -Fc legal_app_production > "$DUMPS/legal_app_$(date +%Y%m%d_%H%M).dump"
find "$DUMPS" -name '*.dump' -mtime +14 -delete   # keep 14 days on the server
echo "$(date) DB DUMP OK"
```
- [ ] `chmod +x ~/backup/db_dump.sh`, run it once by hand, check `ls -lh ~/backups/db`
- [ ] `crontab -e` and add:
```
0 1 * * * /home/prileg/backup/db_dump.sh >> /home/prileg/backup/backup.log 2>&1
```
- [ ] Next morning: `tail ~/backup/backup.log` should end with `DB DUMP OK`

### Step 3 (Option A): IT adds the folders to their backup
- [ ] Do whatever IT asks for (install their agent / create a user / mount a share)
- [ ] IT confirms the first full backup is done (31 GB)
- [ ] The PDF folder belongs to root (Docker). If IT's backup user can't read it, ask them to run
      their agent as root, or give their user read access

### Step 4: Test a restore (with IT, then every few months)
A backup only counts once a restore has worked.
- [ ] Ask IT to restore yesterday's database dump into `/tmp/restore_test/`
- [ ] Load it into a **test** database (never over the real one) and compare:
```bash
createdb -h localhost -U legalapp legal_app_restore_test
pg_restore -h localhost -U legalapp -d legal_app_restore_test /tmp/restore_test/<file>.dump
psql -h localhost -U legalapp legal_app_restore_test -c "SELECT COUNT(*) FROM lawsuits;"
psql -h localhost -U legalapp legal_app_production   -c "SELECT COUNT(*) FROM lawsuits;"
dropdb -h localhost -U legalapp legal_app_restore_test
```
  The counts should match (or be close, depending on today's new lawsuits).
- [ ] Ask IT to restore one PDF, and open it
- [ ] Write down how long the restore took

### Step 5 (Option B only): Our own backup with restic
Only if IT can't do option A. IT gives a host, user and path on another machine.
- [ ] `sudo apt install restic`
- [ ] SSH key: `ssh-keygen -t ed25519 -f ~/.ssh/backup_key -N ""`, give the `.pub` file to IT,
      test with `ssh -i ~/.ssh/backup_key USER@BACKUP_HOST`
- [ ] restic password in `~/.restic_password` (`chmod 600`).
      **Store this password in a second place too (password manager / sealed envelope)!**
      Without it, the backups can't be opened. Not even by us.
- [ ] Create the repository once:
```bash
export RESTIC_REPOSITORY=sftp:USER@BACKUP_HOST:/PATH/legal_app
export RESTIC_PASSWORD_FILE=~/.restic_password
restic init
```
- [ ] Add to the end of `~/backup/db_dump.sh` (before the `echo`):
```bash
export RESTIC_REPOSITORY=sftp:USER@BACKUP_HOST:/PATH/legal_app
export RESTIC_PASSWORD_FILE=/home/prileg/.restic_password
restic backup /home/prileg/backups/db /home/prileg/LegalApp/Legal-App/storage /home/prileg/LegalApp/Legal-App/.env
restic forget --prune --keep-daily 7 --keep-weekly 4 --keep-monthly 12
```
- [ ] The first run copies 31 GB (slow). Afterwards only new files, which takes seconds to minutes.
- [ ] If it gets "permission denied" on `storage/`: put the cron job in `sudo crontab -e` instead
- [ ] Check with `restic snapshots` and `restic check`
- [ ] Restore test: `restic restore latest --target /tmp/restore_test`, then Step 4

### Step 6: Notice when it fails
A backup that silently stopped working is the most common problem.
- [ ] Every Monday: `tail ~/backup/backup.log` (put it in the calendar)
- [ ] Ask IT whether their monitoring alerts them when the backup of this server fails

## Not needed for now
- **Point-in-time recovery** (pgBackRest / WAL archiving): restore to any minute. Overkill for a
  1 MB database and 3 users. Nightly is enough.
- **Public cloud** (S3, Backblaze): only with IT/legal approval (personal data).
