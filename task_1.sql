-- Ranking employees within each department based on performance score
WITH EmployeeAverages AS (
    SELECT
    e.EMP_ID,
    e.EMP_NAME,
    e.DEPARTMENT,
    AVG(p.PERF_SCORE) AS avg_perf_score,
    RANK() OVER (PARTITION BY e.DEPARTMENT ORDER BY AVG(p.PERF_SCORE) DESC) AS dept_rank
    FROM EMPLOYEES e
    JOIN EMP_PERFORMANCE p ON e.EMP_ID = p.EMP_ID
    GROUP BY e.EMP_ID, e.EMP_NAME, e.DEPARTMENT
),

-- Calculating performance trends based on consecutive performance scores
PerformanceTrends AS (
    SELECT
    EMP_ID,
    REVIEW_DATE,
    PERF_SCORE AS current_score,
    LEAD(PERF_SCORE, 1) OVER (PARTITION BY EMP_ID ORDER BY REVIEW_DATE ASC) AS next_score,
    LEAD(PERF_SCORE, 2) OVER (PARTITION BY EMP_ID ORDER BY REVIEW_DATE ASC) AS next_next_score
    FROM EMP_PERFORMANCE
),

-- Filtering employees with consecutive declining performance score 
ConsecutiveDeclines AS (
    SELECT DISTINCT EMP_ID
    FROM PerformanceTrends
    WHERE current_score > next_score
    AND next_score > next_next_score
)

-- Shows the final output showing performance score averages and whether their performance has been declining
SELECT
    ea.EMP_ID,
    ea.EMP_NAME,
    ea.DEPARTMENT,
    ROUND(ea.avg_perf_score, 2) AS avg_perf_score,
    ea.dept_rank,

    CASE
    WHEN cd.EMP_ID IS NOT NULL THEN 'Yes'
    ELSE 'No'
    END AS consecutive_decline_flag

FROM EmployeeAverages ea
LEFT JOIN ConsecutiveDeclines cd ON ea.EMP_ID = cd.EMP_ID
ORDER BY ea.DEPARTMENT, ea.dept_rank;

