# Analytics Tool Selection Guide

## Quick Decision Matrix

| Question | If Yes → Use | If No → Use |
|----------|--------------|-------------|
| Do you need financial metrics (revenue, costs, ROAS)? | Metabase | PostHog |
| Are you analyzing user behavior on the website? | PostHog | Metabase |
| Do you need to query across multiple databases? | Metabase | PostHog |
| Are you tracking conversion funnels? | PostHog | Metabase |
| Do you need SQL-based analysis? | Metabase | PostHog |
| Are you running A/B tests? | PostHog | Metabase |
| Do you need executive dashboards? | Metabase | PostHog |
| Are you analyzing individual user sessions? | PostHog | Metabase |

## Metabase - Business Intelligence Platform

### When to Use Metabase

**Perfect for:**
- 📊 Business KPIs and executive reporting
- 💰 Financial analytics (revenue, costs, margins)
- 📈 ROAS and advertising performance
- 🏪 Marketplace metrics (GMV, AOV, orders)
- 👥 Seller/brand performance analysis
- 📅 Time-based trending and forecasting
- 🔄 Cross-database queries and joins
- 📝 Scheduled reports and alerts

### Metabase Use Cases

1. **ROAS Dashboard**
   - Track ad spend efficiency
   - Compare platform performance
   - Identify underperforming campaigns
   - Calculate customer acquisition costs

2. **Financial Reporting**
   - Monthly GMV tracking toward $1M goal
   - Accounts payable to sellers
   - Revenue by category/brand
   - Margin analysis

3. **Operational Analytics**
   - Order fulfillment metrics
   - Inventory turnover
   - Seller performance rankings
   - Customer lifetime value

4. **Executive Dashboards**
   - High-level business health
   - Goal tracking (conversion rate: 1.95% → 3.5%)
   - Competitive benchmarking
   - Board reporting

### Metabase Strengths
- ✅ Native SQL support
- ✅ Connects to multiple databases
- ✅ Powerful visualization options
- ✅ Scheduled reports and alerts
- ✅ Self-hosted for data privacy
- ✅ No event volume limits

### Metabase Limitations
- ❌ No real-time user tracking
- ❌ No session recordings
- ❌ Limited cohort analysis
- ❌ No A/B testing framework
- ❌ Requires SQL knowledge for complex queries

## PostHog - Product Analytics Platform

### When to Use PostHog

**Perfect for:**
- 🔍 User behavior analysis
- 🎯 Conversion funnel optimization
- 🧪 A/B testing and experiments
- 📹 Session recordings and heatmaps
- 🚩 Feature flags and rollouts
- 📱 Product usage analytics
- 🔄 User journey mapping
- 🎨 UX/UI optimization

### PostHog Use Cases

1. **Conversion Optimization**
   - Track 92.5% drop-off before product views
   - Analyze checkout abandonment
   - Mobile vs desktop performance
   - Page-by-page funnel analysis

2. **Product Analytics**
   - Feature adoption rates
   - User engagement metrics
   - Search effectiveness
   - Navigation patterns

3. **Experimentation**
   - A/B test new features
   - Multivariate testing
   - Feature flag management
   - Gradual rollouts

4. **User Understanding**
   - Session recordings
   - Heatmaps and clickmaps
   - User paths analysis
   - Rage click detection

### PostHog Strengths
- ✅ Automatic event tracking
- ✅ Visual funnel builder
- ✅ Session recordings
- ✅ Built-in A/B testing
- ✅ Feature flags
- ✅ Real-time data

### PostHog Limitations
- ❌ Poor support for external data warehouses
- ❌ Not designed for financial metrics
- ❌ Limited cross-database capabilities
- ❌ Can't handle aggregated business data well
- ❌ Visualization errors with non-event data

## Practical Examples

### Scenario 1: "What's our ROAS for Google Ads this month?"
**→ Use Metabase**
- Query: `analytics.mv_ad_performance_daily`
- Visualization: ROAS scorecard
- Dashboard: ROAS Performance Tracker

### Scenario 2: "Why are users abandoning cart?"
**→ Use PostHog**
- Tool: Funnel analysis
- Data: Page view → Add to cart → Checkout → Purchase
- Enhancement: Session recordings of drop-offs

### Scenario 3: "What's our monthly revenue by brand?"
**→ Use Metabase**
- Query: Join orders with brands tables
- Visualization: Bar chart or table
- Report: Monthly financial summary

### Scenario 4: "Which homepage variant converts better?"
**→ Use PostHog**
- Tool: A/B test experiment
- Metrics: Conversion rate, engagement
- Feature: Feature flags for variant control

### Scenario 5: "Track seller payout obligations"
**→ Use Metabase**
- Query: Accounts payable report
- Data: Orders, commissions, fees
- Schedule: Monthly automated report

### Scenario 6: "How do users navigate to products?"
**→ Use PostHog**
- Tool: Path analysis
- Visual: User flow diagram
- Insights: Common navigation patterns

## Integration Between Tools

While Metabase and PostHog serve different purposes, they can complement each other:

1. **PostHog → Metabase**
   - Export cohorts for financial analysis
   - Join behavioral data with transactions
   - Correlate feature usage with revenue

2. **Metabase → PostHog**
   - Identify high-value customer segments
   - Target experiments to specific cohorts
   - Personalize based on purchase history

## Decision Framework

### Choose Metabase if you need to:
1. Calculate business metrics (ROAS, CAC, LTV)
2. Generate financial reports
3. Query historical data
4. Join data across systems
5. Create executive dashboards
6. Schedule automated reports
7. Analyze aggregated metrics

### Choose PostHog if you need to:
1. Track user interactions
2. Optimize conversion funnels
3. Run A/B tests
4. Watch session recordings
5. Deploy feature flags
6. Analyze user paths
7. Measure feature adoption

## Common Mistakes to Avoid

1. **Don't use PostHog for financial reporting**
   - It's not designed for aggregated business metrics
   - External warehouse tables cause errors

2. **Don't use Metabase for real-time user tracking**
   - It lacks event collection capabilities
   - No session recording features

3. **Don't duplicate efforts**
   - Each tool has its strengths
   - Use the right tool for the job

4. **Don't ignore integration opportunities**
   - Tools can work together
   - Share insights between platforms

## Quick Reference

| Metric/Task | Tool | Location |
|-------------|------|----------|
| ROAS | Metabase | `dashboards/roas/` |
| Conversion Funnel | PostHog | Product Analytics |
| Revenue Reports | Metabase | `reports/monthly/` |
| User Sessions | PostHog | Session Recordings |
| Ad Performance | Metabase | `analytics.mv_ad_performance_daily` |
| A/B Tests | PostHog | Experiments |
| GMV Tracking | Metabase | Executive Dashboard |
| Feature Usage | PostHog | Events & Actions |

## Getting Help

- **Metabase questions:** #tech-analytics Slack channel
- **PostHog questions:** #product-analytics Slack channel
- **Tool selection:** Engineering team
- **Access requests:** Admin team