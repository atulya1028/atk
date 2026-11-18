CREATE TABLE survey_questions (
  id TEXT PRIMARY KEY,
  survey_type TEXT NOT NULL CHECK (survey_type IN ('INITIAL', 'MENTAL')),
  question_id TEXT NOT NULL,
  source_order INTEGER NOT NULL,
  definition JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT survey_questions_type_question_key UNIQUE (survey_type, question_id)
);

CREATE INDEX survey_questions_type_order_idx
  ON survey_questions (survey_type, source_order);
