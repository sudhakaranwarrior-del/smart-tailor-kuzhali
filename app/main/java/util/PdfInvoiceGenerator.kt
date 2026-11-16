package `in`.kuzhalitailoring.smarttailor.util

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.pdf.PdfDocument
import java.io.File
import java.io.FileOutputStream

/**
 * Native Android PdfDocument generator for bilingual Tamil/English Tax & Non-GST Invoices
 * and Customer Measurement Sheets.
 */
object PdfInvoiceGenerator {
    fun generateInvoicePdf(
        context: Context,
        invoiceNumber: String,
        customerName: String,
        customerMobile: String,
        orderCode: String,
        totalAmount: Double,
        paidAmount: Double,
        balanceDue: Double
    ): File {
        val pdfDocument = PdfDocument()
        val pageInfo = PdfDocument.PageInfo.Builder(595, 842, 1).create()
        val page = pdfDocument.startPage(pageInfo)
        val canvas: Canvas = page.canvas
        val paint = Paint().apply { textSize = 14f; isAntiAlias = true }

        paint.textSize = 20f
        paint.isFakeBoldText = true
        canvas.drawText("KUZHALI TAILORING (குழலி தையலகம்)", 40f, 50f, paint)

        paint.textSize = 12f
        paint.isFakeBoldText = false
        canvas.drawText("Mariamman Kovil Kadai Veethi, Thenkarai, Periyakulam - 625601 | +91 90436 87516", 40f, 72f, paint)
        canvas.drawText("Invoice No: $invoiceNumber | Order ID: $orderCode", 40f, 105f, paint)
        canvas.drawText("Customer: $customerName ($customerMobile)", 40f, 125f, paint)
        canvas.drawText("Total Amount: Rs. ${String.format("%.2f", totalAmount)}", 40f, 165f, paint)
        canvas.drawText("Paid Amount:  Rs. ${String.format("%.2f", paidAmount)}", 40f, 185f, paint)
        canvas.drawText("Balance Due:  Rs. ${String.format("%.2f", balanceDue)}", 40f, 205f, paint)

        pdfDocument.finishPage(page)
        val outFile = File(context.cacheDir, "$invoiceNumber.pdf")
        FileOutputStream(outFile).use { pdfDocument.writeTo(it) }
        pdfDocument.close()
        return outFile
    }
}
