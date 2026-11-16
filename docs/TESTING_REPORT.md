# Smart Tailor (குழலி தையலகம்) – Automated Testing & Verification Report

**Execution Environment**: Local SQLite 3 Relational Engine (`tests/smart_tailor_test.db`) + Node.js Syntax & DOM Verifier (`check_web_app.py`)
**Total Test Cases Executed**: 18 / 18
**Pass Rate**: 18 / 18 (100% Passed)

| Test ID | Test Case Name | Status | Verified Outcome & Database Evidence |
| :--- | :--- | :--- | :--- |
| TC-01 | New Customer Registration, Family Member Link & Duplicate/Format Safeguards | **PASSED** | Registered CUST_001 (9843011223) + daughter FAM_001; SQLite CHECK rejected invalid mobile '12345' and UNIQUE constraint rejected duplicate mobile. |
| TC-02 | Existing Customer Search by Name and Mobile | **PASSED** | Query matched 1 record(s): Lakshmi Narayanan (9843011223). |
| TC-03 | Digital Measurement Creation with Garment-Specific & Custom Fields | **PASSED** | Stored Saree Blouse v1 (14 standard fields + custom 'Aari Border Width': 1.5 INCH) for CUST_001. |
| TC-04 | Measurement Version History & Anti-Overwrite Trigger | **PASSED** | Trigger trg_prevent_measurement_overwrite blocked direct UPDATE on v1; created v2 preserving v1 history (Waist 31.0 -> 31.5 in). |
| TC-05 | Multi-Garment Order Booking with Independent Item Tracking | **PASSED** | Booked ORD_1001 with 2 garment line items (2x Saree Blouse ₹700 + 1x Kurti ₹450 = ₹1,150; Net Total ₹1,200). |
| TC-06 | 8-Stage Workflow Progression, Audit Timestamps & Premature Delivery Block | **PASSED** | Trigger blocked premature delivery before QC/Trial; completed all 8 stages for ITEM_1001_A with 7 logged status transitions. |
| TC-07 | Alteration Management & Free-vs-Paid Owner Rule | **PASSED** | Recorded free trial alteration ALT_001 (₹0); constraint prevented non-zero charge when is_paid_alteration = 0. |
| TC-08 | Partial Payment & Idempotent Duplicate-Payment Guard | **PASSED** | Recorded ₹500 cash advance + ₹400 UPI partial payment (Balance ₹300); idempotency key blocked duplicate payment entry. |
| TC-09 | Full Payment Settlement & Automatic Balance Calculation | **PASSED** | Settled remaining ₹300; Total Paid = ₹1,200, Balance Due = ₹0.0, Invoice Status = PAID. |
| TC-10 | Refund Processing with Audit Log & Negative Balance Protection | **PASSED** | CHECK constraint blocked negative pending_balance (-₹100); recorded ₹50 REFUND transaction with audit trail AUD_001. |
| TC-11 | Invoice Generation & Formula Verification | **PASSED** | Verified Invoice KT-INV-2026-001: Garments ₹1,150 + Addl ₹100 - Discount ₹50 = ₹1200.00 (GST disabled by default). |
| TC-12 | Inventory Consumption & Customer-Supplied Cloth Exemption | **PASSED** | Blocked inventory deduction for customer-supplied silk (ITEM_1001_A); deducted 2.5m shop lining for ITEM_1001_B (Remaining: 22.5m, Valuation: ₹1,462.50). |
| TC-13 | Expense Recording & Earned Revenue vs Unearned Advance Accounting | **PASSED** | Earned Revenue: ₹1200.00 (ORD_1001 delivered); Unearned Advance Liability: ₹400.00 (ORD_1002 in-progress excluded from revenue); Expenses: ₹550.00; Operating Profit: ₹650.00. |
| TC-14 | Monthly Reports & Garment-Wise Revenue Analytics | **PASSED** | Aggregated garment-wise revenue across 2 categories (Saree Blouse: ₹700, Kurti: ₹450) plus pending receivables (₹500). |
| TC-15 | Offline-First Operation & Local Sync Queue | **PASSED** | All 2 orders created 100% offline in local SQLite with sync_status='PENDING' ready for background WorkManager sync. |
| TC-16 | Cloud Synchronization Preserving Local Data & Last-Synced Timestamp | **PASSED** | Synchronised 2 orders; local records preserved (2 orders intact) and shop last_synced_at updated to 2026-11-16T23:25:00+05:30. |
| TC-17 | Database Backup & Full Restore Verification | **PASSED** | Exported full SQLite dump (30069 bytes) and restored into clean database instance: verified 1 customer and 3 measurement versions. |
| TC-18 | Role-Based Access Control (Tailor Financial Restriction) | **PASSED** | Verified USR_TLR1 (TAILOR) has can_view_financial_reports=0 (blocked from profit/sales reports), while USR_OWNER has full access (1). |

## How to Re-Run the Automated Test Suite
Run the self-contained verification script from the project root:
```bash
python3 tests/run_verification_tests.py
```
