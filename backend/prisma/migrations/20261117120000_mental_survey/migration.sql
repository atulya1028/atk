ALTER TABLE survey_submissions
  DROP CONSTRAINT IF EXISTS survey_submissions_type_check;

ALTER TABLE survey_submissions
  ADD CONSTRAINT survey_submissions_type_check
  CHECK (type IN ('INITIAL', 'DETAILED', 'MENTAL'));
