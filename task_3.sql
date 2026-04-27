CREATE OR REPLACE TRIGGER trg_prevent_salary_reduction
BEFORE UPDATE OF salary ON employees
FOR EACH ROW
BEGIN
    IF :NEW.salary < :OLD.salary THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Update Failed: Salary reductions are not permitted.'
        );
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'Unexpected error in TRG_PREVENT_SALARY_REDUCTION: ' || SQLERRM
        );
END trg_prevent_salary_reduction;
/