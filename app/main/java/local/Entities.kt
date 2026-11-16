package `in`.kuzhalitailoring.smarttailor.data.local

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(tableName = "shops")
data class ShopEntity(
    @PrimaryKey val shopId: String = "SHOP_01",
    val shopName: String = "Kuzhali Tailoring",
    val shopNameTa: String = "குழலி தையலகம்",
    val ownerName: String = "Tailor Tamilselvi (தமிழ்செல்வி)",
    val mobileNumber: String = "9043687516",
    val address: String = "Mariamman Kovil Kadai Veethi, Thenkarai",
    val city: String = "Periyakulam",
    val district: String = "Theni",
    val state: String = "Tamil Nadu",
    val pincode: String = "625601",
    val gstEnabled: Boolean = false,
    val gstin: String? = null,
    val defaultUnit: String = "INCH",
    val defaultLanguage: String = "TA_EN",
    val upiVpa: String = "kuzhalitailoring@upi",
    val lastSyncedAt: String? = null
)

@Entity(
    tableName = "customers",
    indices = [Index(value = ["primaryMobile"], unique = true), Index(value = ["customerName"])]
)
data class CustomerEntity(
    @PrimaryKey val customerId: String,
    val customerCode: String,
    val customerName: String,
    val primaryMobile: String,
    val alternateMobile: String? = null,
    val address: String? = null,
    val areaCity: String = "Periyakulam",
    val registrationDate: String,
    val customerNotes: String? = null,
    val designPreferences: String? = null,
    val preferredLanguage: String = "TA",
    val photoUri: String? = null,
    val promotionalConsent: Boolean = false,
    val totalOrdersCount: Int = 0,
    val isRepeatCustomer: Boolean = false,
    val syncStatus: String = "PENDING"
)

@Entity(tableName = "measurement_versions")
data class MeasurementVersionEntity(
    @PrimaryKey val versionId: String,
    val measurementId: String,
    val versionNumber: Int,
    val unit: String = "INCH",
    val parametersJson: String,
    val customParametersJson: String = "{}",
    val measurementNotes: String? = null,
    val recordedAt: String
)

@Entity(tableName = "orders")
data class OrderEntity(
    @PrimaryKey val orderId: String,
    val orderCode: String,
    val customerId: String,
    val bookingDate: String,
    val expectedDeliveryDate: String,
    val priority: String = "NORMAL",
    val totalStitchingCharge: Double,
    val additionalCharges: Double = 0.0,
    val discountAmount: Double = 0.0,
    val taxAmount: Double = 0.0,
    val netTotalAmount: Double,
    val advanceAmount: Double,
    val totalPaidAmount: Double,
    val pendingBalance: Double,
    val orderStatus: String = "BOOKED",
    val isRevenueEarned: Boolean = false,
    val orderNotes: String? = null,
    val syncStatus: String = "PENDING"
)

@Entity(tableName = "order_items")
data class OrderItemEntity(
    @PrimaryKey val orderItemId: String,
    val orderId: String,
    val garmentTypeId: String,
    val measurementVersionId: String,
    val requestedDesignId: String? = null,
    val approvedDesignId: String? = null,
    val quantity: Int = 1,
    val unitStitchingCharge: Double,
    val lineTotal: Double,
    val fabricSource: String = "CUSTOMER",
    val fabricDetails: String? = null,
    val assignedStaffId: String? = null,
    val workflowStage: String = "ORDER_BOOKED",
    val qualityCheckPassed: Boolean = false,
    val trialStatus: String = "PENDING",
    val deliveryOverrideAuthorized: Boolean = false,
    val deliveryOverrideReason: String? = null,
    val deliveryStatus: String = "PENDING"
)
