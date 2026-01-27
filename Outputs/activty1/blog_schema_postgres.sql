CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    comment TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (post_id) REFERENCES posts(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

INSERT INTO users (username) VALUES 
('alice'), 
('bob'),
('decimo'),
('smoshi'),
('tizzman'),
('KesongBinola'),
('Shemay');

INSERT INTO posts (user_id, title, body) VALUES
(1, 'First Post!', 'This is the body of the first post.'),
(2, 'Bob''s Thoughts', 'A penny for my thoughts.'),
(3, 'Welcome Post', 'Decimo welcomes everyone to the blog!'),
(4, 'Smoshi''s Musings', 'Random thoughts and musings from Smoshi.'),
(5, 'Tizzman Tips', 'Tizzman shares tips and tricks.'),
(6, 'Cheese Adventures', 'KesongBinola writes about cheese adventures.'),
(7, 'Life of Shemay', 'Shemay talks about daily life and experiences.');


INSERT INTO comments (post_id, user_id, comment) VALUES
(1, 2, 'Great first post, Alice!'),
(2, 1, 'Interesting thoughts, Bob.'),
(3, 2, 'Welcome, Decimo!'),
(4, 3, 'Nice musings, Smoshi.'),
(5, 4, 'Thanks for the tips, Tizzman.'),
(6, 5, 'Cheese adventures sound fun!'),
(7, 6, 'Life stories are interesting, Shemay!');