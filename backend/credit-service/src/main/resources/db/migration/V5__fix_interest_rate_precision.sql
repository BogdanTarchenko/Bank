-- DECIMAL(5,2) допускает макс. 999.99 — при больших значениях (напр. суммы) возникает overflow
ALTER TABLE tariffs ALTER COLUMN interest_rate TYPE DECIMAL(10,4);
