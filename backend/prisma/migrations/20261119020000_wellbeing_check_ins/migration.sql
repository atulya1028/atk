CREATE TABLE wellbeing_check_ins (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  topic TEXT NOT NULL CHECK (topic IN (
    'emotional_wellbeing', 'anxiety_worry', 'stress_management', 'sleep_relaxation'
  )),
  responses JSONB NOT NULL,
  updated_at TIMESTAMPTZ(6) NOT NULL,
  PRIMARY KEY (user_id, topic)
);
