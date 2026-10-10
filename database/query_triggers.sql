use skill_exchange
-- Skill Exchange Platform: project queries, views, and triggers
-- Target: MySQL 8.0+; run after the supplied schema has been created.
-- This file contains no INSERT statements and does not alter the source schema.

USE skill_exchange;

-- ============================================================
-- A. REPORTING AND SEARCH QUERIES
-- ============================================================

-- Q1. Browse the complete skill catalog with its category.
SELECT s.skill_id, s.skill_name, s.description, c.category_name
FROM skills AS s
JOIN categories AS c ON c.category_id = s.category_id
ORDER BY c.category_name, s.skill_name;

-- Q2. Show each user's offered skills and proficiency.
SELECT u.user_id, u.name, s.skill_name, o.proficiency_level
FROM user_offers AS o
JOIN users AS u ON u.user_id = o.user_id
JOIN skills AS s ON s.skill_id = o.skill_id
ORDER BY u.name, s.skill_name;

-- Q3. Show each user's wanted skills.
SELECT u.user_id, u.name, s.skill_name
FROM user_wants AS w
JOIN users AS u ON u.user_id = w.user_id
JOIN skills AS s ON s.skill_id = w.skill_id
ORDER BY u.name, s.skill_name;

-- Q4. Requests in readable form, including both participants and skills.
SELECT r.request_id, sender.name AS sender, receiver.name AS receiver,
       requested.skill_name AS requested_skill,
       offered.skill_name AS offered_skill, r.status, r.request_date
FROM exchange_requests AS r
JOIN users AS sender ON sender.user_id = r.sender_id
JOIN users AS receiver ON receiver.user_id = r.receiver_id
JOIN skills AS requested ON requested.skill_id = r.requested_skill_id
JOIN skills AS offered ON offered.skill_id = r.offered_skill_id
ORDER BY r.request_date DESC, r.request_id DESC;

-- Q5. Find potential exchange partners for a chosen user's wanted skill.
-- Replace 1 with the user_id being searched for.
SELECT DISTINCT seeker.user_id AS seeker_id, seeker.name AS seeker,
       provider.user_id AS provider_id, provider.name AS provider,
       wanted.skill_name AS skill_the_seeker_wants,
       own_offer.proficiency_level AS provider_proficiency
FROM user_wants AS seeker_want
JOIN skills AS wanted ON wanted.skill_id = seeker_want.skill_id
JOIN user_offers AS own_offer ON own_offer.skill_id = seeker_want.skill_id
JOIN users AS seeker ON seeker.user_id = seeker_want.user_id
JOIN users AS provider ON provider.user_id = own_offer.user_id
WHERE seeker_want.user_id = 1
  AND provider.user_id <> seeker.user_id
ORDER BY own_offer.proficiency_level DESC, provider.name;

-- Q6. Find mutual exchange matches: each user offers a skill the other wants.
SELECT DISTINCT ua.user_id AS user_a_id, ua.name AS user_a,
       ub.user_id AS user_b_id, ub.name AS user_b,
       a_skill.skill_name AS user_a_can_teach,
       b_skill.skill_name AS user_b_can_teach
FROM user_offers AS a_offer
JOIN user_wants AS b_want
  ON b_want.skill_id = a_offer.skill_id
 AND b_want.user_id <> a_offer.user_id
JOIN user_offers AS b_offer ON b_offer.user_id = b_want.user_id
JOIN user_wants AS a_want
  ON a_want.user_id = a_offer.user_id
 AND a_want.skill_id = b_offer.skill_id
JOIN users AS ua ON ua.user_id = a_offer.user_id
JOIN users AS ub ON ub.user_id = b_offer.user_id
JOIN skills AS a_skill ON a_skill.skill_id = a_offer.skill_id
JOIN skills AS b_skill ON b_skill.skill_id = b_offer.skill_id
WHERE ua.user_id < ub.user_id
ORDER BY ua.name, ub.name;

