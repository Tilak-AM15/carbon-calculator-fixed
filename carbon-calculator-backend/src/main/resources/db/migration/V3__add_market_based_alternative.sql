ALTER TABLE public.emission_factors
    ADD COLUMN IF NOT EXISTS is_market_based_alternative
    BOOLEAN NOT NULL DEFAULT FALSE;
