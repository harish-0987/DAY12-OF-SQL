-- ====================================================================
-- DAY 12 OF SQL: SUBQUERIES, CORRELATED SUBQUERIES & CONDITIONAL LOGIC
-- ====================================================================
-- Topics:
--   Part 1: Standard Subqueries                 (10 Queries)
--   Part 2: Correlated Subqueries & EXISTS     (10 Queries)
--   Part 3: CASE WHEN, IF, COALESCE             (Conditional Logic)
-- ====================================================================

-- --------------------------------------------------------------------
-- SETUP: DATABASE & TABLES
-- --------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS day12_db;
USE day12_db;

DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS departments;

-- 1. Departments Table
CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50) NOT NULL,
    location VARCHAR(50) NOT NULL
);

-- 2. Employees Table
CREATE TABLE employees (
    emp_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_name VARCHAR(50) NOT NULL,
    dept_id INT,
    salary DECIMAL(10, 2) NOT NULL,
    bonus DECIMAL(10, 2) DEFAULT NULL,
    commission DECIMAL(10, 2) DEFAULT NULL,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

-- 3. Orders Table (for EXISTS & Subquery demonstrations)
CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_id INT,
    order_amount DECIMAL(10, 2) NOT NULL,
    order_date DATE NOT NULL,
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
);

-- Insert Sample Departments
INSERT INTO departments (dept_id, dept_name, location) VALUES
(1, 'Engineering', 'Tech Park'),
(2, 'Human Resources', 'Building A'),
(3, 'Finance', 'Building B'),
(4, 'Marketing', 'Building C'); -- Department with NO employees

-- Insert Sample Employees
INSERT INTO employees (emp_name, dept_id, salary, bonus, commission) VALUES
('Harish',  1, 95000.00, 8000.00, 2000.00),
('Rahul',   1, 72000.00, 5000.00, NULL),
('Amit',    1, 88000.00, NULL,    1500.00),
('Priya',   2, 58000.00, 3000.00, NULL),
('Vikram',  2, 48000.00, NULL,    NULL),
('Sneha',   3, 75000.00, 6000.00, 3000.00),
('Ananya',  3, 82000.00, NULL,    NULL);

-- Insert Sample Orders
INSERT INTO orders (emp_id, order_amount, order_date) VALUES
(1, 1500.00, '2024-01-15'),
(1, 3200.00, '2024-02-10'),
(2, 450.00,  '2024-01-20'),
(3, 2100.00, '2024-03-05'),
(6, 5000.00, '2024-02-28');


-- ====================================================================
-- PART 1: STANDARD SUBQUERIES (10 QUERIES)
-- ====================================================================

-- Query 1: Scalar Subquery in WHERE - Employees earning more than company average
SELECT emp_name, salary 
FROM employees 
WHERE salary > (SELECT AVG(salary) FROM employees);

-- Query 2: Subquery finding the employee with the maximum salary
SELECT emp_name, salary 
FROM employees 
WHERE salary = (SELECT MAX(salary) FROM employees);

-- Query 3: Subquery with IN - Employees working in departments located in 'Tech Park'
SELECT emp_name, dept_id, salary 
FROM employees 
WHERE dept_id IN (SELECT dept_id FROM departments WHERE location = 'Tech Park');

-- Query 4: Subquery with NOT IN - Employees NOT in HR or Finance
SELECT emp_name, salary 
FROM employees 
WHERE dept_id NOT IN (SELECT dept_id FROM departments WHERE dept_name IN ('Human Resources', 'Finance'));

-- Query 5: Subquery with comparison operator (<) - Employees earning less than maximum HR salary
SELECT emp_name, salary 
FROM employees 
WHERE salary < (SELECT MAX(salary) FROM employees WHERE dept_id = 2);

-- Query 6: Subquery with ALL operator - Salary greater than ALL employees in HR
SELECT emp_name, salary 
FROM employees 
WHERE salary > ALL (SELECT salary FROM employees WHERE dept_id = 2);

-- Query 7: Subquery with ANY operator - Salary greater than AT LEAST ONE employee in Engineering
SELECT emp_name, salary 
FROM employees 
WHERE salary > ANY (SELECT salary FROM employees WHERE dept_id = 1);

-- Query 8: Subquery in SELECT clause - Display employee salary alongside overall company average
SELECT 
    emp_name, 
    salary,
    ROUND((SELECT AVG(salary) FROM employees), 2) AS overall_avg_salary,
    ROUND(salary - (SELECT AVG(salary) FROM employees), 2) AS difference_from_avg
FROM employees;

-- Query 9: Subquery in FROM clause (Derived Table / Inline View)
-- Calculate max and avg salary of department summary statistics
SELECT 
    dept_summary.dept_id,
    dept_summary.avg_salary,
    dept_summary.total_employees
FROM (
    SELECT dept_id, ROUND(AVG(salary), 2) AS avg_salary, COUNT(*) AS total_employees
    FROM employees
    GROUP BY dept_id
) AS dept_summary
WHERE dept_summary.avg_salary > 65000;

-- Query 10: Subquery in HAVING clause - Departments with average salary greater than company average
SELECT dept_id, ROUND(AVG(salary), 2) AS dept_avg_salary
FROM employees
GROUP BY dept_id
HAVING AVG(salary) > (SELECT AVG(salary) FROM employees);


-- ====================================================================
-- PART 2: CORRELATED SUBQUERIES & EXISTS (10 QUERIES)
-- ====================================================================