-- Q7. Show skills with the number of users who offer them, including zero.
SELECT s.skill_id, s.skill_name, COUNT(o.user_id) AS number_of_providers
FROM skills AS s
LEFT JOIN user_offers AS o ON o.skill_id = s.skill_id
GROUP BY s.skill_id, s.skill_name
ORDER BY number_of_providers DESC, s.skill_name;

-- Q8. Show popular wanted skills.
SELECT s.skill_name, COUNT(w.user_id) AS number_of_people_wanting
FROM skills AS s
LEFT JOIN user_wants AS w ON w.skill_id = s.skill_id
GROUP BY s.skill_id, s.skill_name
ORDER BY number_of_people_wanting DESC, s.skill_name;

-- Q9. Count skills in every category, including empty categories.
SELECT c.category_id, c.category_name, COUNT(s.skill_id) AS total_skills
FROM categories AS c
LEFT JOIN skills AS s ON s.category_id = c.category_id
GROUP BY c.category_id, c.category_name
ORDER BY c.category_name;

-- Q10. Request totals by status.
SELECT status, COUNT(*) AS request_count
FROM exchange_requests
GROUP BY status
ORDER BY request_count DESC, status;

-- Q11. Completed exchanges per user, counting both sender and receiver roles.
SELECT u.user_id, u.name,
       COUNT(DISTINCT r.request_id) AS completed_exchange_count
FROM users AS u
LEFT JOIN exchange_requests AS r
  ON (r.sender_id = u.user_id OR r.receiver_id = u.user_id)
 AND r.status = 'Completed'
GROUP BY u.user_id, u.name
ORDER BY completed_exchange_count DESC, u.name;

-- Q12. Users who have not offered any skill yet.
SELECT u.user_id, u.name, u.email
FROM users AS u
LEFT JOIN user_offers AS o ON o.user_id = u.user_id
WHERE o.user_id IS NULL
ORDER BY u.name;

-- Q13. Requests currently waiting for a response, oldest first.
SELECT r.request_id, sender.name AS sender, receiver.name AS receiver,
       requested.skill_name AS requested_skill,
       offered.skill_name AS offered_skill, r.request_date
FROM exchange_requests AS r
JOIN users AS sender ON sender.user_id = r.sender_id
JOIN users AS receiver ON receiver.user_id = r.receiver_id
JOIN skills AS requested ON requested.skill_id = r.requested_skill_id
JOIN skills AS offered ON offered.skill_id = r.offered_skill_id
WHERE r.status = 'Pending'
ORDER BY r.request_date, r.request_id;

-- Q14. Video library with the uploader and skill category.
SELECT v.video_id, v.title, v.video_url, v.duration_minutes, v.upload_date,
       u.name AS uploaded_by, s.skill_name, c.category_name
FROM videos AS v
JOIN users AS u ON u.user_id = v.user_id
JOIN skills AS s ON s.skill_id = v.skill_id
JOIN categories AS c ON c.category_id = s.category_id
ORDER BY v.upload_date DESC, v.title;

-- Q15. Find providers by skill name (replace the search phrase).
SELECT s.skill_name, u.user_id, u.name, u.email, o.proficiency_level
FROM skills AS s
JOIN user_offers AS o ON o.skill_id = s.skill_id
JOIN users AS u ON u.user_id = o.user_id
WHERE s.skill_name LIKE '%Python%'
ORDER BY FIELD(o.proficiency_level, 'Advanced', 'Intermediate', 'Beginner'), u.name;

-- Q16. Find skills with no providers.
SELECT s.skill_id, s.skill_name, c.category_name
FROM skills AS s
JOIN categories AS c ON c.category_id = s.category_id
LEFT JOIN user_offers AS o ON o.skill_id = s.skill_id
WHERE o.skill_id IS NULL
ORDER BY c.category_name, s.skill_name;

-- Q17. Monthly exchange request volume.
SELECT DATE_FORMAT(request_date, '%Y-%m') AS request_month,
       COUNT(*) AS request_count
FROM exchange_requests
GROUP BY DATE_FORMAT(request_date, '%Y-%m')
ORDER BY request_month;

