# 🏥 Code Blue: Emergency Operations & Patient Flow Analytics
### FP20 Analytics Challenge 38 — NHS System Intelligence Dashboard

> **"The difference between data and intelligence is the story it tells."**
> This dashboard transforms 11 NHS hospitals' operational data into a single, coherent narrative — from system-wide baselines to individual facility crises, and from financial health to clinical quality.

---

## 📋 Table of Contents
- [Project Overview](#project-overview)
- [Dashboard Pages](#dashboard-pages)
- [Key Findings](#key-findings)
- [Strengths — What the NHS System Is Doing Right](#strengths)
- [Weaknesses — Where the System Is Breaking Down](#weaknesses)
- [Strategic Recommendations](#strategic-recommendations)
- [Technical Stack](#technical-stack)

---

## Project Overview

This Power BI dashboard provides a **three-page analytical deep-dive** into NHS emergency operations, patient flow, staffing pressure, and financial sustainability across 11 hospitals — from Large Urban Trauma Centres to Underfunded Public facilities.

The central question driving this analysis:

> *When a healthcare system looks stable on paper, where exactly is it quietly breaking down — and what should leadership do about it?*

The answer unfolds across three pages, each building on the last.

---

## Dashboard Pages

### Page 1 — Executive Command Centre
*NHS system health — single glance view*

High-level KPIs, hospital performance matrix, archetype breakdown, and a real-time critical alert panel. Designed for C-suite and NHS board decision-makers who need the full picture in under 60 seconds.

### Page 2 — Operational Pressure Map
*Bottlenecks, staffing crisis & flow breakdown*

Granular operational intelligence: burnout vs. overtime by hospital, visit volume by severity level, chronic conditions vs. ICU demand, and patient outcome distribution. Designed for operations managers and clinical directors.

### Page 3 — Strategic Outcomes & Action Plan
*Clinical quality, financial health & executive recommendations*

The "so what?" page. A quality-vs-financial health matrix, satisfaction trend analysis, and prioritised action cards with hospital-specific interventions. Designed for strategy leads and NHS commissioners.

---

## Key Findings

### System-Wide Baseline

| Metric | Value |
|---|---|
| Avg Wait Time | 61.37 minutes |
| Readmission Rate (30d) | 17.04% |
| Avg Patient Satisfaction | 62.50 |
| Mortality Rate | 3.32% |
| Bed Occupancy | 54.0% |
| Total Revenue | £10.07bn |
| Avg Profit Margin | 17.44% |

These numbers suggest a system that is *functioning* — but the facility-level data tells a very different story.

---

## Strengths

### 🟢 High-Volume Efficiency Leaders — Alder Hey & UCL
Despite handling the highest patient volumes in the entire dataset (930+ visits), both Alder Hey and UCL maintain **peak satisfaction scores above 63.0** under only moderate staffing stress. These facilities prove that high throughput and clinical excellence are not mutually exclusive — they are the benchmark the rest of the system should be measured against.

**Strategic implication:** Alder Hey and UCL's operational models — their triage protocols, staffing ratios, and patient flow management — should be formally documented and shared across the NHS trust network.

---

### 🟢 Leeds — The Financial & Clinical Sweet Spot
Leeds sits in the optimal quadrant of the Quality vs. Financial Health Matrix: the **highest profit margin in the dataset (~19.3%)** paired with a **readmission rate below the system average (~16.3%)**. This is not a coincidence — it reflects disciplined discharge planning, effective post-acute care coordination, and a financially sustainable operating model.

**Strategic implication:** Leeds is the system's proof of concept that quality and profitability reinforce each other. Its care coordination model should be the template for trust-wide improvement programmes.

---

### 🟢 Bristol — Clinical Excellence Under Financial Pressure
Bristol records the **lowest readmission rate in the system (~15.7%)**, indicating that its clinical care pathways are genuinely effective at treating patients completely the first time. The challenge is purely financial — not operational.

**Strategic implication:** Bristol's clinical protocols deserve preservation and investment, not cuts. The financial gap is a funding and payer-mix problem that requires commissioner-level intervention, not a signal of poor care quality.

---

### 🟢 Uniform Patient Distribution Across Facilities
Each of the 11 hospitals accounts for between **8.76% and 9.38%** of total patient visits — a remarkably even distribution. This means comparative performance analysis between facilities is statistically valid and not distorted by one dominant site.

**Strategic implication:** Performance benchmarking across this network is reliable. Accountability frameworks can be applied consistently across all 11 sites without adjusting for volume bias.

---

### 🟢 4-Hour Compliance
The system-wide **4-hour compliance rate of 98.8%** exceeds the NHS standard of 95%. This is a significant operational achievement, particularly during periods of peak winter pressure.

---

## Weaknesses

### 🔴 Sandwell General — A Compounding Crisis
Sandwell General is the single most urgent intervention priority in this dataset. Every major clinical, operational, and financial indicator has collapsed simultaneously:

- **Patient satisfaction: 28.9** (system average: 62.50 — a 56% collapse)
- **Mortality rate: 6%** — double the system-wide average of 3.32%
- **Burnout index: 0.96** — approaching the absolute maximum on the scale
- **Readmission rate and profit margin** both sit in the high-risk quadrant of the financial health matrix

This is not a single-metric problem. It is a **systemic cascade failure**: chronic understaffing has driven burnout to critical levels, which has extended wait times, eroded care quality, driven up readmissions, and ultimately pushed mortality rates to dangerous highs — all while the facility's financial position deteriorates. Each problem is amplifying the others.

---

### 🔴 Seasonal Winter Surge — A Predictable Crisis Treated as a Surprise
Across every hospital in the network, January represents the absolute operational peak:
- **1-Resus cases peak at 52** (highest of the year)
- **3-Urgent cases hit 363** — nearly 35% higher than the June trough
- **Overtime hours surge, burnout risk climbs toward 0.65+**, and patient satisfaction collapses in lockstep

The critical insight is that this is entirely predictable. The data shows the same pattern repeating across 2024 and into 2025. The system is experiencing winter as though it is a surprise each year, rather than a scheduled operational challenge it can prepare for.

---

### 🔴 Cornwall & Norfolk — Financial Sustainability Risks
Cornwall and Norfolk both sit in vulnerable positions on the financial health matrix:
- **Low profit margins (~15.5%–16.0%)** combined with **high readmission rates (~17.0%–18.0%)**
- Norfolk's ICU demand remains elevated, driven by a patient mix weighted toward medium-to-high acuity chronic conditions
- High readmission rates signal gaps in discharge planning and post-acute care pathways

---

### 🔴 King's, Alder Hey & Norfolk — Quality Risk Despite Financial Health
These facilities are financially strong (margins between 17.5% and 18.5%) but carry the **highest readmission rates in the system**, peaking near 18.3% at King's. Financial performance is masking a clinical quality problem: patients are being discharged before they are fully stabilised, or are falling through gaps in community care.

---

### 🔴 January 2025 Satisfaction Collapse — A System-Wide Signal
In January 2025, average patient satisfaction dropped to a **historic low of ~64.0**, while complaint rates surged to over **8.5%** — their highest point in the two-year period. The pattern then begins to repeat as the system approaches the next winter cycle in late 2025. This is not an isolated event; it is the leading indicator of systemic winter failure recurring on schedule.

---

## Strategic Recommendations

### Immediate (0–3 months)

**1. Emergency Intervention at Sandwell General**
Deploy a cross-functional turnaround team. Prioritise immediate staffing reinforcement through bank and agency staff, initiate a mortality review for all cases in the past 6 months, and place the facility under enhanced NHS oversight. Burnout at 0.96 means the existing workforce cannot self-recover — external resource injection is non-negotiable.

**2. Pre-Winter Staffing Contracts**
Given the clear and recurring November–January surge pattern, all 11 trusts should lock in contingency staffing agreements by September each year. The data makes the volume forecast reliable enough to act on it proactively rather than reactively.

---

### Medium-Term (3–12 months)

**3. Replicate the Spire & Nuffield Model**
Both Spire and Nuffield demonstrate burnout indices around 0.38 and readmission rates between 3–6%, with patient satisfaction scores between 84–88. Their workforce management and discharge planning models should be formally benchmarked and adapted for NHS Foundation Trust environments.

**4. Bristol Financial Recovery Programme**
Bristol's clinical outcomes are system-leading. The financial gap (~14% margin vs. 17.44% system average) requires a commissioner-level review of its payer mix, contract structures, and funding allocation — not a reduction in clinical resources.

**5. Post-Acute Care Investment for High-Readmission Sites**
King's, Norfolk, and Alder Hey's high readmission rates are a post-discharge problem, not an in-hospital one. Investment in community care coordination, follow-up protocols, and patient education programmes at discharge would reduce readmissions and improve both quality scores and long-term financial performance.

---

### Long-Term (12+ months)

**6. Risk-Stratified Chronic Condition Management**
The chronic conditions vs. ICU demand analysis shows that ICU strain is driven by patient acuity mix, not total volume. Targeted interventions for High and Medium risk chronic patients — preventing them from deteriorating to Critical — would materially reduce ICU demand at Bristol, Harrogate, and Leeds.

**7. Seasonal Demand-Based Elective Scheduling**
Formally shift elective procedures toward the May–July window, when emergency demand is at its lowest. This optimises bed utilisation year-round and reduces the operational shock of winter surges by creating buffer capacity before Q4.

---

## The Narrative Thread

If this data tells one story, it is this:

> The NHS network analysed here is not failing — but it is fragile. Its strongest performers (Leeds, Alder Hey, UCL) demonstrate that high-quality, financially sustainable care at scale is entirely achievable. Its weakest points (Sandwell, Cornwall, the January collapse) are not random — they are the predictable consequences of understaffing, inadequate post-acute pathways, and treating a cyclical seasonal crisis as if it were an unpredictable event.
>
> The gap between what this system achieves at its best and what it tolerates at its worst is the strategic opportunity. Close that gap — by replicating what works, intervening where the cascade has already begun, and building predictive capacity for what the data clearly shows is coming every winter — and this becomes a genuinely world-class NHS network.

---

## Technical Stack

| Tool | Usage |
|---|---|
| **Power BI Desktop** | Dashboard development, DAX measures, data modelling |
| **DAX** | KPI measures, readmission rate, profit margin, burnout index, severity buckets |
| **Power Query** | Data transformation, column creation, severity short labels |
| **Data Model** | Star schema — Fact_Patient_Visits, Fact_Staffing, Fact_Financials + 6 Dimension tables |

---

*Dashboard developed for FP20 Analytics Challenge 38 — "Code Blue: Emergency Operations & Patient Flow Analytics"*
*11 NHS Hospitals · 2024–2025 · Power BI*
