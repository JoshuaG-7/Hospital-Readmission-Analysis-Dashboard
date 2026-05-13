# 🏥 Hospital Readmission Analysis Dashboard

![SQL](https://img.shields.io/badge/SQL-PostgreSQL-blue) ![Power BI](https://img.shields.io/badge/Tool-Power%20BI-yellow) ![Tableau](https://img.shields.io/badge/Tool-Tableau-orange) ![Status](https://img.shields.io/badge/Status-Complete-green)

## 📌 Overview

This project analyzes **24,800+ CMS Medicare patient records** to identify 30-day hospital readmission trends across departments, age groups, and patient diagnoses. The goal is to surface high-risk patient segments and provide actionable insights to reduce preventable readmissions.

---

## 🎯 Objectives

- Calculate and track 30-day hospital readmission rates by department and age group
- Identify high-risk patient segments based on diagnosis and demographics
- Detect anomalies such as unusually short stays followed by quick readmissions
- Build an interactive dashboard for real-time monitoring of clinical KPIs

---

## 📊 Key Findings

- **Overall 30-day readmission rate: 18.4%** — up 1.2% vs. prior year
- **CHF patients aged 75+** had the highest readmission rate at **31.2%**
- **COPD patients aged 85+** followed closely at **28.7%**
- **Cardiology** was the highest-risk department at **24.1%** readmission rate
- **Orthopedics** had the lowest rate at **11.3%**, improving by 2.1% YoY
- Patients aged **75–84** made up the largest segment (41%) of total volume

---

## 🗂️ Project Structure

```
hospital-readmission-analysis/
│
├── hospital_readmission_queries.sql   # Full SQL pipeline (cleaning → analysis → dashboard view)
├── hospital_readmission_dashboard.html # Interactive dashboard (open in browser)
└── README.md
```

---

## 🛠️ Tools & Technologies

| Tool | Purpose |
|---|---|
| PostgreSQL / SQL | Data cleaning, KPI queries, anomaly detection |
| Power BI / Tableau | Interactive dashboard and visualizations |
| CMS Medicare Dataset | Primary data source (data.cms.gov) |
| Excel | Supplementary data validation |

---

## 🔍 SQL Pipeline Breakdown

| Step | Description |
|---|---|
| 1 | Table creation — `patients` and `readmissions` |
| 2 | Data cleaning — nulls, duplicates, invalid dates, age group standardization |
| 3 | KPI queries — overall readmission rate, avg length of stay, patient count |
| 4 | Readmission rate by department |
| 5 | Readmission rate by age group |
| 6 | High-risk segment detection with risk labels (High / Medium / Low) |
| 7 | Monthly trend by department |
| 8 | Year-over-year comparison |
| 9 | Anomaly detection — short stays + quick readmissions |
| 10 | Summary view to feed Power BI / Tableau |

---

## 📈 Dashboard Features

- **5 KPI cards** — readmission rate, total patients, avg length of stay, high-risk segments
- **Line chart** — monthly readmission trends by diagnosis
- **Doughnut chart** — patient volume by age group
- **Horizontal bar chart** — readmission rate by department
- **Risk table** — high/medium/low risk segments with visual indicators
- **Interactive filters** — by department, age group, and fiscal year

---

## 📁 Dataset

**Source:** CMS Hospital Readmissions Reduction Program
**Access:** [data.cms.gov](https://data.cms.gov) (free and publicly available)
**Also available on:** [Kaggle — Hospital Readmissions](https://www.kaggle.com)

---

## 🚀 How to Run

1. Load the dataset into PostgreSQL or any SQL-compatible database
2. Run `hospital_readmission_queries.sql` step by step
3. Connect the summary view (`vw_readmission_summary`) to Power BI or Tableau
4. Open `hospital_readmission_dashboard.html` in any browser for the interactive demo

---

## 👤 Author

**Joshua Giddirappa**
MS in Computer Science — University of Alabama at Birmingham
[LinkedIn](https://linkedin.com/in/joshua-giddirappa) | [GitHub](https://github.com/joshuagiddirappa)
