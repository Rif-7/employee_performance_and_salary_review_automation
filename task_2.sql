CREATE OR REPLACE PROCEDURE process_annual_salary_review
IS
    CURSOR c_emp_reviews IS
        -- Filtering employee performance score for the last 4 quarters
        WITH last_year_performance AS (
            SELECT
                emp_id,
                perf_score
            FROM emp_performance
            WHERE review_date >= ADD_MONTHS(SYSDATE, -12)
        ),

        -- Calculates the average employee performance score in the last 4 quarters
        emp_averages AS (
            SELECT
                e.emp_id,
                e.emp_name,
                e.department,
                e.salary                  AS old_salary,
                NVL(AVG(p.perf_score), 0) AS avg_score
            FROM employees e
            LEFT JOIN last_year_performance p
                   ON e.emp_id = p.emp_id
            WHERE e.status = 'ACTIVE'
            GROUP BY
                e.emp_id,
                e.emp_name,
                e.department,
                e.salary
        )
        -- Calculates the rank within department
        SELECT
            emp_id,
            old_salary,
            avg_score,
            RANK() OVER (
                PARTITION BY department
                ORDER BY avg_score DESC
            ) AS dept_rank
        FROM emp_averages;

    v_new_salary NUMBER(10, 2);
    v_reason     VARCHAR2(255);
    v_audit_id   NUMBER;

BEGIN
    FOR v_emp IN c_emp_reviews LOOP
        BEGIN
            v_new_salary := v_emp.old_salary;
            v_reason     := NULL;

            IF v_emp.avg_score >= 4
               AND v_emp.dept_rank <= 3 THEN

                v_new_salary := v_emp.old_salary * 1.15; 
                v_reason := '15% increment applied: Avg Score >= 4 and Dept Rank <= 3';

            ELSIF v_emp.avg_score >= 3
               AND v_emp.avg_score < 4 THEN

                v_new_salary := v_emp.old_salary * 1.08;
                v_reason := '8% increment applied: Avg Score between 3 and 4';

            ELSE
                v_new_salary := v_emp.old_salary;
            END IF;

            IF v_new_salary > v_emp.old_salary THEN
                UPDATE employees
                SET salary = v_new_salary
                WHERE emp_id = v_emp.emp_id;

                IF SQL%ROWCOUNT = 0 THEN
                    RAISE NO_DATA_FOUND;
                END IF;

                SELECT NVL(MAX(audit_id), 0) + 1
                INTO v_audit_id
                FROM salary_audit;

                INSERT INTO salary_audit (
                    audit_id,
                    emp_id,
                    old_salary,
                    new_salary,
                    change_date,
                    reason
                ) VALUES (
                    v_audit_id,
                    v_emp.emp_id,
                    v_emp.old_salary,
                    v_new_salary,
                    SYSDATE,
                    v_reason
                );
            END IF;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE(
                    'Warning: Employee ' || v_emp.emp_id || ' not found during update.'
                );

            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE(
                    'Error processing Employee ' || v_emp.emp_id || ' - ' || SQLERRM
                );
        END;
    END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Critical Procedure Error: ' || SQLERRM);
        RAISE;
END process_annual_salary_review;
/