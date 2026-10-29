-- Bonus A : base et utilisateur applicatif sur le cluster InnoDB
-- (exécuté via le MySQL Router, donc sur le primaire, puis répliqué)
CREATE DATABASE IF NOT EXISTS travelo_db;
CREATE USER IF NOT EXISTS 'travelo'@'%' IDENTIFIED BY 'App-Travelo-2026';
GRANT ALL PRIVILEGES ON travelo_db.* TO 'travelo'@'%';
FLUSH PRIVILEGES;