-- Q18. Average duration and number of videos per skill (skills without videos included).
SELECT s.skill_id, s.skill_name,
       COUNT(v.video_id) AS video_count,
       ROUND(AVG(v.duration_minutes), 1) AS average_duration_minutes
FROM skills AS s
LEFT JOIN videos AS v ON v.skill_id = s.skill_id
GROUP BY s.skill_id, s.skill_name
ORDER BY video_count DESC, s.skill_name;

-- Q19. Users' activity summary: offered skills, wanted skills, and requests sent.
SELECT u.user_id, u.name,
       COUNT(DISTINCT o.skill_id) AS skills_offered,
       COUNT(DISTINCT w.skill_id) AS skills_wanted,
       COUNT(DISTINCT r.request_id) AS requests_sent
FROM users AS u
LEFT JOIN user_offers AS o ON o.user_id = u.user_id
LEFT JOIN user_wants AS w ON w.user_id = u.user_id
LEFT JOIN exchange_requests AS r ON r.sender_id = u.user_id
GROUP BY u.user_id, u.name
ORDER BY u.name;

-- Q20. Find accepted exchanges by participant (replace 1 with user_id).
SELECT r.request_id, r.status, r.request_date,
       sender.name AS sender, receiver.name AS receiver,
       requested.skill_name AS requested_skill,
       offered.skill_name AS offered_skill
FROM exchange_requests AS r
JOIN users AS sender ON sender.user_id = r.sender_id
JOIN users AS receiver ON receiver.user_id = r.receiver_id
JOIN skills AS requested ON requested.skill_id = r.requested_skill_id
JOIN skills AS offered ON offered.skill_id = r.offered_skill_id
WHERE r.status = 'Accepted'
  AND (r.sender_id = 1 OR r.receiver_id = 1)
ORDER BY r.request_date DESC;

-- ============================================================
-- B. VIEWS
-- ============================================================

CREATE OR REPLACE VIEW vw_skill_catalog AS
SELECT s.skill_id, s.skill_name, s.description,
       c.category_id, c.category_name
FROM skills AS s
JOIN categories AS c ON c.category_id = s.category_id;

CREATE OR REPLACE VIEW vw_user_skill_offers AS
SELECT u.user_id, u.name AS user_name, s.skill_id, s.skill_name,
       o.proficiency_level, c.category_name
FROM user_offers AS o
JOIN users AS u ON u.user_id = o.user_id
JOIN skills AS s ON s.skill_id = o.skill_id
JOIN categories AS c ON c.category_id = s.category_id;

CREATE OR REPLACE VIEW vw_user_skill_wants AS
SELECT u.user_id, u.name AS user_name, s.skill_id, s.skill_name,
       c.category_name
FROM user_wants AS w
JOIN users AS u ON u.user_id = w.user_id
JOIN skills AS s ON s.skill_id = w.skill_id
JOIN categories AS c ON c.category_id = s.category_id;

CREATE OR REPLACE VIEW vw_exchange_request_details AS
SELECT r.request_id, r.sender_id, sender.name AS sender_name,
       r.receiver_id, receiver.name AS receiver_name,
       r.requested_skill_id, requested.skill_name AS requested_skill,
       r.offered_skill_id, offered.skill_name AS offered_skill,
       r.status, r.request_date
FROM exchange_requests AS r
JOIN users AS sender ON sender.user_id = r.sender_id
JOIN users AS receiver ON receiver.user_id = r.receiver_id
JOIN skills AS requested ON requested.skill_id = r.requested_skill_id
JOIN skills AS offered ON offered.skill_id = r.offered_skill_id;

CREATE OR REPLACE VIEW vw_skill_popularity AS
SELECT s.skill_id, s.skill_name, c.category_name,
       COALESCE(offered.provider_count, 0) AS provider_count,
       COALESCE(wanted.wanter_count, 0) AS wanter_count
FROM skills AS s
JOIN categories AS c ON c.category_id = s.category_id
LEFT JOIN (
    SELECT skill_id, COUNT(*) AS provider_count
    FROM user_offers GROUP BY skill_id
) AS offered ON offered.skill_id = s.skill_id
LEFT JOIN (
    SELECT skill_id, COUNT(*) AS wanter_count
    FROM user_wants GROUP BY skill_id
) AS wanted ON wanted.skill_id = s.skill_id;

