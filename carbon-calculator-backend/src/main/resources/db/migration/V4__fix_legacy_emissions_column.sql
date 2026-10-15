-- The current EmissionActivity entity uses raw_emissions_kg
-- and allocated_emissions_kg instead of the legacy emissions_kg.
-- Allow inserts that do not populate the obsolete column.

ALTER TABLE public.emission_activities
    ALTER COLUMN emissions_kg DROP NOT NULL;
