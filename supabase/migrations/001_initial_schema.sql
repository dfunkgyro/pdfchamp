-- PDFChamp Initial Database Schema
-- Run this in your Supabase SQL editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ======================
-- USERS TABLE (extends auth.users)
-- ======================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    preferences JSONB DEFAULT '{}'::jsonb,
    subscription_tier TEXT DEFAULT 'free' CHECK (subscription_tier IN ('free', 'pro', 'enterprise')),
    storage_used_bytes BIGINT DEFAULT 0,
    storage_limit_bytes BIGINT DEFAULT 1073741824, -- 1GB default
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view their own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

-- ======================
-- PDFS TABLE
-- ======================
CREATE TABLE IF NOT EXISTS public.pdfs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    file_name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_size BIGINT,
    page_count INTEGER,
    thumbnail_url TEXT,
    is_favorite BOOLEAN DEFAULT FALSE,
    is_encrypted BOOLEAN DEFAULT FALSE,
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    metadata JSONB DEFAULT '{}'::jsonb,
    last_opened_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS on pdfs
ALTER TABLE public.pdfs ENABLE ROW LEVEL SECURITY;

-- PDFs policies
CREATE POLICY "Users can view their own PDFs"
    ON public.pdfs FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own PDFs"
    ON public.pdfs FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own PDFs"
    ON public.pdfs FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own PDFs"
    ON public.pdfs FOR DELETE
    USING (auth.uid() = user_id);

-- Indexes for PDFs
CREATE INDEX IF NOT EXISTS idx_pdfs_user_id ON public.pdfs(user_id);
CREATE INDEX IF NOT EXISTS idx_pdfs_created_at ON public.pdfs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_pdfs_tags ON public.pdfs USING GIN(tags);

-- ======================
-- PDF EDITS TABLE
-- ======================
CREATE TABLE IF NOT EXISTS public.pdf_edits (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    pdf_id UUID REFERENCES public.pdfs(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    edit_type TEXT NOT NULL CHECK (edit_type IN ('text', 'annotation', 'highlight', 'redaction', 'form_fill', 'signature')),
    page_number INTEGER NOT NULL,
    edit_data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS on pdf_edits
ALTER TABLE public.pdf_edits ENABLE ROW LEVEL SECURITY;

-- PDF Edits policies
CREATE POLICY "Users can view their own PDF edits"
    ON public.pdf_edits FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own PDF edits"
    ON public.pdf_edits FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own PDF edits"
    ON public.pdf_edits FOR DELETE
    USING (auth.uid() = user_id);

-- Indexes for PDF Edits
CREATE INDEX IF NOT EXISTS idx_pdf_edits_pdf_id ON public.pdf_edits(pdf_id);
CREATE INDEX IF NOT EXISTS idx_pdf_edits_user_id ON public.pdf_edits(user_id);

-- ======================
-- FOLDERS TABLE
-- ======================
CREATE TABLE IF NOT EXISTS public.folders (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    parent_folder_id UUID REFERENCES public.folders(id) ON DELETE CASCADE,
    color TEXT,
    icon TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id, parent_folder_id, name)
);

-- Enable RLS on folders
ALTER TABLE public.folders ENABLE ROW LEVEL SECURITY;

-- Folders policies
CREATE POLICY "Users can view their own folders"
    ON public.folders FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own folders"
    ON public.folders FOR ALL
    USING (auth.uid() = user_id);

-- Indexes for Folders
CREATE INDEX IF NOT EXISTS idx_folders_user_id ON public.folders(user_id);
CREATE INDEX IF NOT EXISTS idx_folders_parent_id ON public.folders(parent_folder_id);

-- ======================
-- PDF FOLDERS (Many-to-Many)
-- ======================
CREATE TABLE IF NOT EXISTS public.pdf_folders (
    pdf_id UUID REFERENCES public.pdfs(id) ON DELETE CASCADE NOT NULL,
    folder_id UUID REFERENCES public.folders(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    PRIMARY KEY (pdf_id, folder_id)
);

-- Enable RLS on pdf_folders
ALTER TABLE public.pdf_folders ENABLE ROW LEVEL SECURITY;

-- PDF Folders policies
CREATE POLICY "Users can manage their PDF folder assignments"
    ON public.pdf_folders FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.pdfs
            WHERE pdfs.id = pdf_folders.pdf_id
            AND pdfs.user_id = auth.uid()
        )
    );

