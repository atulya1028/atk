ALTER TABLE survey_submissions
  DROP CONSTRAINT survey_submissions_type_check,
  ADD CONSTRAINT survey_submissions_type_check
    CHECK (type IN ('INITIAL', 'DETAILED', 'MENTAL', 'MENTAL_STANDALONE'));
