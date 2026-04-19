param(
    [string]$CsvPath = ".\\comic_digital.csv",
    [string]$ContainerName = "comicrealmdb",
    [string]$DbName = "comicrealm",
    [string]$DbUser = "comicrealm"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $CsvPath)) {
    throw "CSV file not found at '$CsvPath'."
}

$containerCsvPath = "/tmp/comic_digital.csv"

Write-Host "Copying CSV into container..."
docker cp $CsvPath "${ContainerName}:$containerCsvPath" | Out-Null

$sql = @'
\set ON_ERROR_STOP on

-- Ensure default login users exist with ASP.NET Identity-compatible password hashes.
INSERT INTO users (email, password_hash, role, created_by, created_at, updated_at, is_active)
SELECT 'superadmin@comicrealm.com', 'AQAAAAIAAYagAAAAELsSL5L3Gjqz5rFN/f2hGAeDye0+NrpdcCqPEgwpLRNlM1YWPwsr/5fkUJF9YpMbMg==', 0, NULL, NOW(), NOW(), true
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'superadmin@comicrealm.com');

INSERT INTO users (email, password_hash, role, created_by, created_at, updated_at, is_active)
SELECT 'admin@comicrealm.com', 'AQAAAAIAAYagAAAAEIfUODokghnrLkzTCQOywjCFM1/f7s0B64DER2HNdl7dkLpVkEc1UOSAELOLDSXqtw==', 1, NULL, NOW(), NOW(), true
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'admin@comicrealm.com');

INSERT INTO users (email, password_hash, role, created_by, created_at, updated_at, is_active)
SELECT 'friend@comicrealm.com', 'AQAAAAIAAYagAAAAEIqeLBWYppTtuHBMub/pEiVXaxwZVSZA9BocEdxdfQl/FKSdOBVpkLuCJ9q8E4BVOQ==', 2, NULL, NOW(), NOW(), true
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'friend@comicrealm.com');

-- Staging table for raw CSV rows.
CREATE TABLE IF NOT EXISTS comics_import_raw (
    id text,
    serie text,
    number text,
    title text
);

TRUNCATE TABLE comics_import_raw;

\copy comics_import_raw (id, serie, number, title) FROM '/tmp/comic_digital.csv' WITH (FORMAT csv, HEADER true);

WITH before_count AS (
    SELECT COUNT(*)::bigint AS total_before FROM comics
),
creator AS (
    SELECT COALESCE(
        (SELECT user_id FROM users WHERE LOWER(email) = 'admin@comicrealm.com' LIMIT 1),
        (SELECT user_id FROM users WHERE LOWER(email) = 'superadmin@comicrealm.com' LIMIT 1),
        (SELECT user_id FROM users WHERE is_active = true ORDER BY user_id LIMIT 1)
    ) AS created_by_id
),
cleaned AS (
    SELECT
        LEFT(NULLIF(BTRIM(serie), ''), 255) AS serie,
        LEFT(NULLIF(BTRIM(number), ''), 50) AS number,
        LEFT(NULLIF(BTRIM(title), ''), 500) AS title
    FROM comics_import_raw
),
inserted AS (
    INSERT INTO comics (serie, number, title, created_by, created_at, updated_at)
    SELECT c.serie, c.number, c.title, cr.created_by_id, NOW(), NOW()
    FROM cleaned c
    CROSS JOIN creator cr
    WHERE cr.created_by_id IS NOT NULL
      AND c.serie IS NOT NULL
      AND c.number IS NOT NULL
      AND c.title IS NOT NULL
      AND NOT EXISTS (
          SELECT 1
          FROM comics x
          WHERE LOWER(BTRIM(x.serie)) = LOWER(c.serie)
            AND LOWER(BTRIM(x.number)) = LOWER(c.number)
            AND LOWER(BTRIM(x.title)) = LOWER(c.title)
      )
    RETURNING 1
)
SELECT
    (SELECT COUNT(*) FROM comics_import_raw) AS staging_rows,
    (SELECT COUNT(*) FROM inserted) AS inserted_rows,
    ((SELECT total_before FROM before_count) + (SELECT COUNT(*) FROM inserted)) AS total_comics;
'@

Write-Host "Running database seed SQL..."
$sql | docker exec -i $ContainerName psql -U $DbUser -d $DbName

Write-Host "Seeding finished."
