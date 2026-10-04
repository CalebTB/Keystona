CREATE TABLE public.users_metadata (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  onboarding_completed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.users_metadata ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own metadata"
  ON public.users_metadata FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own metadata"
  ON public.users_metadata FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own metadata"
  ON public.users_metadata FOR UPDATE
  USING (auth.uid() = id);
