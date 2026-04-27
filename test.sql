-- Salary Reduction Test: Trigger(trg_prevent_salary_reduction) raises exception

UPDATE employees SET salary = salary * 0.9 WHERE emp_id = 101;
/

-----------------------------------------------------

-- Review Salary

EXECUTE process_annual_salary_review;
/

SELECT * FROM SALARY_AUDIT;
/
