 # Food Delivery Operations Analytics & Executive Dashboard

An end-to-end data analytics project using MySQL for data auditing, pipeline cleansing, and anomaly resolution, paired with Microsoft Power BI for interactive operational monitoring and KPI reporting.

---

## 📌 Executive Summary
This project analyzes real-world food delivery operations across urban delivery networks to pinpoint bottlenecks in transit times, evaluate driver and fleet performance, and assess kitchen preparation efficiency. 

Raw, uncurated operational data was audited and structured in MySQL, and an executive-level Power BI report ("Delivery Dashboard") was developed to provide actionable operational visibility for dispatch and logistics teams.

---

## 💻 Tech Stack
* Database & Transformations: MySQL Workbench (Data Cleansing, Dynamic Regex, Temporal Arithmetic, Views)
* Business Intelligence & Reporting: Microsoft Power BI Desktop (Data Modeling, DAX, Interactive Visualizations)
* Data Sources: CSV / Relational Staging Tables (90,000+ Raw Records)

---

## ⚙️ Data Architecture & Engineering Pipeline
Raw CSV Dataset
│
▼
[ MySQL Staging Layer ] ──────── staging_food_delivery (String Ingestion)
│
▼
[ Data Cleansing Layer ] ─────── cleaned_food_delivery
│                             ├── Standardize mixed date formats (STR_TO_DATE)
│                             ├── Cast numeric and timestamp metrics
│                             ├── Sanitize string noise and 'NaN' instances
│                             └── Midnight cross-over correction (+1440 mins)
│
▼
[ Production Semantic View ] ─── food_delivery_bi_summary
│
▼
[ Power BI Presentation Layer ] ─ "Delivery Dashboard" (KPIs, Combo Visuals, Slicers)
 ### 1. Data Cleaning & Type Casting
* Heterogeneous Date Parsing: Converted non-uniform date strings formatted as both DD-MM-YYYY and DD/MM/YYYY into standardized SQL DATE types.
* Timestamp Normalization: Extracted string time components and cast them into native TIME data types for duration math.
* Text Sanitation: Stripped unwanted substrings (e.g., 'conditions ' prefixes) and filtered empty strings and 'NaN' textual representations.

### 2. Midnight Rollover Anomaly Resolution
* The Problem: Orders submitted shortly before midnight (e.g., 23:55) and picked up by delivery drivers past midnight (e.g., 00:08) produced negative preparation intervals (prep_time_min < 0).
* The Solution: Implemented interval rollover arithmetic adding 1440 minutes (24 hours) to restore valid operational kitchen turnaround:
  $$\text{prep\_time} = \begin{cases} \text{prep\_time\_min} + 1440 & \text{if } \text{prep\_time\_min} < 0 \\ \text{prep\_time\_min} & \text{otherwise} \end{cases}$$

### 3. Production BI View
* Engineered a consolidated view (food_delivery_bi_summary) extracting calendar dimensions (DAYNAME(order_date)) and applying baseline dimensional filters to streamline Power BI performance without requiring complex client-side calculated columns.

---

## 📊 Key Performance Indicators & Business Insights

| Metric Dimension | Key Insight | Operational Recommendation |
| :--- | :--- | :--- |
| Traffic Congestion | Deliveries during heavy traffic (Jam) average 31.08 mins, representing a 44% increase in transit duration compared to low traffic density (21.53 mins). | Implement dynamic order dispatch buffers and automated routing during peak traffic periods. |
| Weather Conditions | Foggy conditions cause the longest delivery durations (29.47 mins), while clear Sunny days show the fastest completion (21.91 mins). | Adjust customer delivery SLA estimates proactively according to real-time weather forecasts. |
| Fleet Performance | Electric Scooters (24.16 mins) and Scooters (24.68 mins) outperform conventional Motorcycles (27.71 mins) across urban hubs. | Prioritize scooter fleets in densely packed urban delivery corridors to minimize delay. |
| Kitchen Turnaround | Kitchen preparation times remain remarkably steady between 9.80 and 10.03 mins across snacks, meals, drinks, and buffets. | Operational delays originate primarily from transit and road conditions, not kitchen turnaround bottlenecks. |
| Weekly Demand | Order volume demonstrates sustained mid-week peaks (Wednesday records the highest volume), while Mondays observe the lowest volume. | Align delivery partner shift scheduling and incentives around mid-week demand surges. |

---

## 🖥️ Executive Power BI Dashboard ("Delivery Dashboard")

![Delivery Dashboard Preview](delivery%20project%20dashboard.png)

### Core Report Components:
* Metric Cards:
  * Total Orders — Total order throughput volume.
  * Avg Delivery Time (Min) — Benchmark transit operational efficiency.
  * Avg Delivery Rating — Delivery partner customer service benchmark.
* Analytical Visualizations:
  * Delivery Time by Weather: Column chart breaking down delivery delays across atmospheric environments.
  * Delivery Time by Vehicle: Comparative bar chart benchmarking vehicle fleet transit speed.
  * Traffic Impact on Delivery: Congestion escalation chart mapping transit delays across traffic density tiers.
  * Order Volume & Kitchen Prep Time: Dual-axis combo visual evaluating food order volume alongside kitchen prep durations.
  * Orders by Weekday & Orders by Day of Month: Time-series operational distribution charts.
* Interactive Filtering: Global dropdown slicers for City and Delivery Person Age Group.

---

## 📁 Repository Structure
├── SQL/
│   └── delivery%20project%20query.sql         # Complete staging, cleaning, view creation & analytical queries
├── Dashboard/
│   ├── Delivery%20project.pbix       # Production Power BI dashboard file
│   └── delivery%20project%20dashboard.png         # High-resolution dashboard report capture
└── README.md                         # Detailed technical project documentation
