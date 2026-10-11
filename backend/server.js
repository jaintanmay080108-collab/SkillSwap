require('dotenv').config();
const express = require('express');
const cors = require('cors');
const session = require('express-session');
const path = require('path');
const pool = require('./db');
const bcrypt = require('bcryptjs');
const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors({ origin: true, credentials: true }));
app.use(express.json());
app.use(session({
  secret: process.env.SESSION_SECRET || 'dev-only-change-this-secret',
  resave: false, saveUninitialized: false,
  cookie: { httpOnly: true, sameSite: 'lax', secure: false, maxAge: 8 * 60 * 60 * 1000 }
}));
app.use(express.static(path.join(__dirname, '../frontend')));

function requireAuth(req, res, next) {
  if (!req.session.user) return res.status(401).json({ error: 'Please log in first.' });
  next();
}
app.get('/api/health', async (req, res) => {
  try { await pool.query('SELECT 1'); res.json({ ok: true, database: 'connected' }); }
  catch (e) { res.status(500).json({ ok: false, error: 'Database connection failed. Check backend/.env and MySQL.' }); }
});
app.get('/api/me', (req, res) => res.json({ user: req.session.user || null }));

app.post('/api/register', async (req, res) => {
  try {
    const name = String(req.body.name || '').trim();
    const email = String(req.body.email || '').trim().toLowerCase();
    const password = String(req.body.password || '');
    if (!name || !email || password.length < 6) return res.status(400).json({ error: 'Name, valid email, and password (at least 6 characters) are required.' });
    const [existing] = await pool.execute('SELECT user_id FROM users WHERE email = ?', [email]);
    if (existing.length) return res.status(409).json({ error: 'This email is already registered. Try logging in.' });
    const hash = await bcrypt.hash(password, 10);
    const [result] = await pool.execute('INSERT INTO users (name, email, password_hash) VALUES (?, ?, ?)', [name, email, hash]);
    req.session.user = { user_id: result.insertId, name, email };
    res.status(201).json({ message: 'Account created successfully.', user: req.session.user });
  } catch (e) { console.error(e); res.status(500).json({ error: 'Registration failed. Check that the database schema is loaded.' }); }
});

app.post('/api/login', async (req, res) => {
  try {
    const email = String(req.body.email || '').trim().toLowerCase();
    const password = String(req.body.password || '');
    const [rows] = await pool.execute('SELECT user_id, name, email, password_hash FROM users WHERE email = ?', [email]);
    if (!rows.length) return res.status(401).json({ error: 'Email or password is incorrect.' });
    const user = rows[0];
    // The supplied bulk users_data files contain placeholder SHA-256-looking hashes, not usable login passwords.
    // Accounts registered through this website use bcrypt and can log in normally.
    const valid = await bcrypt.compare(password, user.password_hash).catch(() => false);
    if (!valid) return res.status(401).json({ error: 'Email or password is incorrect. For demo, register a fresh account on this website first.' });
    req.session.user = { user_id: user.user_id, name: user.name, email: user.email };
    res.json({ message: 'Logged in successfully.', user: req.session.user });
  } catch (e) { console.error(e); res.status(500).json({ error: 'Login failed.' }); }
});
app.post('/api/logout', (req, res) => req.session.destroy(() => res.json({ message: 'Logged out.' })));

