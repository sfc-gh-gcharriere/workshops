-- Seed sample data for PII.USERS and ABSENCE.ABSENCES
USE DATABASE HR;

-- Users (PII)
USE SCHEMA PII;
TRUNCATE TABLE IF EXISTS USERS;
INSERT INTO USERS (USERNAME, FIRSTNAME, EMAIL, BIRTHDATE) VALUES
  ('jdoe', 'John', 'john.doe@example.com', '1985-04-12'),
  ('asmith', 'Alice', 'alice.smith@example.com', '1990-09-23'),
  ('bchen', 'Bao', 'bao.chen@example.com', '1978-01-05'),
  ('dlee', 'David', 'david.lee@example.com', '1982-07-18');

-- Absences
USE SCHEMA ABSENCE;
TRUNCATE TABLE IF EXISTS ABSENCES;
INSERT INTO ABSENCES (USERNAME, START_DATE, END_DATE, REASON) VALUES
  ('jdoe', '2025-01-10', '2025-01-12', 'SICK'),
  ('jdoe', '2025-03-05', '2025-03-06', 'PERSONAL'),
  ('asmith', '2025-02-14', '2025-02-14', 'SICK'),
  ('bchen', '2025-01-20', '2025-01-22', 'VACATION'),
  ('dlee', '2025-02-20', '2025-02-22', 'VACATION');

-- Manager mapping
TRUNCATE TABLE IF EXISTS MANAGER_MAP;
INSERT INTO MANAGER_MAP (EMPLOYEE_USERNAME, MANAGER_USERNAME) VALUES
  ('jdoe', 'asmith'),
  ('bchen', 'asmith'),
  ('dlee', 'bchen');