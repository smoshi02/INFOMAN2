-- Scene 1
CREATE INDEX idx_author_id on posts (author_id);
CREATE INDEX idx_date on posts (date);

-- Scene 2
CREATE INDEX idx_title on posts (title);

-- Scene 3
CREATE INDEX idx_date on posts (date);