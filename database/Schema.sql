-- =====================================================
-- Skill Exchange Platform : Schema + Demo Sample Data
-- =====================================================

DROP DATABASE IF EXISTS skill_exchange;
CREATE DATABASE skill_exchange;
USE skill_exchange;

-- -----------------------------------------------------
-- 1. USERS
-- -----------------------------------------------------
CREATE TABLE users (
    user_id        INT AUTO_INCREMENT PRIMARY KEY,
    name           VARCHAR(100) NOT NULL,
    email          VARCHAR(150) NOT NULL UNIQUE,
    password_hash  VARCHAR(255) NOT NULL,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------
-- 2. CATEGORIES
-- -----------------------------------------------------
CREATE TABLE categories (
    category_id    INT AUTO_INCREMENT PRIMARY KEY,
    category_name  VARCHAR(80) NOT NULL UNIQUE
);

-- -----------------------------------------------------
-- 3. SKILLS  (each skill belongs to one category: N:1)
-- -----------------------------------------------------
CREATE TABLE skills (
    skill_id       INT AUTO_INCREMENT PRIMARY KEY,
    skill_name     VARCHAR(100) NOT NULL UNIQUE,
    description    TEXT,
    category_id    INT NOT NULL,
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- -----------------------------------------------------
-- 4. USER_OFFERS  (M:N between users and skills)
-- -----------------------------------------------------
CREATE TABLE user_offers (
    user_id            INT NOT NULL,
    skill_id           INT NOT NULL,
    proficiency_level  ENUM('Beginner','Intermediate','Advanced') NOT NULL DEFAULT 'Intermediate',
    PRIMARY KEY (user_id, skill_id),
    FOREIGN KEY (user_id)  REFERENCES users(user_id)   ON DELETE CASCADE,
    FOREIGN KEY (skill_id) REFERENCES skills(skill_id) ON DELETE CASCADE
);

-- -----------------------------------------------------
-- 5. USER_WANTS  (M:N between users and skills)
-- -----------------------------------------------------
CREATE TABLE user_wants (
    user_id    INT NOT NULL,
    skill_id   INT NOT NULL,
    PRIMARY KEY (user_id, skill_id),
    FOREIGN KEY (user_id)  REFERENCES users(user_id)   ON DELETE CASCADE,
    FOREIGN KEY (skill_id) REFERENCES skills(skill_id) ON DELETE CASCADE
);

-- -----------------------------------------------------
-- 6. EXCHANGE_REQUESTS
--    sender asks receiver for requested_skill_id
--    and offers offered_skill_id in return
-- -----------------------------------------------------
CREATE TABLE exchange_requests (
    request_id          INT AUTO_INCREMENT PRIMARY KEY,
    sender_id           INT NOT NULL,
    receiver_id         INT NOT NULL,
    requested_skill_id  INT NOT NULL,
    offered_skill_id    INT NOT NULL,
    status              ENUM('Pending','Accepted','Rejected','Completed','Cancelled')
                        NOT NULL DEFAULT 'Pending',
    request_date        DATE NOT NULL,
    FOREIGN KEY (sender_id)          REFERENCES users(user_id),
    FOREIGN KEY (receiver_id)        REFERENCES users(user_id),
    FOREIGN KEY (requested_skill_id) REFERENCES skills(skill_id),
    FOREIGN KEY (offered_skill_id)   REFERENCES skills(skill_id),
    CONSTRAINT chk_diff_users CHECK (sender_id <> receiver_id)
);

-- -----------------------------------------------------
-- 7. VIDEOS  (tutorial uploaded by a user for a skill)
-- -----------------------------------------------------
CREATE TABLE videos (
    video_id          INT AUTO_INCREMENT PRIMARY KEY,
    title             VARCHAR(150) NOT NULL,
    video_url         VARCHAR(255) NOT NULL,
    duration_minutes  INT CHECK (duration_minutes > 0),
    upload_date       DATE NOT NULL,
    user_id           INT NOT NULL,
    skill_id          INT NOT NULL,
    FOREIGN KEY (user_id)  REFERENCES users(user_id)   ON DELETE CASCADE,
    FOREIGN KEY (skill_id) REFERENCES skills(skill_id) ON DELETE CASCADE
);

-- Indexes for common lookups
CREATE INDEX idx_req_sender   ON exchange_requests(sender_id);
CREATE INDEX idx_req_receiver ON exchange_requests(receiver_id);
CREATE INDEX idx_req_status   ON exchange_requests(status);
CREATE INDEX idx_video_skill  ON videos(skill_id);

-- =====================================================
-- SAMPLE DATA --> bs demo ke liye hian mein bhejta hoon sample data eyin insert mt krna sumit
-- =====================================================

-- Users (password_hash values are dummy placeholders)
INSERT INTO users (name, email, password_hash) VALUES
('Aarav Sharma',   'aarav.sharma@example.com',   '$2b$10$aaravHashDummyValue000000000000000000000000000001'),
('Priya Verma',    'priya.verma@example.com',    '$2b$10$priyaHashDummyValue000000000000000000000000000002'),
('Rohan Patil',    'rohan.patil@example.com',    '$2b$10$rohanHashDummyValue000000000000000000000000000003'),
('Sneha Kulkarni', 'sneha.kulkarni@example.com', '$2b$10$snehaHashDummyValue000000000000000000000000000004'),
('Aditya Singh',   'aditya.singh@example.com',   '$2b$10$adityaHashDummyValue00000000000000000000000000005'),
('Neha Gupta',     'neha.gupta@example.com',     '$2b$10$nehaHashDummyValue0000000000000000000000000000006'),
('Karan Mehta',    'karan.mehta@example.com',    '$2b$10$karanHashDummyValue000000000000000000000000000007'),
('Ananya Joshi',   'ananya.joshi@example.com',   '$2b$10$ananyaHashDummyValue00000000000000000000000000008'),
('Vikram Rao',     'vikram.rao@example.com',     '$2b$10$vikramHashDummyValue00000000000000000000000000009'),
('Isha Deshmukh',  'isha.deshmukh@example.com',  '$2b$10$ishaHashDummyValue0000000000000000000000000000010');

-- Categories
INSERT INTO categories (category_name) VALUES
('Programming'),        -- 1
('Design'),             -- 2
('Music'),              -- 3
('Languages'),          -- 4
('Academics'),          -- 5
('Lifestyle & Hobbies');-- 6

-- Skills
INSERT INTO skills (skill_name, description, category_id) VALUES
('Python Programming',     'Python basics to intermediate, scripting and problem solving', 1),  -- 1
('C++ & DSA',              'C++ with data structures and algorithms for placements',       1),  -- 2
('Web Development',        'HTML, CSS, JavaScript, React and Node.js',                     1),  -- 3
('Machine Learning Basics','Intro to ML concepts, scikit-learn and model evaluation',      1),  -- 4
('UI/UX Design',           'Wireframing and prototyping with Figma',                       2),  -- 5
('Graphic Design',         'Posters, logos and branding using Canva and Photoshop',        2),  -- 6
('Video Editing',          'Editing and storytelling using Premiere Pro and DaVinci',      2),  -- 7
('Guitar',                 'Chords, strumming patterns and basic songs',                   3),  -- 8
('Singing',                'Vocal training, breathing and pitch control',                  3),  -- 9
('Tabla',                  'Basic taals and bols for beginners',                           3),  -- 10
('English Speaking',       'Fluency, vocabulary and daily conversation practice',          4),  -- 11
('French',                 'Beginner French grammar and speaking',                         4),  -- 12
('Marathi Writing',        'Marathi grammar, essays and creative writing',                 4),  -- 13
('Engineering Mathematics','Calculus, Laplace and Fourier transforms, linear algebra',     5),  -- 14
('Digital Electronics',    'Logic gates, flip-flops, counters and circuits',               5),  -- 15
('SQL & Databases',        'SQL queries, joins, normalization and ER modelling',           1),  -- 16
('Photography',            'Composition, lighting and mobile or DSLR photography',         6),  -- 17
('Cooking',                'Home-style Indian cooking and meal prep',                      6),  -- 18
('Chess',                  'Openings, tactics and endgames',                               6),  -- 19
('Public Speaking',        'Stage confidence, speech structure and debate',                4);  -- 20

-- Skills offered by users
INSERT INTO user_offers (user_id, skill_id, proficiency_level) VALUES
(1, 1,  'Advanced'),
(1, 2,  'Advanced'),
(1, 16, 'Intermediate'),
(2, 5,  'Advanced'),
(2, 6,  'Intermediate'),
(3, 3,  'Advanced'),
(3, 16, 'Advanced'),
(4, 8,  'Intermediate'),
(4, 9,  'Advanced'),
(5, 2,  'Advanced'),
(5, 19, 'Intermediate'),
(6, 11, 'Advanced'),
(6, 20, 'Intermediate'),
(7, 7,  'Intermediate'),
(7, 17, 'Advanced'),
(8, 12, 'Intermediate'),
(8, 14, 'Advanced'),
(9, 4,  'Intermediate'),
(9, 15, 'Advanced'),
(10, 18,'Advanced'),
(10, 13,'Advanced');

-- Skills wanted by users
INSERT INTO user_wants (user_id, skill_id) VALUES
(1, 5), (1, 8), (1, 20),
(2, 3), (2, 11),
(3, 7), (3, 17),
(4, 1), (4, 14),
(5, 3), (5, 11),
(6, 1), (6, 12),
(7, 2), (7, 16),
(8, 4), (8, 9),
(9, 2), (9, 18),
(10, 5), (10, 1);

-- Exchange requests (sender offers offered_skill, receiver teaches requested_skill)
INSERT INTO exchange_requests
(sender_id, receiver_id, requested_skill_id, offered_skill_id, status, request_date) VALUES
(1,  2,  5,  1,  'Accepted',  '2026-08-10'),
(2,  3,  3,  5,  'Completed', '2026-08-12'),
(3,  7,  17, 3,  'Pending',   '2026-09-01'),
(4,  8,  14, 8,  'Accepted',  '2026-09-03'),
(5,  6,  11, 2,  'Completed', '2026-08-20'),
(6,  1,  1,  11, 'Rejected',  '2026-08-25'),
(7,  3,  16, 7,  'Pending',   '2026-09-10'),
(8,  4,  9,  14, 'Completed', '2026-08-30'),
(9,  5,  2,  15, 'Pending',   '2026-09-15'),
(10, 2,  5,  18, 'Accepted',  '2026-09-18'),
(9,  10, 18, 4,  'Cancelled', '2026-09-20'),
(6,  8,  12, 20, 'Accepted',  '2026-09-22');

-- Tutorial videos
INSERT INTO videos (title, video_url, duration_minutes, upload_date, user_id, skill_id) VALUES
('Python in 30 Minutes',              'https://example.com/videos/python-in-30.mp4',      30, '2026-07-05', 1,  1),
('Binary Search Explained',           'https://example.com/videos/binary-search.mp4',     18, '2026-07-12', 5,  2),
('Intro to Figma',                    'https://example.com/videos/intro-figma.mp4',       25, '2026-07-15', 2,  5),
('React Basics Crash Course',         'https://example.com/videos/react-basics.mp4',      45, '2026-07-20', 3,  3),
('Beginner Guitar Chords',            'https://example.com/videos/guitar-chords.mp4',     22, '2026-07-25', 4,  8),
('SQL Joins Made Easy',               'https://example.com/videos/sql-joins.mp4',         20, '2026-08-01', 3,  16),
('Photography Composition Tips',      'https://example.com/videos/photo-composition.mp4', 15, '2026-08-05', 7,  17),
('Daily English Conversation',        'https://example.com/videos/english-daily.mp4',     28, '2026-08-08', 6,  11),
('Laplace Transform Basics',          'https://example.com/videos/laplace-basics.mp4',    35, '2026-08-14', 8,  14),
('Perfect Paneer Butter Masala',      'https://example.com/videos/paneer-masala.mp4',     17, '2026-08-18', 10, 18),
('Intro to Machine Learning',         'https://example.com/videos/intro-ml.mp4',          40, '2026-08-22', 9,  4),
('Basic French Greetings',            'https://example.com/videos/french-greetings.mp4',  12, '2026-08-28', 8,  12);

-- =====================================================
-- Yein dekh yein sample queries bhi aise tum log run krwa skte ho!!!
-- SAMPLE QUERIES (for demo / viva)
-- =====================================================

-- Q1: All requests with names instead of IDs
SELECT r.request_id,
       s.name  AS sender,
       rc.name AS receiver,
       sk1.skill_name AS requested_skill,
       sk2.skill_name AS offered_skill,
       r.status, r.request_date
FROM exchange_requests r
JOIN users  s  ON r.sender_id = s.user_id
JOIN users  rc ON r.receiver_id = rc.user_id
JOIN skills sk1 ON r.requested_skill_id = sk1.skill_id
JOIN skills sk2 ON r.offered_skill_id = sk2.skill_id
ORDER BY r.request_date;

-- Q2: Skills grouped by category
SELECT c.category_name, COUNT(s.skill_id) AS total_skills
FROM categories c
LEFT JOIN skills s ON c.category_id = s.category_id
GROUP BY c.category_name;

-- Q3: Perfect two-way matches (A offers what B wants AND B offers what A wants)
SELECT u1.name AS user_a, u2.name AS user_b,
       s1.skill_name AS a_teaches_b, s2.skill_name AS b_teaches_a
FROM user_offers o1
JOIN user_wants  w2 ON o1.skill_id = w2.skill_id
JOIN user_offers o2 ON o2.user_id = w2.user_id
JOIN user_wants  w1 ON w1.user_id = o1.user_id AND w1.skill_id = o2.skill_id
JOIN users  u1 ON u1.user_id = o1.user_id
JOIN users  u2 ON u2.user_id = o2.user_id
JOIN skills s1 ON s1.skill_id = o1.skill_id
JOIN skills s2 ON s2.skill_id = o2.skill_id
WHERE o1.user_id < o2.user_id;

-- Q4: Most popular offered skills
SELECT s.skill_name, COUNT(*) AS offered_by
FROM user_offers o JOIN skills s ON o.skill_id = s.skill_id
GROUP BY s.skill_name
ORDER BY offered_by DESC;

-- Q5: Number of completed exchanges per user (as sender or receiver)
SELECT u.name, COUNT(*) AS completed_exchanges
FROM users u
JOIN exchange_requests r ON u.user_id IN (r.sender_id, r.receiver_id)
WHERE r.status = 'Completed'
GROUP BY u.name;
