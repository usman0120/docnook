package app.docnook.reader

import android.content.Context
import android.graphics.BitmapFactory
import com.googlecode.tesseract.android.TessBaseAPI
import java.io.File

/**
 * Tesseract English OCR for phones without Google Play services (BLUEPRINT
 * 4.3). Only the `direct` APK carries it; the `play` flavor has a stub. The
 * "fast" English model ships in assets and is copied to app-private storage on
 * first use, because Tesseract reads it from a folder.
 */
object Tesseract {
    const val AVAILABLE = true

    private var api: TessBaseAPI? = null

    @Synchronized
    fun recognize(context: Context, path: String): Map<String, Any?> {
        val bitmap = BitmapFactory.decodeFile(path)
            ?: throw IllegalArgumentException("unreadable image")
        val tess = api ?: open(context).also { api = it }
        try {
            tess.setImage(bitmap)
            tess.getUTF8Text()
            val lines = mutableListOf<Map<String, Any?>>()
            val iterator = tess.resultIterator
            if (iterator != null) {
                val level = TessBaseAPI.PageIteratorLevel.RIL_TEXTLINE
                iterator.begin()
                do {
                    val text = iterator.getUTF8Text(level)?.trim().orEmpty()
                    if (text.isNotEmpty()) {
                        val box = iterator.getBoundingRect(level)
                        lines.add(
                            mapOf(
                                "text" to text,
                                "left" to box.left,
                                "top" to box.top,
                                "width" to box.width(),
                                "height" to box.height(),
                            ),
                        )
                    }
                } while (iterator.next(level))
                iterator.delete()
            }
            return mapOf(
                "width" to bitmap.width,
                "height" to bitmap.height,
                "lines" to lines,
            )
        } finally {
            tess.clear()
            bitmap.recycle()
        }
    }

    private fun open(context: Context): TessBaseAPI {
        val root = File(context.filesDir, "tesseract")
        val data = File(root, "tessdata/eng.traineddata")
        if (!data.exists()) {
            data.parentFile?.mkdirs()
            val partial = File(data.path + ".part")
            context.assets.open("tessdata/eng.traineddata").use { input ->
                partial.outputStream().use { input.copyTo(it) }
            }
            partial.renameTo(data)
        }
        val tess = TessBaseAPI()
        if (!tess.init(root.absolutePath, "eng")) {
            tess.recycle()
            throw IllegalStateException("tesseract init failed")
        }
        return tess
    }
}
