# System-Hardening-And-Secure-Virtual-Systems-V2
The improved less vibed version of System-Hardening-And-Secure-Virtual-Systems

## Environment Setup

Remove the .example from `.env.example` and update it with the database name, username and password before running Docker Compose. The `.env` file is ignored by git and is used for local configuration only.

## Start With Automatic Seeding

When `comic_digital.csv` is present in the repository root, starting Docker Compose now automatically:
- migrates the database
- seeds default users
- imports comics from the CSV

Run from the repository root:

```powershell
docker compose up --build
```

## Seed Database (Single Script)

If you want to run seeding manually (or rerun it), use:

```powershell
.\scripts\seed-db.ps1
```

What this does:
- Ensures default users exist (`superadmin`, `admin`, `friend`)
- Loads `comic_digital.csv` into a staging table
- Inserts cleaned comic records into `comics`
- Skips blank records and existing duplicates