CREATE OR REPLACE VIEW vw_user_exchange_summary AS
SELECT u.user_id, u.name,
       COALESCE(sent.sent_count, 0) AS requests_sent,
       COALESCE(received.received_count, 0) AS requests_received,
       COALESCE(done.completed_count, 0) AS completed_exchanges
FROM users AS u
LEFT JOIN (
    SELECT sender_id, COUNT(*) AS sent_count
    FROM exchange_requests GROUP BY sender_id
) AS sent ON sent.sender_id = u.user_id
LEFT JOIN (
    SELECT receiver_id, COUNT(*) AS received_count
    FROM exchange_requests GROUP BY receiver_id
) AS received ON received.receiver_id = u.user_id
LEFT JOIN (
    SELECT participant_id, COUNT(*) AS completed_count
    FROM (
        SELECT sender_id AS participant_id, request_id
        FROM exchange_requests WHERE status = 'Completed'
        UNION ALL
        SELECT receiver_id AS participant_id, request_id
        FROM exchange_requests WHERE status = 'Completed'
    ) AS completed_participations
    GROUP BY participant_id
) AS done ON done.participant_id = u.user_id;

-- Example view usage:
-- SELECT * FROM vw_exchange_request_details WHERE status = 'Pending';
-- SELECT * FROM vw_skill_popularity ORDER BY wanter_count DESC;

-- ============================================================
-- C. TRIGGERS
-- ============================================================

DELIMITER $$

-- A request is valid only if its sender offers the skill they exchange
-- and its receiver offers the skill being requested.
CREATE TRIGGER trg_exchange_request_validate_insert
BEFORE INSERT ON exchange_requests
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM user_offers
        WHERE user_id = NEW.sender_id AND skill_id = NEW.offered_skill_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Sender must offer the offered skill before creating a request';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM user_offers
        WHERE user_id = NEW.receiver_id AND skill_id = NEW.requested_skill_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Receiver must offer the requested skill before accepting a request';
    END IF;
END$$

-- Apply the same offer checks if the participants or skills are changed later.
CREATE TRIGGER trg_exchange_request_validate_update
BEFORE UPDATE ON exchange_requests
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM user_offers
        WHERE user_id = NEW.sender_id AND skill_id = NEW.offered_skill_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Sender must offer the offered skill';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM user_offers
        WHERE user_id = NEW.receiver_id AND skill_id = NEW.requested_skill_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Receiver must offer the requested skill';
    END IF;

    IF NEW.status <> OLD.status AND NOT (
        (OLD.status = 'Pending' AND NEW.status IN ('Accepted', 'Rejected', 'Cancelled'))
        OR (OLD.status = 'Accepted' AND NEW.status IN ('Completed', 'Cancelled'))
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid exchange request status transition';
    END IF;
END$$

-- A video uploader must list the skill they are teaching as an offer.
CREATE TRIGGER trg_video_validate_insert
BEFORE INSERT ON videos
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM user_offers
        WHERE user_id = NEW.user_id AND skill_id = NEW.skill_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Video uploader must offer the video skill';
    END IF;
END$$

CREATE TRIGGER trg_video_validate_update
BEFORE UPDATE ON videos
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM user_offers
        WHERE user_id = NEW.user_id AND skill_id = NEW.skill_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Video uploader must offer the video skill';
    END IF;
END$$

DELIMITER ;

-- ============================================================
-- Trigger behavior notes
-- ============================================================
-- 1. The request triggers validate offerings, but do not require the sender
--    or receiver to have a matching row in user_wants. This matches the
--    supplied data model and allows requests without a recorded wish-list.
-- 2. The update trigger permits Pending -> Accepted/Rejected/Cancelled and
--    Accepted -> Completed/Cancelled. Rejected, Completed, and Cancelled are
--    terminal states under this rule.
-- 3. To add an exchange request, first add the sender's offered skill and
--    receiver's offered skill to user_offers.
