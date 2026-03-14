-- ==========================================
-- MIGRATION SCRIPT: GLOBAL SCOPE TAGS
-- ==========================================

-- 1. Create the `tags` table
CREATE TABLE IF NOT EXISTS public.tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    label TEXT NOT NULL UNIQUE,
    color TEXT NOT NULL DEFAULT '#808080', -- Hex color code, e.g., '#FF0000'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for tags
ALTER TABLE public.tags ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read access to tags" ON public.tags FOR SELECT USING (true);
CREATE POLICY "Allow admin to manage tags" ON public.tags FOR ALL USING (auth.role() = 'authenticated');

-- 2. Add `tags` column to existing tables (Array of TEXT representing the tag labels)
ALTER TABLE public.cis ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';
ALTER TABLE public.journey_maps ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';

-- 3. Update `dependencies` table
-- Previously we used bu_filter (TEXT[]). We rename it to tags for consistency.
DO $$
BEGIN
  IF EXISTS(SELECT *
    FROM information_schema.columns
    WHERE table_name='dependencies' and column_name='bu_filter')
  THEN
      ALTER TABLE public.dependencies RENAME COLUMN bu_filter TO tags;
  ELSE
      ALTER TABLE public.dependencies ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';
  END IF;
END $$;

-- 4. Update `events` table
-- Previously we used impacted_bus (TEXT[]). We rename it to tags for consistency.
DO $$
BEGIN
  IF EXISTS(SELECT *
    FROM information_schema.columns
    WHERE table_name='events' and column_name='impacted_bus')
  THEN
      ALTER TABLE public.events RENAME COLUMN impacted_bus TO tags;
  ELSE
      ALTER TABLE public.events ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';
  END IF;
END $$;

-- 5. Set default empty arrays instead of NULL to simplify dart mapping
UPDATE public.cis SET tags = '{}' WHERE tags IS NULL;
UPDATE public.journey_maps SET tags = '{}' WHERE tags IS NULL;
UPDATE public.dependencies SET tags = '{}' WHERE tags IS NULL;
UPDATE public.events SET tags = '{}' WHERE tags IS NULL;