-- ======================
-- AI INTERACTIONS TABLE
-- ======================
CREATE TABLE IF NOT EXISTS public.ai_interactions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    pdf_id UUID REFERENCES public.pdfs(id) ON DELETE CASCADE,
    interaction_type TEXT NOT NULL CHECK (interaction_type IN ('chat', 'summarize', 'extract', 'translate', 'analyze')),
    prompt TEXT NOT NULL,
    response TEXT,
    model TEXT,
    tokens_used INTEGER,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS on ai_interactions
ALTER TABLE public.ai_interactions ENABLE ROW LEVEL SECURITY;

-- AI Interactions policies
CREATE POLICY "Users can view their own AI interactions"
    ON public.ai_interactions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own AI interactions"
    ON public.ai_interactions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Indexes for AI Interactions
CREATE INDEX IF NOT EXISTS idx_ai_interactions_user_id ON public.ai_interactions(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_interactions_pdf_id ON public.ai_interactions(pdf_id);
CREATE INDEX IF NOT EXISTS idx_ai_interactions_created_at ON public.ai_interactions(created_at DESC);

-- ======================
-- ACTIVITY LOG TABLE
-- ======================
CREATE TABLE IF NOT EXISTS public.activity_log (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    pdf_id UUID REFERENCES public.pdfs(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    details JSONB DEFAULT '{}'::jsonb,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS on activity_log
ALTER TABLE public.activity_log ENABLE ROW LEVEL SECURITY;

-- Activity Log policies
CREATE POLICY "Users can view their own activity"
    ON public.activity_log FOR SELECT
    USING (auth.uid() = user_id);

-- Indexes for Activity Log
CREATE INDEX IF NOT EXISTS idx_activity_log_user_id ON public.activity_log(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_log_created_at ON public.activity_log(created_at DESC);

-- ======================
-- FUNCTIONS
-- ======================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pdfs_updated_at BEFORE UPDATE ON public.pdfs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_folders_updated_at BEFORE UPDATE ON public.folders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to automatically create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on new auth user
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to update storage used
CREATE OR REPLACE FUNCTION update_storage_used()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.profiles
        SET storage_used_bytes = storage_used_bytes + NEW.file_size
        WHERE id = NEW.user_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.profiles
        SET storage_used_bytes = storage_used_bytes - OLD.file_size
        WHERE id = OLD.user_id;
    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE public.profiles
        SET storage_used_bytes = storage_used_bytes - OLD.file_size + NEW.file_size
        WHERE id = NEW.user_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update storage used
CREATE TRIGGER update_profile_storage
    AFTER INSERT OR UPDATE OR DELETE ON public.pdfs
    FOR EACH ROW EXECUTE FUNCTION update_storage_used();

-- ======================
-- STORAGE BUCKETS
-- ======================

-- Create storage buckets (run in Supabase dashboard if needed)
INSERT INTO storage.buckets (id, name, public)
VALUES
    ('pdfs', 'pdfs', false),
    ('thumbnails', 'thumbnails', true),
    ('fonts', 'fonts', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for PDFs bucket
CREATE POLICY "Users can upload their own PDFs"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'pdfs' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can view their own PDFs"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'pdfs' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can delete their own PDFs"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'pdfs' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Storage policies for thumbnails bucket (public read)
CREATE POLICY "Anyone can view thumbnails"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'thumbnails');

CREATE POLICY "Users can upload thumbnails"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'thumbnails');

-- Storage policies for fonts bucket (public read)
CREATE POLICY "Anyone can view fonts"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'fonts');

CREATE POLICY "Authenticated users can upload fonts"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'fonts' AND
        auth.role() = 'authenticated'
    );

-- ======================
-- VIEWS
-- ======================

-- View for PDF statistics
CREATE OR REPLACE VIEW pdf_statistics AS
SELECT
    p.user_id,
    COUNT(*) as total_pdfs,
    SUM(p.file_size) as total_size_bytes,
    COUNT(CASE WHEN p.is_favorite THEN 1 END) as favorites_count,
    MAX(p.created_at) as last_upload,
    COUNT(DISTINCT DATE(p.created_at)) as upload_days
FROM public.pdfs p
GROUP BY p.user_id;

-- ======================
-- SAMPLE DATA (Optional - for testing)
-- ======================

-- Insert sample folder for new users
-- CREATE OR REPLACE FUNCTION create_default_folders()
-- RETURNS TRIGGER AS $$
-- BEGIN
--     INSERT INTO public.folders (user_id, name, color, icon)
--     VALUES
--         (NEW.id, 'My Documents', '#3B82F6', 'folder'),
--         (NEW.id, 'Work', '#10B981', 'briefcase'),
--         (NEW.id, 'Personal', '#F59E0B', 'user');
--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER create_user_default_folders
--     AFTER INSERT ON public.profiles
--     FOR EACH ROW EXECUTE FUNCTION create_default_folders();
