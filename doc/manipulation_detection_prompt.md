You are an expert Data Analyst and Financial Forensics Specialist for the Counter-Strike (CS2) item economy. I am providing you with a CSV dataset of daily market snapshots.

Your goal is to identify items that are currently in the **"Silent Accumulation Phase"** of a market manipulation cycle (specifically "Chinese Pump" patterns). These are items where "Smart Money" is absorbing supply behind the scenes before a major price spike.

**The Columns in the CSV are:**
- `Name`: Item Name
- `Collection`: The collection the item belongs to (older collections are better targets)
- `Latest Price`: Current lowest sell price on Steam
- `Sold Today`: Number of items sold in the last 24 hours (Immediate Velocity)
- `Sold Volume Change`: % change in sales volume over the last 2 weeks (Demand Trend)
- `Offer Volume`: Total number of items currently listed for sale (Current Supply)
- `Offer Change`: % change in supply over the last 2 weeks (Supply Trend)
- `Turnover Rate (%)`: Pre-calculated ratio of Sold Today / Offer Volume
- `Buy Order Volume`: Total number of active buy requests
- `Buy Order Change`: % change in buy orders over the last 2 weeks
- `Buy Wall Ratio (x)`: Pre-calculated ratio of Buy Order Vol / Offer Vol
**Please analyze the data and rank the Top 10 "Potential Pump" candidates based on the following Weighted Scoring Criteria:**
**Please take into consideration overal items & collections supply**

### 1. The "Safety Net" (High Importance)
* **Metric:** `Buy Wall Ratio (x)`
* **Condition:** Look for a Ratio > **50x**.
  * *Logic:* A high ratio means buyers have placed a massive safety net. If `Buy Order Change` is also **Positive** (green), it means this wall is actively growing.

### 2. The "Supply Squeeze" (Critical Importance)
* **Metric:** `Offer Change` (Last 2 Weeks)
* **Condition:** Must be **Negative** (e.g., -10% or lower).
* **Logic:** We are looking for items where the supply is physically drying up over the 2-week period. If `Offer Change` is positive (supply increasing), **exclude it**—that is a dump, not a pump.

### 3. The "Silent Accumulation" Divergence
* **Pattern:**
  * `Sold Volume Change` is **Positive** (Demand is rising over 2 weeks).
  * `Offer Change` is **Negative** (Supply is falling over 2 weeks).
  * `Latest Price` is relatively **Stable** (not already up 200%).
* **Logic:** Rising demand + Falling supply + Flat price = Manipulation (Price suppression while buying).

### 4. The "Velocity" Check
* **Metric:** `Turnover Rate (%)`
* **Condition:** Ideally between **10% and 40%**.
  * *Warning:* If `Turnover Rate (%)` is > 100%, it is likely Wash Trading (fake volume). Flag these as high risk.

**Output Format:**
Please output a table with the following columns, ranked by your calculated "Pump Probability Score":
1.  **Item Name**
2.  **Pump Score (1-10)**
3.  **Wall Ratio (x)**
4.  **Supply Trend (2w)** (`Offer Change`)
5.  **Demand Trend (2w)** (`Sold Volume Change`)
6.  **Analysis:** A brief 1-sentence explanation of why this is a good pick (e.g., *"Supply dropped 15% in 2 weeks while buy orders grew 20%; huge 65x wall established"*).

If you detect any anomalies (like Wash Trading: massive volume but zero price movement and infinite supply), flag them as "TRAPS" at the end of the list.

**Note:** Please do not include any items that are not in the "Silent Accumulation Phase".

**Important** DO not response with any sort of code or suggestions, clarifications, etc. I only want the ranked list. and explanation why. Thats all.

***Update*** I need to see in list concrete examples of the "Silent Accumulation Phase" items. Not collections or cases names