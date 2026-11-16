# TODO: HTTPS + a proper name for the app

Created 2026-11-13. Email to IT **sent 2026-11-13** (Step 1).
**On hold until December 2026:** IT has yearly certificate licenses, renewed in December; decided with IT
to issue our certificate with the new license. Then fill in Step 2 and we do the rest together.

## Today
- The app runs with Puma (`rails server`) **directly** on port 8080, over **plain HTTP**:
  `http://10.11.254.142:8080/`
- Everything (also passwords at login) goes over the network **unencrypted**.
- `docker-compose.yml`: `ports: "8080:3000"` (open to the whole network);
  `config/environments/production.rb`: `force_ssl = false`.

## Goal
- `https://legalapp.kosovotelecom.local` (name asked from IT) and `https://10.11.254.142`, lock in the browser,
  no warnings.
- Nginx in front of the app (HTTPS on 443, HTTP 80 → redirect to HTTPS); port 8080 closed, so the only
  way in is HTTPS.
- Rails secure mode: login cookies only over HTTPS, only our name / IP accepted.
- Firewall: the company firewall already keeps the app inside the local network (decided 2026-11-13:
  no extra server firewall needed).

## Step 1: Message to IT
- [x] Sent 2026-11-13 by Ergon, with these changes to the draft below: name **`legalapp.kosovotelecom.local`**;
      asked IT whether we create the private key / CSR or they send it; added info: internal app, users
      created by the admin (no AD), users change their own password, 10–15 colleagues of the legal office
      (2–3 colleagues for about a year so far).

Draft (for reference):

> Përshëndetje,
>
> Për aplikacionin tonë të brendshëm "Aplikacioni Ligjor" në serverin **10.11.254.142**, duam të kalojmë
> nga HTTP në **HTTPS**. A mund të na ndihmoni me këto:
>
> 1. **DNS:** një DNS record të brendshëm, p.sh. `ligjore.kosovotelecom.local` (ose sipas emërtimit që
>    përdorni ju) → `10.11.254.142`.
> 2. **SSL certificate** nga Internal CA i kompanisë, për emrin DNS dhe IP-në `10.11.254.142`, në format
>    PEM, bashkë me CA chain. Për private key / CSR, veproni si e keni procedurën ju; ne mund ta krijojmë
>    edhe CSR në server nëse ju duhet.
> 3. Sa kohë vlen certificate dhe si bëhet renewal?
>
> Faleminderit,
> Ergon Mehmeti

## Step 2: IT's answers (fill in, then tell Claude "IT answered, see TODO_HTTPS.md")
- [ ] DNS name: ______________________________ (asked: legalapp.kosovotelecom.local; works from a PC? `ping <name>` → 10.11.254.142: ___)
- [ ] Private key: IT sends it / IT wants a CSR from us: ______
      (if CSR: who / where to send it: ______)
- [ ] Certificate files received (certificate, CA chain, key if from IT): ______ (where saved: ______)
- [ ] Valid until: ____-__-__   Renewal: how / who: ______

## Step 3: Code (Claude prepares on this branch, tested locally)
- [ ] Nginx container in `docker-compose.yml`: 443 with the certificate, 80 → redirect to HTTPS,
      proxy to the app; upload limit big enough for PDFs (`client_max_body_size`)
- [ ] App port 8080 no longer open to the network (only Nginx reaches the app)
- [ ] `production.rb`: `assume_ssl` + `force_ssl` (secure cookies, HSTS), `config.hosts` = name + IP
- [ ] Local test on the Mac with a self-signed test certificate (browser warning is OK only locally)

## Step 4: On the server (step by step with Claude)
- [ ] If IT wants a CSR: create key + CSR on the server (command from Claude), send the `.csr` to IT
- [ ] Put the certificate files in the agreed folder, private key readable only by root (`chmod 600`)
- [ ] Backup (pg_dump + rsync storage, as in every deploy)
- [ ] `git pull` → `sudo docker-compose build` → `down` → `up -d` → `tailwindcss:build` → `restart`
- [ ] Test from a PC: `https://10.11.254.142` and `https://<name>`: lock (no warning), login works,
      PDFs open, `http://...` redirects to HTTPS, `http://...:8080` no longer answers
- [ ] Tell the users the new address

## Step 5: Afterwards
- [ ] Calendar reminder 1 month before the certificate expires (date from Step 2), renewal with IT,
      then replace the files on the server and `sudo docker-compose restart nginx`

## Also on this branch (deploy together with HTTPS)
- [x] CSV export (Provizionimet → "Eksporto Provizionimet në CSV"): Kategoria and Statusi as readable names
      ("Kontestet e Punës", "Aktive") instead of codes (`kontestet_punes`, `active`). Court names were
      already full names since the courts change. Tested locally: no codes left