-- Query 11: Classic Correlated Subquery in WHERE
-- Find employees who earn MORE than the average salary of THEIR OWN department
SELECT e1.emp_name, e1.dept_id, e1.salary
FROM employees e1
WHERE e1.salary > (
    SELECT AVG(e2.salary) 
    FROM employees e2 
    WHERE e2.dept_id = e1.dept_id
);

-- Query 12: Correlated Subquery in WHERE
-- Find employees who earn the MINIMUM salary within THEIR OWN department
SELECT e1.emp_name, e1.dept_id, e1.salary
FROM employees e1
WHERE e1.salary = (
    SELECT MIN(e2.salary)
    FROM employees e2
    WHERE e2.dept_id = e1.dept_id
);

-- Query 13: Correlated Subquery in SELECT
-- Display employee salary along with their specific department's average salary
SELECT 
    e1.emp_name,
    e1.salary,
    (SELECT ROUND(AVG(e2.salary), 2) 
     FROM employees e2 
     WHERE e2.dept_id = e1.dept_id) AS dept_avg_salary
FROM employees e1;

-- Query 14: Correlated Subquery counting total orders handled per employee
SELECT 
    e.emp_name,
    (SELECT COUNT(*) FROM orders o WHERE o.emp_id = e.emp_id) AS total_orders
FROM employees e;

-- Query 15: EXISTS Operator - Find departments that have AT LEAST ONE employee
SELECT d.dept_id, d.dept_name
FROM departments d
WHERE EXISTS (
    SELECT 1 FROM employees e WHERE e.dept_id = d.dept_id
);

-- Query 16: NOT EXISTS Operator - Find departments that have ZERO employees
SELECT d.dept_id, d.dept_name
FROM departments d
WHERE NOT EXISTS (
    SELECT 1 FROM employees e WHERE e.dept_id = d.dept_id
);

-- Query 17: EXISTS Operator - Find employees who have placed at least one order
SELECT e.emp_id, e.emp_name, e.salary
FROM employees e
WHERE EXISTS (
    SELECT 1 FROM orders o WHERE o.emp_id = e.emp_id
);

-- Query 18: NOT EXISTS Operator - Find employees who have NEVER placed any order
SELECT e.emp_id, e.emp_name, e.salary
FROM employees e
WHERE NOT EXISTS (
    SELECT 1 FROM orders o WHERE o.emp_id = e.emp_id
);

-- Query 19: EXISTS with Filter - Employees who handled high-value orders (> 3,000)
SELECT e.emp_name, e.salary
FROM employees e
WHERE EXISTS (
    SELECT 1 FROM orders o 
    WHERE o.emp_id = e.emp_id AND o.order_amount > 3000.00
);

-- Query 20: Correlated Subquery with Cumulative Sum / Total Order Value
SELECT 
    e.emp_name,
    COALESCE((SELECT SUM(o.order_amount) FROM orders o WHERE o.emp_id = e.emp_id), 0) AS total_sales_volume
FROM employees e;


-- ====================================================================
-- PART 3: CASE WHEN, IF, COALESCE (CONDITIONAL LOGIC)
-- ====================================================================

-- Query 21: Simple CASE WHEN - Categorize employees by salary tier
SELECT 
    emp_name,
    salary,
    CASE 
        WHEN salary >= 85000 THEN 'Tier 1: Senior Executive'
        WHEN salary >= 65000 THEN 'Tier 2: Mid-Level Professional'
        ELSE 'Tier 3: Associate'
    END AS salary_grade
FROM employees;

-- Query 22: CASE WHEN with Multiple Conditions
SELECT 
    emp_name,
    dept_id,
    salary,
    CASE 
        WHEN dept_id = 1 AND salary >= 80000 THEN 'Senior Engineer'
        WHEN dept_id = 1 THEN 'Junior Engineer'
        WHEN dept_id = 3 THEN 'Finance Specialist'
        ELSE 'General Staff'
    END AS role_title
FROM employees;

-- Query 23: CASE WHEN in ORDER BY (Custom Sorting Order)
-- Custom sort: Engineering first, then Finance, then HR
SELECT emp_name, dept_id, salary
FROM employees
ORDER BY 
    CASE dept_id
        WHEN 1 THEN 1
        WHEN 3 THEN 2
        WHEN 2 THEN 3
        ELSE 4
    END ASC, salary DESC;

-- Query 24: IF Function (MySQL Specific Two-Branch Ternary Logic)
-- Syntax: IF(condition, value_if_true, value_if_false)
SELECT 
    emp_name,
    salary,
    IF(salary >= 70000, 'Eligible for Leadership Program', 'Standard Track') AS status
FROM employees;

-- Query 25: COALESCE Function - Handling NULL values
-- Returns the first non-null expression from bonus, commission, or 0.00
SELECT 
    emp_name,
    salary,
    bonus,
    commission,
    COALESCE(bonus, commission, 0.00) AS first_available_incentive,
    salary + COALESCE(bonus, 0.00) + COALESCE(commission, 0.00) AS total_compensation
FROM employees;

-- Query 26: Combined CASE WHEN + COALESCE
SELECT 
    emp_name,
    COALESCE(bonus, 0.00) AS bonus_received,
    CASE 
        WHEN bonus IS NOT NULL AND bonus >= 5000 THEN 'High Performer'
        WHEN bonus IS NOT NULL THEN 'Standard Performer'
        ELSE 'No Bonus Awarded'
    END AS performance_evaluation
FROM employees;
