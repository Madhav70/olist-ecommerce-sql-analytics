# Executive Analytical Report: Brazilian E-Commerce Intelligence (Olist)

**Prepared for:** Marketplace Strategy & Operations Leadership  
**Data Scope:** 99,441 Orders across 27 Brazilian States (2016–2018)  
**Database:** SQLite / PostgreSQL Relational Warehouse  

---

## 1. Executive Summary

An analytical investigation of the Olist marketplace data reveals a rapidly growing e-commerce ecosystem generating **R$ 13.22M in merchandise sales (GMV)** across **96,478 delivered orders**. 

However, beneath the headline GMV growth lies significant untapped potential:
- **Customer Repeat Purchase Rate stands at just 3.00%**, signaling an almost purely transactional, customer-acquisition-driven business model with minimal retention.
- **Delivery SLAs are met 91.89% of the time**, but when orders are delayed, **customer satisfaction collapses from 4.29 to 2.57 stars**, and 1-star complaints skyrocket from 6.6% to 46.2%.
- **Freight expenses account for 14.26% of total customer spend**, acting as a friction point in categories like furniture, home appliances, and low-ticket goods.
- **Credit card financing is critical**, with 73.92% of orders paid via credit card and 36.6% of credit purchases financed across 4 to 10+ installments.

---

## 2. Platform KPIs at a Glance

| Executive Metric | Platform Value | Business Interpretation |
| :--- | :--- | :--- |
| **Total Orders** | 99,441 | Gross purchase volume recorded. |
| **Delivered Orders** | 96,478 | 97.02% order completion rate; 625 canceled (0.63%). |
| **Delivered GMV** | **R$ 13,221,498.11** | Merchandise revenue excluding freight charges. |
| **Freight Collected** | **R$ 2,198,275.64** | Freight contributes an additional 14.26% to spend. |
| **Total Customer Spend** | **R$ 15,419,773.75** | Total platform gross payments. |
| **Unique Customers** | 96,096 | Human customer accounts. |
| **Active Sellers** | 3,095 | Third-party marketplace merchants. |
| **Average Order Value (AOV)** | **R$ 137.04** | Average merchandise spend per completed order. |
| **Average Basket Size** | **1.17 items** | High propensity for single-item cart checkouts. |
| **Platform Review Score** | **4.09 / 5.00** | Healthy overall rating benchmark. |

---

## 3. Deep-Dive Findings & Strategic Insights

### Finding 1: The Repeat Purchase Dilemma (3.00% Retention)
- **The Metric:** Out of 93,358 delivered customers, **90,557 (97.0%) bought only once**. Only **2,801 customers (3.00%) placed repeat orders**.
- **Economic Value:** Repeat buyers generate **R$ 260.05 in lifetime spend**, nearly **double** the one-time buyer average of R$ 137.96.
- **Repurchase Timing:** Among the 3.0% who repeat, **36.31% repurchase within 7 days** (often buying complementary items or completing an order), while 18.42% take more than 6 months.
- **Strategic Recommendation:** Implement an automated post-purchase CRM nurture flow within 7–14 days offering targeted cross-category discounts, converting 1-time buyers into repeat loyalists.

### Finding 2: The Severe Cost of Delivery Delays
- **On-time vs. Late Reviews:** 
  - On-time orders average **4.29 stars** (62.4% 5-star, only 6.6% 1-star).
  - Late orders plummet to **2.57 stars** (only 22.2% 5-star, and **46.16% 1-star**).
- **Latency Threshold:**
  - Orders delivered in **1–3 days** enjoy a **4.46 star average** (71.0% 5-star).
  - Orders taking **>30 days** collapse to **2.20 stars** with **55.9% 1-star reviews**.
- **Customer Rage Behavior:** Dissatisfied customers (1-star) leave written feedback **76.55% of the time**, compared to only 35.85% for happy 5-star customers. Negative word-of-mouth is twice as vocal.
- **Strategic Recommendation:** Implement proactive customer SMS/email notifications when parcels encounter carrier bottlenecks. Under-promising and over-delivering on SLA dates directly protects customer NPS.

