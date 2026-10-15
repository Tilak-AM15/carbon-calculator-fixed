
-- Repair the existing PostgreSQL emission_factors table.
-- This migration preserves existing rows and fills missing classifications.

ALTER TABLE IF EXISTS public.emission_factors
    ADD COLUMN IF NOT EXISTS category_code VARCHAR(32);

ALTER TABLE IF EXISTS public.emission_factors
    ADD COLUMN IF NOT EXISTS scope VARCHAR(32);

-- Restore category codes for known seeded factors.
UPDATE public.emission_factors
SET category_code = CASE
    WHEN factor_code ILIKE '%NATGAS%'
      OR name ILIKE '%natural gas%'
        THEN 'S1_STATIONARY'

    WHEN factor_code ILIKE '%DIESEL%'
      AND factor_code ILIKE '%S1%'
        THEN 'S1_MOBILE'

    WHEN factor_code ILIKE '%R134A%'
      OR name ILIKE '%R-134a%'
        THEN 'S1_FUGITIVE'

    WHEN factor_code ILIKE '%S2-ELEC-CONTRACTUAL%'
      OR factor_code ILIKE '%S2-ELEC-RESIDUAL%'
        THEN 'S2_MARKET'

    WHEN factor_code ILIKE '%S2-ELEC%'
        THEN 'S2_LOCATION'

    WHEN factor_code ILIKE '%S3-RAW%'
      OR factor_code ILIKE '%S3-SPEND-PROCUREMENT%'
        THEN 'CAT_1'

    WHEN factor_code ILIKE '%S3-CAPITAL%'
        THEN 'CAT_2'

    WHEN factor_code ILIKE '%S3-ENERGY-TD%'
        THEN 'CAT_3'

    WHEN factor_code ILIKE '%S3-FREIGHT%'
        THEN 'CAT_4'

    WHEN factor_code ILIKE '%S3-WASTE%'
        THEN 'CAT_5'

    WHEN factor_code ILIKE '%S3-TRAVEL%'
        THEN 'CAT_6'

    WHEN factor_code ILIKE '%S3-COMMUTING%'
        THEN 'CAT_7'

    WHEN factor_code ILIKE '%S3-LEASED%'
        THEN 'CAT_8'

    WHEN factor_code ILIKE '%S3-DOWNSTREAM%'
        THEN 'CAT_9'

    WHEN factor_code ILIKE '%S3-USE%'
        THEN 'CAT_11'

    WHEN factor_code ILIKE '%S3-EOL%'
        THEN 'CAT_12'

    ELSE COALESCE(NULLIF(BTRIM(category_code), ''), 'UNCLASSIFIED')
END
WHERE category_code IS NULL
   OR BTRIM(category_code) = '';

-- Derive the scope from a known category or factor identifier.
UPDATE public.emission_factors
SET scope = CASE
    WHEN category_code LIKE 'S1_%' THEN 'SCOPE_1'
    WHEN category_code = 'S2_LOCATION' THEN 'SCOPE_2'
    WHEN category_code = 'S2_MARKET' THEN 'SCOPE_2'
    WHEN category_code LIKE 'CAT_%' THEN 'SCOPE_3'

    WHEN factor_code ILIKE 'CLIM-S1-%' THEN 'SCOPE_1'
    WHEN factor_code ILIKE 'CLIM-S2-%' THEN 'SCOPE_2'
    WHEN factor_code ILIKE 'CLIM-S3-%' THEN 'SCOPE_3'

    ELSE COALESCE(NULLIF(BTRIM(scope), ''), 'SCOPE_UNKNOWN')
END
WHERE scope IS NULL
   OR BTRIM(scope) = '';

-- Existing records with missing classifications are explicitly marked,
-- rather than silently assigned an invented emission category.
UPDATE public.emission_factors
SET category_code = 'UNCLASSIFIED'
WHERE category_code IS NULL
   OR BTRIM(category_code) = '';

-- Make existing unknown classifications visible for later review.
UPDATE public.emission_factors
SET source_note = LEFT(
    CONCAT_WS(
        ' | ',
        NULLIF(source_note, ''),
        'Classification requires manual verification; do not use as a verified factor until reviewed.'
    ),
    1200
)
WHERE scope = 'SCOPE_UNKNOWN'
   OR category_code = 'UNCLASSIFIED';

-- Enforce the non-null constraints required by the Java entity.
ALTER TABLE public.emission_factors
    ALTER COLUMN scope SET NOT NULL;

ALTER TABLE public.emission_factors
    ALTER COLUMN category_code SET NOT NULL;
