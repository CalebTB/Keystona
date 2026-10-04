-- Add new project_type enum values
ALTER TYPE project_type ADD VALUE IF NOT EXISTS 'plumbing';
ALTER TYPE project_type ADD VALUE IF NOT EXISTS 'electrical';
ALTER TYPE project_type ADD VALUE IF NOT EXISTS 'general_renovation';

-- Add work_type column to projects (TEXT + CHECK — avoids needing ALTER TYPE for future values)
ALTER TABLE projects
  ADD COLUMN IF NOT EXISTS work_type TEXT NOT NULL DEFAULT 'diy'
    CHECK (work_type IN ('diy', 'contractor', 'mixed'));

-- Create project-photos storage bucket (private)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'project-photos',
  'project-photos',
  false,
  10485760,
  ARRAY['image/jpeg', 'image/png', 'image/heic', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- RLS policies for project-photos bucket
-- Users can only access photos in their own folder (path starts with their user_id)
CREATE POLICY "project_photos_select"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'project-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "project_photos_insert"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'project-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "project_photos_update"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'project-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "project_photos_delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'project-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