app.get('/api/skills', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT s.skill_id, s.skill_name, s.description, s.category_id, c.category_name FROM skills s JOIN categories c ON c.category_id=s.category_id ORDER BY c.category_name, s.skill_name');
    res.json(rows);
  } catch (e) { console.error(e); res.status(500).json({ error: 'Could not load skills. Make sure Schema.sql has been run.' }); }
});
app.get('/api/categories', async (req, res) => {
  try { const [rows] = await pool.query('SELECT category_id, category_name FROM categories ORDER BY category_name'); res.json(rows); }
  catch (e) { res.status(500).json({ error: 'Could not load categories.' }); }
});
app.get('/api/dashboard', requireAuth, async (req, res) => {
  try {
    const id = req.session.user.user_id;
    const [[offers]] = await pool.execute('SELECT COUNT(*) AS total FROM user_offers WHERE user_id=?', [id]);
    const [[wants]] = await pool.execute('SELECT COUNT(*) AS total FROM user_wants WHERE user_id=?', [id]);
    const [[sent]] = await pool.execute('SELECT COUNT(*) AS total FROM exchange_requests WHERE sender_id=?', [id]);
    const [[received]] = await pool.execute("SELECT COUNT(*) AS total FROM exchange_requests WHERE receiver_id=? AND status='Pending'", [id]);
    const [myOffers] = await pool.execute('SELECT s.skill_id,s.skill_name,o.proficiency_level FROM user_offers o JOIN skills s ON s.skill_id=o.skill_id WHERE o.user_id=? ORDER BY s.skill_name', [id]);
    const [myWants] = await pool.execute('SELECT s.skill_id,s.skill_name FROM user_wants w JOIN skills s ON s.skill_id=w.skill_id WHERE w.user_id=? ORDER BY s.skill_name', [id]);
    res.json({ stats: { offered: offers.total, wanted: wants.total, sent: sent.total, pending: received.total }, offers: myOffers, wants: myWants });
  } catch (e) { console.error('DASHBOARD ERROR:',e); res.status(500).json({ error: 'Could not load dashboard.', details: e.message }); }
});
app.get('/api/my-skills', requireAuth, async (req, res) => {
  try {
    const id = req.session.user.user_id;
    const [offers] = await pool.execute('SELECT s.skill_id,s.skill_name,o.proficiency_level FROM user_offers o JOIN skills s ON s.skill_id=o.skill_id WHERE o.user_id=? ORDER BY s.skill_name', [id]);
    const [wants] = await pool.execute('SELECT s.skill_id,s.skill_name FROM user_wants w JOIN skills s ON s.skill_id=w.skill_id WHERE w.user_id=? ORDER BY s.skill_name', [id]);
    res.json({ offers, wants });
  } catch (e) { res.status(500).json({ error: 'Could not load your skills.' }); }
});
app.post('/api/my-skills/offers', requireAuth, async (req, res) => {
  try {
    const skillId = Number(req.body.skill_id); const level = req.body.proficiency_level || 'Intermediate';
    if (!Number.isInteger(skillId) || !['Beginner','Intermediate','Advanced'].includes(level)) return res.status(400).json({ error: 'Choose a skill and valid proficiency level.' });
    await pool.execute('INSERT INTO user_offers (user_id,skill_id,proficiency_level) VALUES (?,?,?)', [req.session.user.user_id, skillId, level]);
    res.status(201).json({ message: 'Skill added to your offers.' });
  } catch (e) { res.status(e.code === 'ER_DUP_ENTRY' ? 409 : 500).json({ error: e.code === 'ER_DUP_ENTRY' ? 'You already offer this skill.' : 'Could not add skill.' }); }
});
app.delete('/api/my-skills/offers/:skillId', requireAuth, async (req, res) => {
  try { await pool.execute('DELETE FROM user_offers WHERE user_id=? AND skill_id=?', [req.session.user.user_id, Number(req.params.skillId)]); res.json({ message: 'Offered skill removed.' }); }
  catch (e) { res.status(500).json({ error: 'Could not remove skill. Existing requests may depend on this offer.' }); }
});
app.post('/api/my-skills/wants', requireAuth, async (req, res) => {
  try {
    const skillId = Number(req.body.skill_id); if (!Number.isInteger(skillId)) return res.status(400).json({ error: 'Choose a skill.' });
    await pool.execute('INSERT INTO user_wants (user_id,skill_id) VALUES (?,?)', [req.session.user.user_id, skillId]);
    res.status(201).json({ message: 'Skill added to your learning list.' });
  } catch (e) { res.status(e.code === 'ER_DUP_ENTRY' ? 409 : 500).json({ error: e.code === 'ER_DUP_ENTRY' ? 'You already want this skill.' : 'Could not add wanted skill.' }); }
});
app.delete('/api/my-skills/wants/:skillId', requireAuth, async (req, res) => {
  try { await pool.execute('DELETE FROM user_wants WHERE user_id=? AND skill_id=?', [req.session.user.user_id, Number(req.params.skillId)]); res.json({ message: 'Wanted skill removed.' }); }
  catch (e) { res.status(500).json({ error: 'Could not remove wanted skill.' }); }
});

