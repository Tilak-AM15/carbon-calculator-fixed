-- Repair the two schema mismatches confirmed in Render logs.
-- This is a new migration: do not edit V1, V2, V3, or V4.

-- The current EmissionFactor entity maps this boolean, but older databases may not have it.
ALTER TABLE IF EXISTS public.emission_factors
    ADD COLUMN IF NOT EXISTS is_market_based_alternative BOOLEAN;

-- Normalize any pre-existing NULL values before enforcing the entity's default expectation.
UPDATE public.emission_factors
SET is_market_based_alternative = FALSE
WHERE is_market_based_alternative IS NULL;

ALTER TABLE IF EXISTS public.emission_factors
    ALTER COLUMN is_market_based_alternative SET DEFAULT FALSE;

ALTER TABLE IF EXISTS public.emission_factors
    ALTER COLUMN is_market_based_alternative SET NOT NULL;

-- The current EmissionActivity entity persists raw_emissions_kg and allocated_emissions_kg.
-- Some older databases still have a legacy emissions_kg column marked NOT NULL, so Hibernate
-- omits it during INSERT and PostgreSQL rejects the row. Make the legacy column optional only
-- when that column exists; preserve the column and all existing values.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'emission_activities'
          AND column_name = 'emissions_kg'
    ) THEN
        ALTER TABLE public.emission_activities
            ALTER COLUMN emissions_kg DROP NOT NULL;
    END IF;
END $$;
