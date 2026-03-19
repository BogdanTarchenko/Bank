-- Дефолтный сотрудник банка
INSERT INTO users (email, first_name, last_name, phone)
VALUES ('employee@bank.com', 'Сотрудник', 'Банка', '+70000000000')
ON CONFLICT (email) DO NOTHING;

INSERT INTO user_roles (user_id, role)
SELECT id, 'EMPLOYEE' FROM users WHERE email = 'employee@bank.com'
ON CONFLICT (user_id, role) DO NOTHING;
