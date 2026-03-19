-- Дефолтный сотрудник банка: employee@bank.com / employee123
INSERT INTO auth_users (email, password_hash, enabled)
VALUES ('employee@bank.com', '{bcrypt}$2b$12$OM38.wRRd7cKZ2I7MU2J0OJQMgooKiB78MTi3QWiPVskOrmykueIa', TRUE)
ON CONFLICT (email) DO NOTHING;
