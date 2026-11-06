# Milestone 1: billing guardrail.
# Built first on purpose: it protects you from surprise charges while you experiment.
# AWS Budgets: the first 2 budgets per account are free.

resource "aws_budgets_budget" "monthly" {
  name         = "monthly-cost-guardrail"
  budget_type  = "COST"
  limit_amount = var.monthly_budget_usd
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # Alert when actual spend passes 80% of the limit...
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  # ...and when AWS *forecasts* you'll exceed 100% by month end.
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}
