# SkillSwap — DBMS project frontend + backend starter

This is a simple, responsive HTML/CSS/JavaScript frontend connected to an Express/Node.js API and MySQL. It uses the supplied `skill_exchange` schema: `users`, `categories`, `skills`, `user_offers`, `user_wants`, `exchange_requests`, and `videos`.

## Included pages
- Home / landing page
- Register and login
- Dashboard with live counts and current skill lists
- Add/remove offered and wanted skills
- Find matches from MySQL
- Create exchange requests and accept/reject/cancel/complete them
- Browse and add tutorials

## 1. Database setup (coordinate with your DB teammate)
1. Open MySQL Workbench and connect to your local MySQL server.
2. Open and run `database/Schema.sql` first. **Warning:** this supplied schema starts with `DROP DATABASE IF EXISTS skill_exchange;`, so it deletes/recreates that database. Back up anything important first. It also inserts 10 demo users, categories, skills, offers, wants, requests and videos.
3. To load the 1,000 bulk user records, run `users_data_1_of_5.sql` through `users_data_5_of_5.sql` in order. Then optionally run `SampleData(1001 to 5000).sql` if your team wants the additional 4,000 users. These files add user records only; they do not give those users skill offers/wants.
4. Run `database/query_triggers.sql` after the schema and any initial sample data. It creates the supplied views and triggers. Run it once per freshly-created schema (or use `CREATE OR REPLACE`/drop triggers if rerunning triggers produces “already exists”).

The SQL files originally supplied with this project are copied into `database/` only when they are included in this bundle. If you already have them separately, use those originals.

## 2. Backend setup
1. Install Node.js LTS if not already installed.
2. Open a terminal in the `backend` folder.
3. Run:
   ```bash
   npm install
   ```
4. Copy `.env.example` to `.env` and set your MySQL password. If your MySQL root account has no password, leave `DB_PASSWORD=` empty.
5. Start the API:
   ```bash
   npm start
   ```
6. Visit `http://localhost:5000`. Check `http://localhost:5000/api/health` to confirm database connection.

The frontend is served by Express, so do not open the HTML files directly from File Explorer and do not use Live Server for the connected version. Open `http://localhost:5000` instead.

## 3. Demo flow
1. Open `http://localhost:5000/register.html` and create a new account.
2. Add at least one skill under **My Skills → Skills you offer** and at least one under **Skills you want to learn**.
3. Open another browser/incognito window and register a second demo account. Add offered skills that match the first account's wanted skills.
4. In the first account, open **Find Matches** and send a request. The sender must choose an offered skill in return.
5. Log into the second account and accept the incoming request under **Requests**.
6. Mark it completed, and browse/add tutorials under **Tutorials**.

## Important notes / known limitations
- The bulk `users_data_*.sql` records have 64-character placeholder hashes, not passwords known to the team. You cannot log in to those preloaded accounts unless you know their original passwords/hash scheme. For a reliable live demo, register fresh accounts through this website; those passwords are stored using bcrypt.
- `Schema.sql` is the source of truth for table and column names. The app deliberately uses those exact names and the supplied DB model, rather than an assumed `Sessions`/`Ratings` schema.
- The provided schema has `exchange_requests`, not a separate sessions or ratings table. This UI uses the request's `Accepted → Completed` status for the exchange lifecycle and does not invent extra tables. If the database team adds sessions/ratings later, add matching API routes and pages after they provide the final schema.
- `videos` insert trigger requires a user to offer that skill before adding a tutorial.
- `express-session` uses its default in-memory store, suitable for a local college demo, not production deployment.
- This is a college demo starter, not production-ready authentication. For deployment, use HTTPS, a persistent session store, CSRF protection, and stricter validation/rate limiting.

## Files
```text
SkillSwapProject/
├── frontend/          HTML, CSS, browser JavaScript
├── backend/           Express API + MySQL connection
└── database/           Schema and project SQL files (add originals here)
```
