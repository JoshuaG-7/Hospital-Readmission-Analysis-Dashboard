-- STEP 1: CREATE TABLES 
CREATE TABLE patients (
    patient_id        VARCHAR(20) PRIMARY KEY,
    age               INT,
    age_group         VARCHAR(20), 
    gender            VARCHAR(10),
    diagnosis_code    VARCHAR(20),
    diagnosis_name    VARCHAR(100),
    department        VARCHAR(50),
    admission_date    DATE,
    discharge_date    DATE,
    length_of_stay    INT,           -- in days
    discharge_status  VARCHAR(50),   -- 'Home', 'SNF', 'Expired', etc.
    hospital_id       VARCHAR(20),
    state             VARCHAR(5)
);

CREATE TABLE readmissions (
    readmission_id    VARCHAR(20) PRIMARY KEY,
    patient_id        VARCHAR(20) REFERENCES patients(patient_id),
    original_admit    DATE,
    readmit_date      DATE,
    days_to_readmit   INT,
    readmit_diagnosis VARCHAR(100),
    is_30day          BOOLEAN       -- TRUE if readmitted within 30 days
);

-- STEP 2: DATA CLEANING

-- Inspect raw data for nulls
SELECT
    COUNT(*)                                        AS total_rows,
    COUNT(*) FILTER (WHERE patient_id IS NULL)      AS null_patient_id,
    COUNT(*) FILTER (WHERE age IS NULL)             AS null_age,
    COUNT(*) FILTER (WHERE diagnosis_code IS NULL)  AS null_diagnosis,
    COUNT(*) FILTER (WHERE admission_date IS NULL)  AS null_admission,
    COUNT(*) FILTER (WHERE discharge_date IS NULL)  AS null_discharge
FROM patients;

-- Remove duplicate patient records (keep most recent)
DELETE FROM patients
WHERE patient_id IN (
    SELECT patient_id
    FROM (
        SELECT
            patient_id,
            ROW_NUMBER() OVER (
                PARTITION BY patient_id
                ORDER BY admission_date DESC
            ) AS rn
        FROM patients
    ) sub
    WHERE rn > 1
);

-- Fix missing length_of_stay by calculating from dates
UPDATE patients
SET length_of_stay = discharge_date - admission_date
WHERE length_of_stay IS NULL
  AND admission_date IS NOT NULL
  AND discharge_date IS NOT NULL;

-- Remove records with invalid dates (discharge before admission)
DELETE FROM patients
WHERE discharge_date < admission_date;

-- Standardize age_group labels
UPDATE patients
SET age_group = CASE
    WHEN age BETWEEN 65 AND 74 THEN '65-74'
    WHEN age BETWEEN 75 AND 84 THEN '75-84'
    WHEN age >= 85              THEN '85+'
    ELSE 'Unknown'
END;

-- Flag 30-day readmissions
UPDATE readmissions
SET is_30day = (days_to_readmit <= 30);

-- Recalculate days_to_readmit where missing
UPDATE readmissions r
SET days_to_readmit = r.readmit_date - p.discharge_date
FROM patients p
WHERE r.patient_id = p.patient_id
  AND r.days_to_readmit IS NULL;


-- STEP 3: KPI QUERIES
-- Overall 30-day readmission rate
SELECT
    COUNT(DISTINCT r.patient_id)                        AS readmitted_patients,
    COUNT(DISTINCT p.patient_id)                        AS total_patients,
    ROUND(
        COUNT(DISTINCT r.patient_id) * 100.0
        / NULLIF(COUNT(DISTINCT p.patient_id), 0), 1
    )                                                   AS readmission_rate_pct
FROM patients p
LEFT JOIN readmissions r
    ON p.patient_id = r.patient_id
    AND r.is_30day = TRUE;

-- Average length of stay
SELECT
    ROUND(AVG(length_of_stay), 1) AS avg_length_of_stay_days
FROM patients
WHERE length_of_stay IS NOT NULL
  AND length_of_stay > 0;

-- Total patients by department
SELECT
    department,
    COUNT(DISTINCT patient_id) AS total_patients
FROM patients
GROUP BY department
ORDER BY total_patients DESC;

-- STEP 4: READMISSION RATE BY DEPARTMENT

SELECT
    p.department,
    COUNT(DISTINCT p.patient_id)                          AS total_patients,
    COUNT(DISTINCT r.patient_id)                          AS readmitted_patients,
    ROUND(
        COUNT(DISTINCT r.patient_id) * 100.0
        / NULLIF(COUNT(DISTINCT p.patient_id), 0), 1
    )                                                     AS readmission_rate_pct
FROM patients p
LEFT JOIN readmissions r
    ON p.patient_id = r.patient_id
    AND r.is_30day = TRUE
GROUP BY p.department
ORDER BY readmission_rate_pct DESC;

-- STEP 5: READMISSION RATE BY AGE GROUP

SELECT
    p.age_group,
    COUNT(DISTINCT p.patient_id)                          AS total_patients,
    COUNT(DISTINCT r.patient_id)                          AS readmitted_patients,
    ROUND(
        COUNT(DISTINCT r.patient_id) * 100.0
        / NULLIF(COUNT(DISTINCT p.patient_id), 0), 1
    )                                                     AS readmission_rate_pct
FROM patients p
LEFT JOIN readmissions r
    ON p.patient_id = r.patient_id
    AND r.is_30day = TRUE
GROUP BY p.age_group
ORDER BY p.age_group;

-- STEP 6: HIGH-RISK PATIENT SEGMENTS
-- (Diagnosis + Age Group combinations)