app.get('/api/matches', requireAuth, async (req, res) => {
  try {
    const id = req.session.user.user_id;
    const [rows] = await pool.execute(`SELECT DISTINCT u.user_id,u.name,s.skill_id,s.skill_name,o.proficiency_level
      FROM user_wants w JOIN user_offers o ON o.skill_id=w.skill_id
      JOIN users u ON u.user_id=o.user_id JOIN skills s ON s.skill_id=o.skill_id
      WHERE w.user_id=? AND u.user_id<>? ORDER BY u.name,s.skill_name`, [id,id]);
    res.json(rows);
  } catch (e) { console.error(e); res.status(500).json({ error: 'Could not find matches.' }); }
});
app.post('/api/requests', requireAuth, async (req, res) => {
  try {
    const senderId = req.session.user.user_id;
    const receiverId = Number(req.body.receiver_id), requestedSkillId = Number(req.body.requested_skill_id), offeredSkillId = Number(req.body.offered_skill_id);
    if (![receiverId,requestedSkillId,offeredSkillId].every(Number.isInteger) || receiverId === senderId) return res.status(400).json({ error: 'Select a valid partner and both skills.' });
    const [result] = await pool.execute(`INSERT INTO exchange_requests (sender_id,receiver_id,requested_skill_id,offered_skill_id,status,request_date) VALUES (?,?,?,?, 'Pending', CURDATE())`, [senderId,receiverId,requestedSkillId,offeredSkillId]);
    res.status(201).json({ message: 'Exchange request sent.', request_id: result.insertId });
  } catch (e) { console.error(e); res.status(400).json({ error: e.sqlMessage || 'Could not create request. Ensure you offer the selected skill and the other user offers the requested skill.' }); }
});
app.get('/api/requests', requireAuth, async (req, res) => {
  try {
    const id = req.session.user.user_id;
    const [rows] = await pool.execute(`SELECT r.request_id,r.sender_id,r.receiver_id,r.requested_skill_id,r.offered_skill_id,r.status,r.request_date,
      su.name AS sender_name,ru.name AS receiver_name,rs.skill_name AS requested_skill,os.skill_name AS offered_skill,
      CASE WHEN r.sender_id=? THEN 'Sent' ELSE 'Received' END AS direction
      FROM exchange_requests r JOIN users su ON su.user_id=r.sender_id JOIN users ru ON ru.user_id=r.receiver_id
      JOIN skills rs ON rs.skill_id=r.requested_skill_id JOIN skills os ON os.skill_id=r.offered_skill_id
      WHERE r.sender_id=? OR r.receiver_id=? ORDER BY r.request_id DESC`, [id,id,id]);
    res.json(rows);
  } catch (e) { res.status(500).json({ error: 'Could not load requests.' }); }
});
app.patch('/api/requests/:id/status', requireAuth, async (req, res) => {
  try {
    const status = req.body.status; if (!['Accepted','Rejected','Cancelled','Completed'].includes(status)) return res.status(400).json({ error: 'Invalid status.' });
    const [rows] = await pool.execute('SELECT sender_id,receiver_id,status FROM exchange_requests WHERE request_id=?', [Number(req.params.id)]);
    if (!rows.length) return res.status(404).json({ error: 'Request not found.' });
    const r = rows[0], id = req.session.user.user_id;
    if (status === 'Completed' && r.sender_id !== id && r.receiver_id !== id) return res.status(403).json({ error: 'Not allowed.' });
    if (['Accepted','Rejected'].includes(status) && r.receiver_id !== id) return res.status(403).json({ error: 'Only the receiver can respond.' });
    if (status === 'Cancelled' && r.sender_id !== id) return res.status(403).json({ error: 'Only the sender can cancel.' });
    const [result] = await pool.execute('UPDATE exchange_requests SET status=? WHERE request_id=?', [status, Number(req.params.id)]);
    res.json({ message: 'Request status updated.' });
  } catch (e) { res.status(400).json({ error: e.sqlMessage || 'Could not update request status.' }); }
});
app.get('/api/videos', async (req, res) => {
  try { const [rows] = await pool.query(`SELECT v.video_id,v.title,v.video_url,v.duration_minutes,v.upload_date,u.name AS uploader,s.skill_name,c.category_name FROM videos v JOIN users u ON u.user_id=v.user_id JOIN skills s ON s.skill_id=v.skill_id JOIN categories c ON c.category_id=s.category_id ORDER BY v.upload_date DESC LIMIT 100`); res.json(rows); }
  catch (e) { res.status(500).json({ error: 'Could not load tutorials.' }); }
});
app.post('/api/videos', requireAuth, async (req, res) => {
  try {
    const { title, video_url, duration_minutes, skill_id } = req.body;
    if (!title || !video_url || !Number.isInteger(Number(skill_id)) || !Number.isInteger(Number(duration_minutes)) || Number(duration_minutes)<1) return res.status(400).json({ error: 'Enter title, valid URL, duration, and skill.' });
    const [result] = await pool.execute('INSERT INTO videos (title,video_url,duration_minutes,upload_date,user_id,skill_id) VALUES (?,?,?,CURDATE(),?,?)', [String(title).trim(),String(video_url).trim(),Number(duration_minutes),req.session.user.user_id,Number(skill_id)]);
    res.status(201).json({ message: 'Tutorial added.', video_id: result.insertId });
  } catch (e) { res.status(400).json({ error: e.sqlMessage || 'Could not add tutorial. You must offer the skill before uploading a tutorial.' }); }
});

app.get('*', (req, res) => res.sendFile(path.join(__dirname, '../frontend/index.html')));
app.listen(PORT, () => console.log(`SkillSwap running at http://localhost:${PORT}`));
