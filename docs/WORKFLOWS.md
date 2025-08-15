# Analytics Workflows - Claude Context

## Common Analytics Tasks

### 1. Creating Reports & Dashboards
**Typical Flow:**
1. Identify business question or KPI
2. Query relevant tables using `execute_query()` or `list_tables()`  
3. Create and test question with `create_card()`
4. Organize in appropriate collection with `create_collection()`
5. Build dashboard combining multiple questions

**Key Collections to Use:**
- "Our analytics" (root collection)
- Team-specific personal collections
- "Automatically Generated Dashboards"

### 2. Monthly/Weekly Reporting
**Location:** `/reports/monthly/` and `/reports/weekly/`
**Process:**
1. Execute existing cards for standard KPIs
2. Generate new analysis for period-specific insights
3. Document findings and recommendations
4. Export data for stakeholder sharing

**Standard KPIs:**
- Monthly GMV vs $1M target
- Order volume and AOV trends  
- Conversion rate progression (current: 1.95%, target: 3.5%)
- Product view rate (current: 7.5%, target: 25%)

### 3. Data Flow Documentation
**Purpose:** Track data movement from source systems to final dashboards
**Components:**
- Source system identification
- ETL/integration method
- Data transformation steps
- Final destination and usage
- Update frequency and reliability

### 4. Performance Analysis Workflows
**Conversion Funnel Analysis:**
- Traffic sources and quality
- Page-by-page drop-off identification  
- Mobile vs desktop performance gaps
- Product catalog effectiveness

**Financial Health Monitoring:**
- GMV trending and forecasting
- Customer cohort analysis
- Brand performance ranking
- Seasonal pattern identification

### 5. Ad-hoc Analysis
**Location:** `/reports/ad-hoc/`
**Common Requests:**
- Brand partnership evaluation
- Product performance deep-dives
- Customer behavior analysis
- Marketing campaign effectiveness
- Operational efficiency studies

## Best Practices

### Query Development
1. Start with existing cards using `list_cards()` to avoid duplication
2. Test queries on small datasets before scaling
3. Document complex logic in card descriptions
4. Use consistent naming conventions

### Dashboard Design  
1. Focus on actionable metrics aligned with business goals
2. Include context (targets, benchmarks, time comparisons)
3. Optimize for mobile viewing given audience
4. Regular review and iteration based on usage

### Data Validation
1. Cross-reference key metrics across systems
2. Monitor data freshness and completeness
3. Document known data quality issues
4. Set up alerts for anomalous values

## Integration Opportunities

### Immediate Priorities
1. **Stripe Integration:** Complete seller payout tracking
2. **Zendesk Integration:** Customer support metrics
3. **PostHog Connection:** Enhanced web analytics

### Future Enhancements
1. Real-time dashboard updates
2. Automated report generation
3. Predictive analytics for GMV forecasting
4. Customer segmentation and personalization insights