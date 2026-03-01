-- ==========================================
-- MIGRATION SCRIPT: INT -> UUID FOR CI IDs
-- ==========================================
-- This script safely migrates the primary keys of the `cis` table from TEXT to UUID.
-- It also propagates the changes to all foreign keys:
-- - dependencies (parent_id, child_id)
-- - events (affected_ci_id)

-- 1. Add temporary UUID columns to the `cis` table
ALTER TABLE public.cis ADD COLUMN new_id UUID DEFAULT uuid_generate_v4();

-- 2. Add temporary UUID columns to referencing tables
ALTER TABLE public.dependencies ADD COLUMN new_source_ci_id UUID;
ALTER TABLE public.dependencies ADD COLUMN new_target_ci_id UUID;
ALTER TABLE public.events ADD COLUMN new_affected_ci_id UUID;

-- 3. Populate the new UUIDs in the referencing tables by joining the original TEXT IDs
UPDATE public.dependencies d
SET new_source_ci_id = c.new_id
FROM public.cis c
WHERE d.source_ci_id = c.id;

UPDATE public.dependencies d
SET new_target_ci_id = c.new_id
FROM public.cis c
WHERE d.target_ci_id = c.id;

UPDATE public.events e
SET new_affected_ci_id = c.new_id
FROM public.cis c
WHERE e.affected_ci_id = c.id;

-- 4. Drop the old foreign key constraints
ALTER TABLE public.dependencies DROP CONSTRAINT IF EXISTS dependencies_source_ci_id_fkey;
ALTER TABLE public.dependencies DROP CONSTRAINT IF EXISTS dependencies_target_ci_id_fkey;
ALTER TABLE public.events DROP CONSTRAINT IF EXISTS events_affected_ci_id_fkey;

-- 5. Drop the old primary key constraint and the old columns
ALTER TABLE public.cis DROP CONSTRAINT IF EXISTS cis_pkey CASCADE;

ALTER TABLE public.dependencies DROP COLUMN source_ci_id CASCADE;
ALTER TABLE public.dependencies DROP COLUMN target_ci_id CASCADE;
ALTER TABLE public.events DROP COLUMN affected_ci_id CASCADE;
ALTER TABLE public.cis DROP COLUMN id CASCADE;

-- 6. Rename the new UUID columns to their original names
ALTER TABLE public.cis RENAME COLUMN new_id TO id;
ALTER TABLE public.dependencies RENAME COLUMN new_source_ci_id TO source_ci_id;
ALTER TABLE public.dependencies RENAME COLUMN new_target_ci_id TO target_ci_id;
ALTER TABLE public.events RENAME COLUMN new_affected_ci_id TO affected_ci_id;

-- 7. Restore the Primary Key and Foreign Keys constraints
ALTER TABLE public.cis ADD PRIMARY KEY (id);

-- Make columns NOT NULL (optional but recommended depending on previous schema rules)
-- Assuming they were NOT NULL before
ALTER TABLE public.dependencies ALTER COLUMN source_ci_id SET NOT NULL;
ALTER TABLE public.dependencies ALTER COLUMN target_ci_id SET NOT NULL;
ALTER TABLE public.events ALTER COLUMN affected_ci_id SET NOT NULL;

-- Re-add Foreign Keys
ALTER TABLE public.dependencies 
  ADD CONSTRAINT dependencies_source_ci_id_fkey FOREIGN KEY (source_ci_id) REFERENCES public.cis(id) ON DELETE CASCADE;

ALTER TABLE public.dependencies 
  ADD CONSTRAINT dependencies_target_ci_id_fkey FOREIGN KEY (target_ci_id) REFERENCES public.cis(id) ON DELETE CASCADE;

ALTER TABLE public.events 
  ADD CONSTRAINT events_affected_ci_id_fkey FOREIGN KEY (affected_ci_id) REFERENCES public.cis(id) ON DELETE CASCADE;

-- ==========================================
-- CREATION SCRIPT: JOURNEY MAPS
-- ==========================================

-- 1. Table journey_maps
CREATE TABLE IF NOT EXISTS public.journey_maps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.journey_maps ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read access to journey_maps" ON public.journey_maps FOR SELECT USING (true);
CREATE POLICY "Allow admin to manage journey_maps" ON public.journey_maps FOR ALL USING (auth.role() = 'authenticated');

-- 2. Table journey_map_cis (Junction table)
-- Now we can safely use UUID for ci_id !
CREATE TABLE IF NOT EXISTS public.journey_map_cis (
    journey_map_id UUID NOT NULL REFERENCES public.journey_maps(id) ON DELETE CASCADE,
    ci_id UUID NOT NULL REFERENCES public.cis(id) ON DELETE CASCADE,
    position INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (journey_map_id, ci_id)
);

-- Enable RLS
ALTER TABLE public.journey_map_cis ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read access to journey_map_cis" ON public.journey_map_cis FOR SELECT USING (true);
CREATE POLICY "Allow admin to manage journey_map_cis" ON public.journey_map_cis FOR ALL USING (auth.role() = 'authenticated');
