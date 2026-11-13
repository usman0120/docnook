package app.docnook.reader

import android.content.Context

/**
 * The Play build relies on ML Kit for OCR and leaves Tesseract out to keep the
 * download small (BLUEPRINT 4.3).
 */
object Tesseract {
    const val AVAILABLE = false

    @Suppress("UNUSED_PARAMETER")
    fun recognize(context: Context, path: String): Map<String, Any?> =
        throw UnsupportedOperationException("tesseract is not in this build")
}