### Finding 3: Regional Disparities in Logistics & SLA Fulfillment
- **The Southeast Advantage:** São Paulo (`SP`) represents **42.2% of all platform orders** with an average delivery speed of **8.8 days** and a low 5.88% late rate (4.25 star rating).
- **The Northern / Northeastern Penalty:**
  - Alagoas (`AL`): 24.5 average delivery days; **23.94% late delivery rate**; 3.84 rating.
  - Maranhão (`MA`): 21.5 average delivery days; **19.56% late delivery rate**; 3.84 rating.
  - Rio de Janeiro (`RJ`): While in the Southeast, RJ experiences a **13.48% late rate** across 12,420 orders due to local urban courier challenges.
- **Strategic Recommendation:** Partner with regional fulfillment hubs (3PLs) in Recife or Salvador to service the Northeast, and enforce stricter carrier SLA agreements in Rio de Janeiro.

### Finding 4: Category Dynamics & High-Friction Freight
- **Top GMV Drivers:**
  1. `health_beauty`: R$ 1,237,439.95 (9.36% share, 4.19 rating)
  2. `watches_gifts`: R$ 1,167,246.63 (8.83% share, 4.07 rating)
  3. `bed_bath_table`: R$ 1,037,177.69 (7.84% share, 3.92 rating)
- **High-Friction Bulky Categories:**
  - `office_furniture`: Average unit freight is **R$ 40.13** (25.01% of merchandise price; average weight 11.34 kg). Consequently, customer satisfaction drops to **3.52 stars**, the lowest among major categories.
- **Cross-Selling Bundles:** Multi-item cart analysis revealed strong affinity between:
  - `furniture_decor` + `bed_bath_table` (86 cross-order pairs)
  - `home_confort` + `bed_bath_table` (45 cross-order pairs)
  - `baby` + `toys` (22 cross-order pairs)
- **Strategic Recommendation:** Offer bundle discounts on complementary categories (Bed, Bath & Table + Furniture Decor) and negotiate freight subsidies with freight forwarders for bulky furniture.

### Finding 5: Payment Methods & Consumer Financing
- **Credit Card Supremacy:** Credit card payments capture **78.34% of platform GMV** (R$ 12.54M), followed by Boleto Bancário at **17.92%** (R$ 2.87M).
- **Installment Financing Elasticity:**
  - 1x single payment: Average ticket R$ 95.87
  - 4x–6x installment: Average ticket R$ 181.32
  - 7x–10x installment: Average ticket **R$ 333.83** (3.5x higher ticket!)
- **Strategic Recommendation:** Promote zero-interest installment options (`sem juros`) on premium products (>R$ 250) to unlock higher conversion rates.

---

## 4. Key Action Items for Product & Operations

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       ACTIONABLE ROADMAP MATRIX                             │
├──────────────────────┬─────────────────────────────┬────────────────────────┤
│ Priority Level       │ Operational Initiative      │ Expected Impact        │
├──────────────────────┼─────────────────────────────┼────────────────────────┤
│ P0 (Immediate)       │ Seller SLA Enforcement      │ Cut late orders by 40% │
│                      │ Flag sellers with >15% late │ Lift platform rating   │
│                      │ rate or dispatch >4 days.   │ from 4.09 -> 4.30.     │
├──────────────────────┼─────────────────────────────┼────────────────────────┤
│ P1 (High Impact)     │ Post-Purchase CRM Flow      │ Increase repeat rate   │
│                      │ Trigger dynamic coupon on   │ from 3.0% -> 6.0%,     │
│                      │ Day 5 post-delivery.        │ adding +R$ 750k GMV.   │
├──────────────────────┼─────────────────────────────┼────────────────────────┤
│ P2 (Medium Term)     │ Freight Subsidy on Furniture│ Reduce cart abandon    │
│                      │ Partner with freight pools  │ in bulky goods; lift   │
│                      │ for bulky goods (>10kg).    │ review rating to 4.0+. │
└──────────────────────┴─────────────────────────────┴────────────────────────┘
```
