--
-- SAMPLE DUMMY DATABASE FOR REPLICATION TESTING
-- Contains schema, tables, indexes, functions, triggers, dummy data
--


---------------------------------------------------------
-- 1. CREATE SCHEMA
---------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS company;
SET search_path TO company;


---------------------------------------------------------
-- 2. MASTER TABLES
---------------------------------------------------------

-- USERS TABLE
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- DEPARTMENTS TABLE
CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(200) NOT NULL,
    location VARCHAR(200)
);

-- EMPLOYEES TABLE
CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id) ON DELETE CASCADE,
    dept_id INT REFERENCES departments(dept_id) ON DELETE SET NULL,
    position VARCHAR(200),
    salary NUMERIC(12,2),
    hired_at DATE DEFAULT CURRENT_DATE
);

-- PROJECTS TABLE
CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(255) NOT NULL,
    start_date DATE,
    end_date DATE
);

-- EMPLOYEE PROJECT LINK TABLE
CREATE TABLE employee_projects (
    emp_id INT REFERENCES employees(emp_id) ON DELETE CASCADE,
    project_id INT REFERENCES projects(project_id) ON DELETE CASCADE,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (emp_id, project_id)
);


---------------------------------------------------------
-- 3. CREATE VIEW
---------------------------------------------------------
CREATE OR REPLACE VIEW v_employee_summary AS
SELECT 
    e.emp_id,
    u.full_name,
    d.dept_name,
    e.position,
    e.salary
FROM employees e
JOIN users u ON e.user_id = u.user_id
LEFT JOIN departments d ON e.dept_id = d.dept_id;


---------------------------------------------------------
-- 4. CREATE FUNCTION & TRIGGER
---------------------------------------------------------

-- FUNCTION TO LOG INSERTS
CREATE TABLE audit_log (
    log_id SERIAL PRIMARY KEY,
    table_name TEXT,
    record_id INT,
    action TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION log_user_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log(table_name, record_id, action)
    VALUES ('users', NEW.user_id, 'INSERT');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_user_insert
AFTER INSERT ON users
FOR EACH ROW EXECUTE PROCEDURE log_user_insert();


---------------------------------------------------------
-- 5. INSERT DEPARTMENTS
---------------------------------------------------------
INSERT INTO departments (dept_name, location) VALUES
('Engineering', 'New York'),
('Finance', 'Chicago'),
('Marketing', 'Los Angeles'),
('Human Resources', 'Boston'),
('IT Support', 'San Francisco');


---------------------------------------------------------
-- 6. INSERT PROJECTS
---------------------------------------------------------
INSERT INTO projects (project_name, start_date, end_date) VALUES
('Apollo Revamp', '2024-01-01', '2024-12-31'),
('Hermes Migration', '2024-02-01', NULL),
('Orion QA Initiative', '2024-03-15', '2024-09-15'),
('Zeus Infrastructure', '2024-04-01', NULL);


---------------------------------------------------------
-- 7. GENERATE 200 USERS
---------------------------------------------------------
DO $$
DECLARE
    i INT;
BEGIN
    FOR i IN 1..200 LOOP
        INSERT INTO users(full_name, email)
        VALUES (
            'User ' || i,
            'user' || i || '@example.com'
        );
    END LOOP;
END;
$$;


---------------------------------------------------------
-- 8. GENERATE 200 EMPLOYEES
---------------------------------------------------------
DO $$
DECLARE
    i INT;
BEGIN
    FOR i IN 1..200 LOOP
        INSERT INTO employees(user_id, dept_id, position, salary)
        VALUES (
            i,
            (i % 5) + 1,
            'Position ' || (i % 10),
            3000 + (i * 15)
        );
    END LOOP;
END;
$$;


---------------------------------------------------------
-- 9. GENERATE 300 EMPLOYEE–PROJECT ASSIGNMENTS
---------------------------------------------------------
DO $$
DECLARE
    i INT;
BEGIN
    FOR i IN 1..300 LOOP
        INSERT INTO employee_projects(emp_id, project_id)
        VALUES (
            (i % 200) + 1,
            (i % 4) + 1
        )
        ON CONFLICT DO NOTHING;
    END LOOP;
END;
$$;


---------------------------------------------------------
-- 10. TEST QUERIES FOR REPLICATION
---------------------------------------------------------

-- 10.1 Check summary
SELECT COUNT(*) AS total_users FROM users;
SELECT COUNT(*) AS total_employees FROM employees;
SELECT COUNT(*) AS total_projects FROM projects;

-- 10.2 View output
SELECT * FROM v_employee_summary LIMIT 20;

-- 10.3 Trigger logs
SELECT * FROM audit_log ORDER BY log_id DESC LIMIT 10;
