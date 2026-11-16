package `in`.kuzhalitailoring.smarttailor.util

import android.content.Context
import android.content.Intent
import android.net.Uri

/**
 * Generates standard NPCI UPI Payment Intent / QR payload.
 * IMPORTANT RULE (Module H): Never automatically mark a UPI intent launch as a verified payment.
 * All UPI intent launches start in PENDING_VERIFICATION status until confirmed by owner or webhook.
 */
object UpiIntentHelper {
    fun buildUpiUri(
        payeeVpa: String,
        payeeName: String = "Kuzhali Tailoring",
        amountInr: Double,
        transactionNote: String,
        orderCode: String
    ): Uri {
        return Uri.Builder()
            .scheme("upi")
            .authority("pay")
            .appendQueryParameter("pa", payeeVpa)
            .appendQueryParameter("pn", payeeName)
            .appendQueryParameter("am", String.format("%.2f", amountInr))
            .appendQueryParameter("cu", "INR")
            .appendQueryParameter("tn", "$orderCode - $transactionNote")
            .build()
    }

    fun launchUpiPaymentChooser(context: Context, uri: Uri) {
        val intent = Intent(Intent.ACTION_VIEW, uri)
        val chooser = Intent.createChooser(intent, "Pay with UPI App / UPI ஆப் மூலம் செலுத்தவும்")
        context.startActivity(chooser)
    }
}
