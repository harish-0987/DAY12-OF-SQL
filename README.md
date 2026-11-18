# 📘 Day 12 of SQL: Subqueries, Correlated Subqueries & Conditional Logic

Welcome to **Day 12 of SQL**! 🚀

In this module, we explore advanced query structures and conditional logic:
1. **Standard Subqueries** (10 Queries): Scalar, single-row, multi-row, derived tables, and subqueries across `WHERE`, `SELECT`, `FROM`, and `HAVING`.
2. **Correlated Subqueries & EXISTS** (10 Queries): Row-by-row execution referencing outer queries, `EXISTS`, and `NOT EXISTS`.
3. **Conditional Functions**: `CASE WHEN`, `IF()`, and `COALESCE()` for dynamic categorization and robust `NULL` handling.

---

## 📑 Table of Contents
1. [Module 1: Standard Subqueries (10 Queries)](#1-module-1-standard-subqueries-10-queries)
   - [Subquery Types](#subquery-types)
   - [Queries 1 through 10](#queries-1-through-10)
2. [Module 2: Correlated Subqueries & EXISTS (10 Queries)](#2-module-2-correlated-subqueries--exists-10-queries)
   - [How Correlated Subqueries Work](#how-correlated-subqueries-work)
   - [EXISTS vs IN: Performance Mental Model](#exists-vs-in-performance-mental-model)
   - [Queries 11 through 20](#queries-11-through-20)
3. [Module 3: CASE WHEN, IF, COALESCE (Conditional Logic)](#3-module-3-case-when-if-coalesce-conditional-logic)
   - [CASE WHEN Statement](#case-when-statement)
   - [IF() Function (MySQL)](#if-function-mysql)
   - [COALESCE() Function](#coalesce-function)
   - [Queries 21 through 26](#queries-21-through-26)
4. [Summary Cheat Sheet](#4-summary-cheat-sheet)

---

## 1. Module 1: Standard Subqueries (10 Queries)

A **subquery** (or inner query) is an SQL query nested inside another query (the outer query). The inner query executes first, and its result is consumed by the outer query.

### Subquery Types
- **Scalar Subquery**: Returns exactly **one single value** (1 row, 1 column).
- **Single-Row Subquery**: Returns 1 row with one or more columns; used with `=`, `<`, `>`, `<=`, `>=`.
- **Multi-Row Subquery**: Returns multiple rows; used with `IN`, `NOT IN`, `ANY`, `ALL`.
- **Derived Table**: A subquery inside the `FROM` clause that functions as a temporary in-memory table.

```sql
-- 1. Scalar in WHERE: Employees earning above company average
SELECT emp_name, salary FROM employees 
WHERE salary > (SELECT AVG(salary) FROM employees);

-- 2. Scalar in WHERE: Employee with maximum salary
SELECT emp_name, salary FROM employees 
WHERE salary = (SELECT MAX(salary) FROM employees);

-- 3. Multi-Row with IN: Departments in Tech Park
SELECT emp_name, dept_id, salary FROM employees 
WHERE dept_id IN (SELECT dept_id FROM departments WHERE location = 'Tech Park');

-- 4. Multi-Row with NOT IN: Exclude HR and Finance
SELECT emp_name, salary FROM employees 
WHERE dept_id NOT IN (SELECT dept_id FROM departments WHERE dept_name IN ('Human Resources', 'Finance'));

-- 5. Comparison (<): Earning less than maximum HR salary
SELECT emp_name, salary FROM employees 
WHERE salary < (SELECT MAX(salary) FROM employees WHERE dept_id = 2);

-- 6. ALL: Salary strictly higher than ALL employees in HR
SELECT emp_name, salary FROM employees 
WHERE salary > ALL (SELECT salary FROM employees WHERE dept_id = 2);

-- 7. ANY: Salary higher than AT LEAST ONE employee in Engineering
SELECT emp_name, salary FROM employees 
WHERE salary > ANY (SELECT salary FROM employees WHERE dept_id = 1);

-- 8. Subquery in SELECT: Side-by-side comparison against company average
SELECT 
    emp_name, 
    salary,
    ROUND((SELECT AVG(salary) FROM employees), 2) AS overall_avg,
    ROUND(salary - (SELECT AVG(salary) FROM employees), 2) AS diff_from_avg
FROM employees;

-- 9. Derived Table (Subquery in FROM): Summarized metrics filter
SELECT dept_id, avg_salary 
FROM (
    SELECT dept_id, ROUND(AVG(salary), 2) AS avg_salary 
    FROM employees 
    GROUP BY dept_id
) AS dept_summary 
WHERE avg_salary > 65000;

-- 10. Subquery in HAVING: Departments with avg salary above company average
SELECT dept_id, ROUND(AVG(salary), 2) AS dept_avg 
FROM employees 
GROUP BY dept_id 
HAVING AVG(salary) > (SELECT AVG(salary) FROM employees);
```

---

## 2. Module 2: Correlated Subqueries & EXISTS (10 Queries)

### How Correlated Subqueries Work
Unlike standard subqueries which execute **once** before the outer query, a **Correlated Subquery** references a column from the outer query. It is evaluated **once for each candidate row** evaluated by the outer query:

```
For each row in outer query (e1):
  ┌────────────────────────────────────────────────────────┐
  │ Pass e1.dept_id into inner query                       │
  │ Inner query calculates AVG(salary) for THAT department │
  │ Check if e1.salary > that department's average         │
  └────────────────────────────────────────────────────────┘
```

### EXISTS vs IN: Performance Mental Model
- **`EXISTS`**: Tests for the **existence** of rows. As soon as the database finds a single matching row, it halts scanning for that row (**short-circuits**). It handles `NULL` values gracefully and is often faster on large datasets.
- **`NOT EXISTS`**: Returns `TRUE` if the subquery returns **zero rows**.

```sql
-- 11. Correlated in WHERE: Earns MORE than own department average
SELECT e1.emp_name, e1.dept_id, e1.salary
FROM employees e1
WHERE e1.salary > (
    SELECT AVG(e2.salary) 
    FROM employees e2 
    WHERE e2.dept_id = e1.dept_id
);

-- 12. Correlated in WHERE: Earns the MINIMUM in own department
SELECT e1.emp_name, e1.dept_id, e1.salary
FROM employees e1
WHERE e1.salary = (
    SELECT MIN(e2.salary) 
    FROM employees e2 
    WHERE e2.dept_id = e1.dept_id
);

-- 13. Correlated in SELECT: Compute department average alongside each employee
SELECT 
    e1.emp_name, 
    e1.salary,
    (SELECT ROUND(AVG(e2.salary), 2) 
     FROM employees e2 
     WHERE e2.dept_id = e1.dept_id) AS dept_avg_salary
FROM employees e1;

-- 14. Correlated in SELECT: Count total orders per employee
SELECT 
    e.emp_name,
    (SELECT COUNT(*) FROM orders o WHERE o.emp_id = e.emp_id) AS total_orders
FROM employees e;

-- 15. EXISTS: Departments that have AT LEAST ONE employee
SELECT d.dept_name FROM departments d
WHERE EXISTS (
    SELECT 1 FROM employees e WHERE e.dept_id = d.dept_id
);

-- 16. NOT EXISTS: Departments with ZERO employees (Marketing)
SELECT d.dept_name FROM departments d
WHERE NOT EXISTS (
    SELECT 1 FROM employees e WHERE e.dept_id = d.dept_id
);

-- 17. EXISTS: Employees who have placed orders
SELECT e.emp_name, e.salary FROM employees e
WHERE EXISTS (
    SELECT 1 FROM orders o WHERE o.emp_id = e.emp_id
);

-- 18. NOT EXISTS: Employees who have NEVER placed any order
SELECT e.emp_name, e.salary FROM employees e
WHERE NOT EXISTS (
    SELECT 1 FROM orders o WHERE o.emp_id = e.emp_id
);

-- 19. EXISTS with filter: Employees handling orders > 3,000
SELECT e.emp_name, e.salary FROM employees e
WHERE EXISTS (
    SELECT 1 FROM orders o 
    WHERE o.emp_id = e.emp_id AND o.order_amount > 3000.00
);

-- 20. Correlated Subquery: Sum order volume per employee with COALESCE
SELECT 
    e.emp_name,
    COALESCE((SELECT SUM(o.order_amount) FROM orders o WHERE o.emp_id = e.emp_id), 0) AS total_sales
FROM employees e;
```

---

## 3. Module 3: CASE WHEN, IF, COALESCE (Conditional Logic)

### CASE WHEN Statement
The ANSI SQL standard construct for conditional branch logic (similar to `if-else if-else` in programming):

```sql
CASE 
    WHEN condition1 THEN result1
    WHEN condition2 THEN result2
    ELSE default_result
END
```

### IF() Function (MySQL)
Ternary shorthand for two-branch logic: `IF(condition, value_if_true, value_if_false)`.

### COALESCE() Function
Returns the **first non-null value** in a list of arguments: `COALESCE(val1, val2, val3, fallback)`.

```sql
-- 21. Categorizing salary tiers with CASE WHEN
SELECT 
    emp_name,
    salary,
    CASE 
        WHEN salary >= 85000 THEN 'Tier 1: Senior Executive'
        WHEN salary >= 65000 THEN 'Tier 2: Mid-Level Professional'
        ELSE 'Tier 3: Associate'
    END AS salary_grade
FROM employees;

-- 22. Multi-column CASE WHEN
SELECT 
    emp_name,
    CASE 
        WHEN dept_id = 1 AND salary >= 80000 THEN 'Senior Engineer'
        WHEN dept_id = 1 THEN 'Junior Engineer'
        WHEN dept_id = 3 THEN 'Finance Specialist'
        ELSE 'General Staff'
    END AS role_title
FROM employees;

-- 23. Custom sorting with CASE WHEN in ORDER BY
SELECT emp_name, dept_id, salary
FROM employees
ORDER BY 
    CASE dept_id
        WHEN 1 THEN 1  -- Engineering first
        WHEN 3 THEN 2  -- Finance second
        WHEN 2 THEN 3  -- HR third
        ELSE 4
    END ASC, salary DESC;

-- 24. IF() ternary logic (MySQL)
SELECT 
    emp_name, 
    salary,
    IF(salary >= 70000, 'Eligible for Leadership', 'Standard Track') AS track_status
FROM employees;

-- 25. COALESCE: Fallback for NULL bonus / commission
SELECT 
    emp_name,
    salary,
    COALESCE(bonus, commission, 0.00) AS first_available_incentive,
    salary + COALESCE(bonus, 0.00) + COALESCE(commission, 0.00) AS total_compensation
FROM employees;

-- 26. Combined CASE WHEN + COALESCE
SELECT 
    emp_name,
    COALESCE(bonus, 0.00) AS bonus_received,
    CASE 
        WHEN bonus IS NOT NULL AND bonus >= 5000 THEN 'High Performer'
        WHEN bonus IS NOT NULL THEN 'Standard Performer'
        ELSE 'No Bonus Awarded'
    END AS performance_evaluation
FROM employees;
```

---

## 4. Summary Cheat Sheet

| Feature | Syntax / Operator | Purpose |
| :--- | :--- | :--- |
| **Scalar Subquery** | `(SELECT AVG(col) FROM t)` | Returns a single value |
| **Multi-Row Subquery** | `IN (SELECT col FROM t)` | Matches against a column list |
| **Derived Table** | `FROM (SELECT ...) AS dt` | Inline view in `FROM` clause |
| **Correlated Subquery** | `WHERE col > (SELECT ... WHERE inner.id = outer.id)` | Evaluated per outer row |
| **EXISTS** | `WHERE EXISTS (SELECT 1 ...)` | Checks if at least 1 matching row exists |
| **NOT EXISTS** | `WHERE NOT EXISTS (SELECT 1 ...)` | Checks if zero matching rows exist |
| **CASE WHEN** | `CASE WHEN cond THEN val ELSE default END` | Standard SQL conditional branching |
| **IF()** | `IF(cond, true_val, false_val)` | MySQL ternary conditional function |
| **COALESCE()** | `COALESCE(val1, val2, fallback)` | Returns first non-NULL expression |

---

⭐ **Stay tuned for Day 13!** Keep practicing and writing queries.
