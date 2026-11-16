-- ============================================================================
-- SMART TAILOR (KUZHALI TAILORING - குழலி தையலகம்)
-- Normalised Relational Database Schema (SQLite / Room ORM v2)
-- Target Market: Tamil Nadu, India | Currency: INR (₹) | Default Unit: INCH
-- ============================================================================

PRAGMA foreign_keys = ON;

-- 1. SHOP ENTITY
CREATE TABLE IF NOT EXISTS shops (
    shop_id TEXT PRIMARY KEY NOT NULL,
    shop_name TEXT NOT NULL,
    shop_name_ta TEXT NOT NULL DEFAULT 'குழலி தையலகம்',
    owner_name TEXT NOT NULL DEFAULT 'Tailor Tamilselvi (தமிழ்செல்வி)',
    mobile_number TEXT NOT NULL CHECK(length(mobile_number) = 10 AND substr(mobile_number, 1, 1) IN ('6','7','8','9')),
    address TEXT NOT NULL,
    city TEXT NOT NULL DEFAULT 'Periyakulam',
    district TEXT NOT NULL DEFAULT 'Theni',
    state TEXT NOT NULL DEFAULT 'Tamil Nadu',
    pincode TEXT NOT NULL DEFAULT '625601',
    gst_enabled INTEGER NOT NULL DEFAULT 0 CHECK(gst_enabled IN (0, 1)),
    gstin TEXT,
    cgst_rate REAL NOT NULL DEFAULT 0.0 CHECK(cgst_rate >= 0),
    sgst_rate REAL NOT NULL DEFAULT 0.0 CHECK(sgst_rate >= 0),
    default_unit TEXT NOT NULL DEFAULT 'INCH' CHECK(default_unit IN ('INCH', 'CM')),
    default_language TEXT NOT NULL DEFAULT 'TA_EN' CHECK(default_language IN ('EN', 'TA', 'TA_EN')),
    upi_vpa TEXT DEFAULT 'kuzhalitailoring@upi',
    last_synced_at TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 2. USERS ENTITY (Authentication & RBAC: OWNER, MANAGER, TAILOR)
CREATE TABLE IF NOT EXISTS users (
    user_id TEXT PRIMARY KEY NOT NULL,
    shop_id TEXT NOT NULL,
    full_name TEXT NOT NULL,
    mobile_number TEXT NOT NULL UNIQUE CHECK(length(mobile_number) = 10 AND substr(mobile_number, 1, 1) IN ('6','7','8','9')),
    role TEXT NOT NULL CHECK(role IN ('OWNER', 'MANAGER', 'TAILOR')),
    pin_hash TEXT NOT NULL,
    biometric_enabled INTEGER NOT NULL DEFAULT 0 CHECK(biometric_enabled IN (0, 1)),
    can_view_financial_reports INTEGER NOT NULL DEFAULT 0 CHECK(can_view_financial_reports IN (0, 1)),
    is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (shop_id) REFERENCES shops(shop_id) ON DELETE CASCADE
);

-- 3. CUSTOMERS ENTITY (CRM with DPDP Act 2023 Consent Flags)
CREATE TABLE IF NOT EXISTS customers (
    customer_id TEXT PRIMARY KEY NOT NULL,
    shop_id TEXT NOT NULL,
    customer_code TEXT NOT NULL UNIQUE,
    customer_name TEXT NOT NULL CHECK(length(trim(customer_name)) >= 2),
    primary_mobile TEXT NOT NULL UNIQUE CHECK(length(primary_mobile) = 10 AND substr(primary_mobile, 1, 1) IN ('6','7','8','9')),
    alternate_mobile TEXT CHECK(alternate_mobile IS NULL OR (length(alternate_mobile) = 10 AND substr(alternate_mobile, 1, 1) IN ('6','7','8','9'))),
    address TEXT,
    area_city TEXT NOT NULL DEFAULT 'Periyakulam',
    registration_date TEXT NOT NULL DEFAULT (date('now')),
    customer_notes TEXT,
    design_preferences TEXT,
    preferred_language TEXT NOT NULL DEFAULT 'TA' CHECK(preferred_language IN ('EN', 'TA', 'TANGLISH')),
    photo_uri TEXT,
    promotional_consent INTEGER NOT NULL DEFAULT 0 CHECK(promotional_consent IN (0, 1)),
    promotional_consent_date TEXT,
    total_orders_count INTEGER NOT NULL DEFAULT 0,
    is_repeat_customer INTEGER NOT NULL DEFAULT 0 CHECK(is_repeat_customer IN (0, 1)),
    is_deleted INTEGER NOT NULL DEFAULT 0 CHECK(is_deleted IN (0, 1)),
    sync_status TEXT NOT NULL DEFAULT 'PENDING' CHECK(sync_status IN ('PENDING', 'SYNCED', 'CONFLICT')),
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (shop_id) REFERENCES shops(shop_id) ON DELETE RESTRICT
);
CREATE INDEX IF NOT EXISTS idx_customers_mobile ON customers(primary_mobile);
CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(customer_name);

-- 4. CUSTOMER FAMILY MEMBERS ENTITY
CREATE TABLE IF NOT EXISTS customer_family_members (
    family_member_id TEXT PRIMARY KEY NOT NULL,
    primary_customer_id TEXT NOT NULL,
    member_name TEXT NOT NULL CHECK(length(trim(member_name)) >= 2),
    relationship TEXT NOT NULL,
    gender TEXT CHECK(gender IN ('FEMALE', 'MALE', 'CHILD', 'OTHER')),
    age_group TEXT,
    notes TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (primary_customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_family_customer ON customer_family_members(primary_customer_id);

-- 5. GARMENTS ENTITY (Master Catalogue of Garment Types & Base Rates)
CREATE TABLE IF NOT EXISTS garments (
    garment_type_id TEXT PRIMARY KEY NOT NULL,
    garment_code TEXT NOT NULL UNIQUE CHECK(garment_code IN ('SHIRT', 'PANT', 'SAREE_BLOUSE', 'KURTI', 'SUIT_SALWAR', 'CUSTOM')),
    name_en TEXT NOT NULL,
    name_ta TEXT NOT NULL,
    base_stitching_charge REAL NOT NULL CHECK(base_stitching_charge >= 0),
    standard_fields_json TEXT NOT NULL,
    custom_fields_json TEXT NOT NULL DEFAULT '[]',
    is_active INTEGER NOT NULL DEFAULT 1
);

-- 6. MEASUREMENTS ENTITY (Master Profile Header per Customer/Family Member & Garment Type)
CREATE TABLE IF NOT EXISTS measurements (
    measurement_id TEXT PRIMARY KEY NOT NULL,
    customer_id TEXT NOT NULL,
    family_member_id TEXT,
    garment_type_id TEXT NOT NULL,
    profile_label TEXT NOT NULL,
    active_version_number INTEGER NOT NULL DEFAULT 1 CHECK(active_version_number >= 1),
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE RESTRICT,
    FOREIGN KEY (family_member_id) REFERENCES customer_family_members(family_member_id) ON DELETE SET NULL,
    FOREIGN KEY (garment_type_id) REFERENCES garments(garment_type_id) ON DELETE RESTRICT
);
CREATE INDEX IF NOT EXISTS idx_measurements_customer ON measurements(customer_id, garment_type_id);

-- 7. MEASUREMENT VERSIONS ENTITY (Immutable Historical Measurement Records)
CREATE TABLE IF NOT EXISTS measurement_versions (
    version_id TEXT PRIMARY KEY NOT NULL,
    measurement_id TEXT NOT NULL,
    version_number INTEGER NOT NULL CHECK(version_number >= 1),
    unit TEXT NOT NULL DEFAULT 'INCH' CHECK(unit IN ('INCH', 'CM')),
    parameters_json TEXT NOT NULL,
    custom_parameters_json TEXT DEFAULT '{}',
    measurement_notes TEXT,
    recorded_by_user_id TEXT,
    recorded_at TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(measurement_id, version_number),
    FOREIGN KEY (measurement_id) REFERENCES measurements(measurement_id) ON DELETE RESTRICT,
    FOREIGN KEY (recorded_by_user_id) REFERENCES users(user_id) ON DELETE SET NULL
);

-- Trigger to prevent overwriting historical measurement versions (Rule 5 & Section 8)
CREATE TRIGGER IF NOT EXISTS trg_prevent_measurement_overwrite
BEFORE UPDATE ON measurement_versions
BEGIN
    SELECT RAISE(ABORT, 'Historical measurement versions are immutable. Insert a new version_number instead.');
END;

-- 8. DESIGN REFERENCES ENTITY (Garment Design Catalogue & Customer Approvals)
CREATE TABLE IF NOT EXISTS design_references (
    design_id TEXT PRIMARY KEY NOT NULL,
    category TEXT NOT NULL CHECK(category IN (
        'SHIRT_DESIGNS', 'PANT_DESIGNS', 'SAREE_BLOUSE_DESIGNS', 'KURTI_DESIGNS',
        'NECK_PATTERNS', 'SLEEVE_PATTERNS', 'COLLAR_DESIGNS', 'EMBROIDERY_DESIGNS',
        'WEDDING_COLLECTION', 'FESTIVAL_COLLECTION'
    )),
    title TEXT NOT NULL,
    description TEXT,
    neck_pattern_ref TEXT,
    sleeve_pattern_ref TEXT,
    embroidery_instructions TEXT,
    customer_specific_instructions TEXT,
    image_uris_json TEXT NOT NULL DEFAULT '[]',
    customer_id TEXT,
    is_customer_approved INTEGER NOT NULL DEFAULT 0 CHECK(is_customer_approved IN (0, 1)),
    approved_at TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE SET NULL
);

-- 9. STAFF ENTITY
CREATE TABLE IF NOT EXISTS staff (
    staff_id TEXT PRIMARY KEY NOT NULL,
    user_id TEXT,
    full_name TEXT NOT NULL,
    mobile_number TEXT NOT NULL UNIQUE CHECK(length(mobile_number) = 10 AND substr(mobile_number, 1, 1) IN ('6','7','8','9')),
    role TEXT NOT NULL CHECK(role IN ('OWNER', 'MANAGER', 'MASTER_CUTTER', 'TAILOR', 'EMBROIDERER', 'HELPER')),
    joining_date TEXT NOT NULL,
    salary_type TEXT NOT NULL CHECK(salary_type IN ('MONTHLY', 'PIECE_RATE', 'WEEKLY')),
    base_pay REAL NOT NULL CHECK(base_pay >= 0),
    skills_json TEXT NOT NULL DEFAULT '[]',
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
);

-- 10. ORDERS ENTITY (Order Header supporting Multiple Garment Items)
CREATE TABLE IF NOT EXISTS orders (
    order_id TEXT PRIMARY KEY NOT NULL,
    order_code TEXT NOT NULL UNIQUE,
    customer_id TEXT NOT NULL,
    booking_date TEXT NOT NULL DEFAULT (date('now')),
    expected_delivery_date TEXT NOT NULL,
    priority TEXT NOT NULL DEFAULT 'NORMAL' CHECK(priority IN ('LOW', 'NORMAL', 'HIGH', 'URGENT_WEDDING')),
    total_stitching_charge REAL NOT NULL DEFAULT 0.0 CHECK(total_stitching_charge >= 0),
    additional_charges REAL NOT NULL DEFAULT 0.0 CHECK(additional_charges >= 0),
    discount_amount REAL NOT NULL DEFAULT 0.0 CHECK(discount_amount >= 0),
    tax_amount REAL NOT NULL DEFAULT 0.0 CHECK(tax_amount >= 0),
    net_total_amount REAL NOT NULL DEFAULT 0.0 CHECK(net_total_amount >= 0),
    advance_amount REAL NOT NULL DEFAULT 0.0 CHECK(advance_amount >= 0),
    total_paid_amount REAL NOT NULL DEFAULT 0.0 CHECK(total_paid_amount >= 0),
    pending_balance REAL NOT NULL DEFAULT 0.0 CHECK(pending_balance >= 0),
    order_status TEXT NOT NULL DEFAULT 'BOOKED' CHECK(order_status IN ('BOOKED', 'IN_PROGRESS', 'READY_FOR_TRIAL', 'READY_FOR_DELIVERY', 'DELIVERED', 'CANCELLED')),
    is_revenue_earned INTEGER NOT NULL DEFAULT 0 CHECK(is_revenue_earned IN (0, 1)),
    order_notes TEXT,
    sync_status TEXT NOT NULL DEFAULT 'PENDING' CHECK(sync_status IN ('PENDING', 'SYNCED', 'CONFLICT')),
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    CHECK(expected_delivery_date >= booking_date),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE RESTRICT
);
CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_delivery_date ON orders(expected_delivery_date);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(order_status);

-- 11. ORDER ITEMS ENTITY (Individual Garment Line Items inside an Order)
CREATE TABLE IF NOT EXISTS order_items (
    order_item_id TEXT PRIMARY KEY NOT NULL,
    order_id TEXT NOT NULL,
    garment_type_id TEXT NOT NULL,
    family_member_id TEXT,
    measurement_version_id TEXT NOT NULL,
    requested_design_id TEXT,
    approved_design_id TEXT,
    quantity INTEGER NOT NULL DEFAULT 1 CHECK(quantity >= 1),
    unit_stitching_charge REAL NOT NULL CHECK(unit_stitching_charge >= 0),
    line_total REAL NOT NULL CHECK(line_total >= 0),
    fabric_source TEXT NOT NULL DEFAULT 'CUSTOMER' CHECK(fabric_source IN ('CUSTOMER', 'SHOP_INVENTORY')),
    fabric_details TEXT,
    shop_inventory_item_id TEXT,
    fabric_meters_used REAL DEFAULT 0.0 CHECK(fabric_meters_used >= 0),
    stitching_instructions TEXT,
    assigned_staff_id TEXT,
    workflow_stage TEXT NOT NULL DEFAULT 'ORDER_BOOKED' CHECK(workflow_stage IN (
        'ORDER_BOOKED',
        'CLOTH_RECEIVED',
        'CUTTING_COMPLETED',
        'STITCHING_IN_PROGRESS',
        'QUALITY_CHECK',
        'READY_FOR_TRIAL',
        'ALTERATION_FINAL_APPROVAL',
        'DELIVERED'
    )),
    quality_check_passed INTEGER NOT NULL DEFAULT 0 CHECK(quality_check_passed IN (0, 1)),
    trial_status TEXT NOT NULL DEFAULT 'PENDING' CHECK(trial_status IN ('PENDING', 'SCHEDULED', 'APPROVED', 'ALTERATION_NEEDED', 'OVERRIDDEN')),
    delivery_override_authorized INTEGER NOT NULL DEFAULT 0 CHECK(delivery_override_authorized IN (0, 1)),
    delivery_override_reason TEXT,
    delivery_status TEXT NOT NULL DEFAULT 'PENDING' CHECK(delivery_status IN ('PENDING', 'READY', 'DELIVERED', 'CANCELLED')),
    delivered_at TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (garment_type_id) REFERENCES garments(garment_type_id) ON DELETE RESTRICT,
    FOREIGN KEY (measurement_version_id) REFERENCES measurement_versions(version_id) ON DELETE RESTRICT,
    FOREIGN KEY (requested_design_id) REFERENCES design_references(design_id) ON DELETE SET NULL,
    FOREIGN KEY (approved_design_id) REFERENCES design_references(design_id) ON DELETE SET NULL,
    FOREIGN KEY (assigned_staff_id) REFERENCES staff(staff_id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_staff ON order_items(assigned_staff_id);
CREATE INDEX IF NOT EXISTS idx_order_items_stage ON order_items(workflow_stage);

-- Trigger enforcing Quality Check & Trial Approval before DELIVERED (unless authorised override recorded)
CREATE TRIGGER IF NOT EXISTS trg_enforce_delivery_checks
BEFORE UPDATE OF workflow_stage ON order_items
WHEN NEW.workflow_stage = 'DELIVERED'
  AND NEW.quality_check_passed = 0
  AND NEW.delivery_override_authorized = 0
BEGIN
    SELECT RAISE(ABORT, 'Cannot mark garment DELIVERED without Quality Check & Trial approval unless an authorised override is recorded.');
END;

-- 12. ORDER STATUS HISTORY ENTITY (8-Stage Workflow Audit Trail)
CREATE TABLE IF NOT EXISTS order_status_history (
    history_id TEXT PRIMARY KEY NOT NULL,
    order_id TEXT NOT NULL,
    order_item_id TEXT NOT NULL,
    from_stage TEXT,
    to_stage TEXT NOT NULL,
    changed_by_staff_id TEXT,
    is_correction_rollback INTEGER NOT NULL DEFAULT 0 CHECK(is_correction_rollback IN (0, 1)),
    internal_remarks TEXT,
    changed_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (order_item_id) REFERENCES order_items(order_item_id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by_staff_id) REFERENCES staff(staff_id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_status_history_item ON order_status_history(order_item_id);

-- 13. ALTERATIONS ENTITY (Dedicated Alteration Module with Free/Paid Toggle)
CREATE TABLE IF NOT EXISTS alterations (
    alteration_id TEXT PRIMARY KEY NOT NULL,
    order_id TEXT NOT NULL,
    order_item_id TEXT NOT NULL,
    customer_id TEXT NOT NULL,
    garment_type_id TEXT NOT NULL,
    alteration_number INTEGER NOT NULL DEFAULT 1 CHECK(alteration_number >= 1),
    alteration_date TEXT NOT NULL DEFAULT (date('now')),
    alteration_reason TEXT NOT NULL,
    requested_changes TEXT NOT NULL,
    assigned_staff_id TEXT,
    is_paid_alteration INTEGER NOT NULL DEFAULT 0 CHECK(is_paid_alteration IN (0, 1)),
    additional_charge REAL NOT NULL DEFAULT 0.0 CHECK(additional_charge >= 0),
    expected_completion_date TEXT NOT NULL,
    alteration_status TEXT NOT NULL DEFAULT 'REQUESTED' CHECK(alteration_status IN ('REQUESTED', 'IN_PROGRESS', 'COMPLETED', 'DELIVERED')),
    completed_at TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    CHECK(is_paid_alteration = 1 OR additional_charge = 0.0),
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (order_item_id) REFERENCES order_items(order_item_id) ON DELETE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE RESTRICT
);

-- 14. INVOICES ENTITY
CREATE TABLE IF NOT EXISTS invoices (
    invoice_id TEXT PRIMARY KEY NOT NULL,
    invoice_number TEXT NOT NULL UNIQUE,
    order_id TEXT NOT NULL UNIQUE,
    customer_id TEXT NOT NULL,
    invoice_date TEXT NOT NULL DEFAULT (date('now')),
    subtotal_garment_charges REAL NOT NULL CHECK(subtotal_garment_charges >= 0),
    additional_charges REAL NOT NULL DEFAULT 0.0 CHECK(additional_charges >= 0),
    discount_amount REAL NOT NULL DEFAULT 0.0 CHECK(discount_amount >= 0),
    gst_enabled INTEGER NOT NULL DEFAULT 0 CHECK(gst_enabled IN (0, 1)),
    gstin TEXT,
    cgst_amount REAL NOT NULL DEFAULT 0.0 CHECK(cgst_amount >= 0),
    sgst_amount REAL NOT NULL DEFAULT 0.0 CHECK(sgst_amount >= 0),
    total_amount REAL NOT NULL CHECK(total_amount >= 0),
    advance_paid REAL NOT NULL DEFAULT 0.0 CHECK(advance_paid >= 0),
    total_payments_received REAL NOT NULL DEFAULT 0.0 CHECK(total_payments_received >= 0),
    balance_due REAL NOT NULL DEFAULT 0.0 CHECK(balance_due >= 0),
    payment_status TEXT NOT NULL DEFAULT 'UNPAID' CHECK(payment_status IN ('UNPAID', 'PARTIAL', 'PAID', 'REFUNDED')),
    pdf_uri TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE RESTRICT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE RESTRICT
);

-- 15. PAYMENTS ENTITY (Supports Advance, Partial, Full & Refund with Idempotency Key)
CREATE TABLE IF NOT EXISTS payments (
    payment_id TEXT PRIMARY KEY NOT NULL,
    idempotency_key TEXT NOT NULL UNIQUE,
    order_id TEXT NOT NULL,
    invoice_id TEXT,
    customer_id TEXT NOT NULL,
    transaction_type TEXT NOT NULL DEFAULT 'PAYMENT' CHECK(transaction_type IN ('ADVANCE', 'PARTIAL_PAYMENT', 'FINAL_PAYMENT', 'REFUND', 'ADJUSTMENT')),
    payment_method TEXT NOT NULL CHECK(payment_method IN ('CASH', 'UPI', 'BANK_TRANSFER', 'OTHER')),
    amount REAL NOT NULL CHECK(amount > 0),
    upi_reference_id TEXT,
    verification_status TEXT NOT NULL DEFAULT 'CONFIRMED' CHECK(verification_status IN ('PENDING_VERIFICATION', 'CONFIRMED', 'FAILED')),
    payment_timestamp TEXT NOT NULL DEFAULT (datetime('now')),
    recorded_by_user_id TEXT,
    notes TEXT,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE RESTRICT,
    FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id) ON DELETE SET NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE RESTRICT
);
CREATE INDEX IF NOT EXISTS idx_payments_order ON payments(order_id);
CREATE INDEX IF NOT EXISTS idx_payments_date ON payments(payment_timestamp);

-- 16. SUPPLIERS ENTITY
CREATE TABLE IF NOT EXISTS suppliers (
    supplier_id TEXT PRIMARY KEY NOT NULL,
    supplier_name TEXT NOT NULL,
    contact_person TEXT,
    mobile_number TEXT CHECK(mobile_number IS NULL OR (length(mobile_number) = 10 AND substr(mobile_number, 1, 1) IN ('6','7','8','9'))),
    address TEXT,
    gstin TEXT,
    materials_supplied TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 17. INVENTORY ITEMS ENTITY
CREATE TABLE IF NOT EXISTS inventory_items (
    item_id TEXT PRIMARY KEY NOT NULL,
    sku_code TEXT NOT NULL UNIQUE,
    item_name TEXT NOT NULL,
    category TEXT NOT NULL CHECK(category IN (
        'FABRIC', 'THREAD', 'BUTTONS', 'ZIPPERS', 'HOOKS',
        'LINING_MATERIAL', 'INTERLINING', 'EMBROIDERY_MATERIALS', 'OTHER_ACCESSORIES'
    )),
    unit_of_measure TEXT NOT NULL CHECK(unit_of_measure IN ('METERS', 'SPOOLS', 'PIECES', 'PACKETS', 'ROLLS')),
    current_stock REAL NOT NULL DEFAULT 0.0 CHECK(current_stock >= 0),
    low_stock_threshold REAL NOT NULL DEFAULT 5.0 CHECK(low_stock_threshold >= 0),
    unit_purchase_cost REAL NOT NULL DEFAULT 0.0 CHECK(unit_purchase_cost >= 0),
    stock_valuation REAL GENERATED ALWAYS AS (current_stock * unit_purchase_cost) VIRTUAL,
    preferred_supplier_id TEXT,
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (preferred_supplier_id) REFERENCES suppliers(supplier_id) ON DELETE SET NULL
);

-- 18. STOCK TRANSACTIONS ENTITY (Purchases, Order Consumption & Adjustments)
CREATE TABLE IF NOT EXISTS stock_transactions (
    transaction_id TEXT PRIMARY KEY NOT NULL,
    item_id TEXT NOT NULL,
    transaction_type TEXT NOT NULL CHECK(transaction_type IN ('PURCHASE', 'ORDER_CONSUMPTION', 'ADJUSTMENT_ADD', 'ADJUSTMENT_REDUCE')),
    quantity REAL NOT NULL CHECK(quantity > 0),
    unit_cost REAL NOT NULL DEFAULT 0.0 CHECK(unit_cost >= 0),
    supplier_id TEXT,
    order_id TEXT,
    order_item_id TEXT,
    fabric_source TEXT DEFAULT 'SHOP_INVENTORY' CHECK(fabric_source IN ('SHOP_INVENTORY', 'CUSTOMER')),
    remarks TEXT,
    transaction_date TEXT NOT NULL DEFAULT (datetime('now')),
    CHECK(NOT (transaction_type = 'ORDER_CONSUMPTION' AND fabric_source = 'CUSTOMER')),
    FOREIGN KEY (item_id) REFERENCES inventory_items(item_id) ON DELETE RESTRICT,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id) ON DELETE SET NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE SET NULL
);

-- 19. EXPENSES ENTITY
CREATE TABLE IF NOT EXISTS expenses (
    expense_id TEXT PRIMARY KEY NOT NULL,
    expense_date TEXT NOT NULL DEFAULT (date('now')),
    category TEXT NOT NULL CHECK(category IN (
        'RENT', 'ELECTRICITY', 'STAFF_SALARY', 'FABRIC_PURCHASES',
        'ACCESSORIES', 'MACHINE_MAINTENANCE', 'TRANSPORT', 'PACKAGING', 'OTHER_EXPENSES'
    )),
    amount REAL NOT NULL CHECK(amount > 0),
    payment_mode TEXT NOT NULL CHECK(payment_mode IN ('CASH', 'UPI', 'BANK_TRANSFER', 'OTHER')),
    description TEXT NOT NULL,
    staff_id TEXT,
    supplier_id TEXT,
    receipt_uri TEXT,
    recorded_by_user_id TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE SET NULL,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(expense_date);

-- 20. NOTIFICATIONS ENTITY (WhatsApp & SMS Templates + Consent Tracking)
CREATE TABLE IF NOT EXISTS notifications (
    notification_id TEXT PRIMARY KEY NOT NULL,
    customer_id TEXT NOT NULL,
    order_id TEXT,
    template_type TEXT NOT NULL CHECK(template_type IN (
        'ORDER_CONFIRMATION', 'CLOTH_RECEIVED', 'STITCHING_IN_PROGRESS',
        'READY_FOR_TRIAL', 'READY_FOR_DELIVERY', 'PAYMENT_REMINDER',
        'DELIVERY_CONFIRMATION', 'PROMOTIONAL_OFFER'
    )),
    message_category TEXT NOT NULL DEFAULT 'TRANSACTIONAL' CHECK(message_category IN ('TRANSACTIONAL', 'MARKETING')),
    channel TEXT NOT NULL CHECK(channel IN ('WHATSAPP', 'SMS')),
    message_preview_text TEXT NOT NULL,
    owner_previewed INTEGER NOT NULL DEFAULT 1 CHECK(owner_previewed = 1),
    delivery_status TEXT NOT NULL DEFAULT 'READY_TO_SEND' CHECK(delivery_status IN ('READY_TO_SEND', 'INTENT_OPENED', 'SENT', 'BLOCKED_NO_CONSENT')),
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE SET NULL
);

-- 21. AUDIT LOGS ENTITY (Tamper-Evident Security & Override Trail)
CREATE TABLE IF NOT EXISTS audit_logs (
    log_id TEXT PRIMARY KEY NOT NULL,
    user_id TEXT,
    user_role TEXT NOT NULL,
    action_type TEXT NOT NULL,
    entity_name TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    old_value_json TEXT,
    new_value_json TEXT,
    reason TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_audit_entity ON audit_logs(entity_name, entity_id);