SELECT
    p.diagnosis_name,
    p.age_group,
    p.department,
    COUNT(DISTINCT p.patient_id)                          AS total_patients,
    COUNT(DISTINCT r.patient_id)                          AS readmitted_patients,
    ROUND(
        COUNT(DISTINCT r.patient_id) * 100.0
        / NULLIF(COUNT(DISTINCT p.patient_id), 0), 1
    )                                                     AS readmission_rate_pct,
    CASE
        WHEN ROUND(COUNT(DISTINCT r.patient_id) * 100.0
             / NULLIF(COUNT(DISTINCT p.patient_id), 0), 1) >= 25 THEN 'High'
        WHEN ROUND(COUNT(DISTINCT r.patient_id) * 100.0
             / NULLIF(COUNT(DISTINCT p.patient_id), 0), 1) >= 15 THEN 'Medium'
        ELSE 'Low'
    END                                                   AS risk_level
FROM patients p
LEFT JOIN readmissions r
    ON p.patient_id = r.patient_id
    AND r.is_30day = TRUE
GROUP BY p.diagnosis_name, p.age_group, p.department
HAVING COUNT(DISTINCT p.patient_id) >= 50   -- filter small sample sizes
ORDER BY readmission_rate_pct DESC
LIMIT 20;

-- STEP 7: MONTHLY READMISSION TREND

SELECT
    TO_CHAR(p.admission_date, 'YYYY-MM')                  AS month,
    p.department,
    COUNT(DISTINCT p.patient_id)                          AS total_patients,
    COUNT(DISTINCT r.patient_id)                          AS readmitted_patients,
    ROUND(
        COUNT(DISTINCT r.patient_id) * 100.0
        / NULLIF(COUNT(DISTINCT p.patient_id), 0), 1
    )                                                     AS readmission_rate_pct
FROM patients p
LEFT JOIN readmissions r
    ON p.patient_id = r.patient_id
    AND r.is_30day = TRUE
WHERE p.admission_date >= '2023-07-01'
  AND p.admission_date <  '2024-07-01'
GROUP BY TO_CHAR(p.admission_date, 'YYYY-MM'), p.department
ORDER BY month, p.department;

-- STEP 8: YEAR-OVER-YEAR COMPARISON BY DEPARTMENT

SELECT
    p.department,
    SUM(CASE WHEN EXTRACT(YEAR FROM p.admission_date) = 2023
             THEN 1 ELSE 0 END)                           AS patients_fy2223,
    SUM(CASE WHEN EXTRACT(YEAR FROM p.admission_date) = 2023
             AND r.is_30day = TRUE
             THEN 1 ELSE 0 END)                           AS readmit_fy2223,
    ROUND(
        SUM(CASE WHEN EXTRACT(YEAR FROM p.admission_date) = 2023
                 AND r.is_30day = TRUE THEN 1 ELSE 0 END) * 100.0
        / NULLIF(SUM(CASE WHEN EXTRACT(YEAR FROM p.admission_date) = 2023
                          THEN 1 ELSE 0 END), 0), 1
    )                                                     AS rate_fy2223,
    SUM(CASE WHEN EXTRACT(YEAR FROM p.admission_date) = 2024
             THEN 1 ELSE 0 END)                           AS patients_fy2324,
    SUM(CASE WHEN EXTRACT(YEAR FROM p.admission_date) = 2024
             AND r.is_30day = TRUE
             THEN 1 ELSE 0 END)                           AS readmit_fy2324,
    ROUND(
        SUM(CASE WHEN EXTRACT(YEAR FROM p.admission_date) = 2024
                 AND r.is_30day = TRUE THEN 1 ELSE 0 END) * 100.0
        / NULLIF(SUM(CASE WHEN EXTRACT(YEAR FROM p.admission_date) = 2024
                          THEN 1 ELSE 0 END), 0), 1
    )                                                     AS rate_fy2324
FROM patients p
LEFT JOIN readmissions r
    ON p.patient_id = r.patient_id
GROUP BY p.department
ORDER BY rate_fy2324 DESC;

-- STEP 9: ANOMALY DETECTION
-- (Patients with unusually short stays + high readmission)

SELECT
    p.patient_id,
    p.age,
    p.diagnosis_name,
    p.department,
    p.length_of_stay,
    r.days_to_readmit,
    p.discharge_status
FROM patients p
JOIN readmissions r
    ON p.patient_id = r.patient_id
    AND r.is_30day = TRUE
WHERE p.length_of_stay <= 2           -- very short initial stay
  AND r.days_to_readmit <= 7          -- readmitted within a week
ORDER BY r.days_to_readmit ASC
LIMIT 50;

-- STEP 10: SUMMARY VIEW FOR DASHBOARD

CREATE OR REPLACE VIEW vw_readmission_summary AS
SELECT
    p.department,
    p.age_group,
    p.diagnosis_name,
    TO_CHAR(p.admission_date, 'YYYY-MM')    AS month,
    COUNT(DISTINCT p.patient_id)            AS total_patients,
    COUNT(DISTINCT r.patient_id)            AS readmitted_30day,
    ROUND(
        COUNT(DISTINCT r.patient_id) * 100.0
        / NULLIF(COUNT(DISTINCT p.patient_id), 0), 1
    )                                       AS readmission_rate_pct,
    ROUND(AVG(p.length_of_stay), 1)         AS avg_los
FROM patients p
LEFT JOIN readmissions r
    ON p.patient_id = r.patient_id
    AND r.is_30day = TRUE
GROUP BY
    p.department,
    p.age_group,
    p.diagnosis_name,
    TO_CHAR(p.admission_date, 'YYYY-MM');

-- Query the summary view (used to feed Power BI / Tableau)
SELECT * FROM vw_readmission_summary
ORDER BY month, department;
