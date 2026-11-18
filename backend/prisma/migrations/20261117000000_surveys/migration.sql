CREATE TABLE survey_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('INITIAL', 'DETAILED')),
  answers JSONB NOT NULL DEFAULT '{}'::jsonb,
  score INTEGER,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX survey_submissions_user_type_updated_idx ON survey_submissions (user_id, type, updated_at DESC);
