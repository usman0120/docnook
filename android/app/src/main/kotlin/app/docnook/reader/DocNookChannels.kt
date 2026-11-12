package app.docnook.reader

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.provider.Settings
import android.view.WindowManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.util.concurrent.Executors

/**
 * The small Kotlin glue layer (BLUEPRINT 4.4): incoming VIEW/SEND intents,
 * copying content URIs into the cache, MediaStore saves to Documents/DocNook,
 * SAF folder grants, "open with another app", launcher shortcuts and
 * FLAG_SECURE. Everything else lives in Dart.
 */
class DocNookChannels(
    private val activity: Activity,
    messenger: BinaryMessenger,
) {
    private val methods = MethodChannel(messenger, "docnook/platform")
    private val intents = EventChannel(messenger, "docnook/intents")
    private val io = Executors.newSingleThreadExecutor()
    private var sink: EventChannel.EventSink? = null
    private var pendingIntent: Map<String, Any?>? = null
    private var pendingTreeResult: MethodChannel.Result? = null
    private var pendingFilesResult: MethodChannel.Result? = null
    private var secure = false

    fun register() {
        methods.setMethodCallHandler(::handle)
        intents.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                sink = events
                pendingIntent?.let { events.success(it) }
                pendingIntent = null
            }

            override fun onCancel(arguments: Any?) {
                sink = null
            }
        })
        publishShortcuts()
    }

    fun dispose() {
        methods.setMethodCallHandler(null)
        intents.setStreamHandler(null)
        io.shutdown()
    }

    // ------------------------------------------------------------- intents

    fun onIntent(intent: Intent?, initial: Boolean) {
        val payload = describe(intent) ?: return
        val withFlag = payload + ("initial" to initial)
        val events = sink
        if (events == null) pendingIntent = withFlag else events.success(withFlag)
    }

    /** Turns an incoming intent into a plain map Dart can read. */
    private fun describe(intent: Intent?): Map<String, Any?>? {
        if (intent == null) return null
        val shortcut = intent.getStringExtra(EXTRA_SHORTCUT)
        if (shortcut != null) return mapOf("kind" to "shortcut", "id" to shortcut)

        val uris = mutableListOf<Uri>()
        when (intent.action) {
            Intent.ACTION_VIEW -> intent.data?.let(uris::add)
            Intent.ACTION_SEND -> {
                parcelableUri(intent)?.let(uris::add)
                if (uris.isEmpty()) {
                    // Plain shared text (no file): handed to Dart as text.
                    val text = intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()
                    if (text != null) return mapOf("kind" to "text", "text" to text)
                }
            }
            Intent.ACTION_SEND_MULTIPLE -> uris.addAll(parcelableUris(intent))
            else -> return null
        }
        if (uris.isEmpty()) return null
        val kind = if (intent.action == Intent.ACTION_VIEW) "view" else "share"
        return mapOf(
            "kind" to kind,
            "files" to uris.map { uri ->
                mapOf(
                    "uri" to uri.toString(),
                    "name" to displayName(uri),
                    "size" to sizeOf(uri),
                    "mime" to (intent.type ?: activity.contentResolver.getType(uri)),
                )
            },
        )
    }

    @Suppress("DEPRECATION")
    private fun parcelableUri(intent: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= 33) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            intent.getParcelableExtra(Intent.EXTRA_STREAM) as? Uri
        }

    @Suppress("DEPRECATION")
    private fun parcelableUris(intent: Intent): List<Uri> =
        if (Build.VERSION.SDK_INT >= 33) {
            intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java) ?: emptyList()
        } else {
            intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM) ?: emptyList()
        }

    private fun displayName(uri: Uri): String? {
        if (uri.scheme == "file") return uri.lastPathSegment
        return try {
            activity.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                ?.use { c -> if (c.moveToFirst() && !c.isNull(0)) c.getString(0) else null }
        } catch (_: Exception) {
            null
        } ?: uri.lastPathSegment
    }

    private fun sizeOf(uri: Uri): Long? {
        if (uri.scheme == "file") return uri.path?.let { File(it).length() }
        return try {
            activity.contentResolver.query(uri, arrayOf(OpenableColumns.SIZE), null, null, null)
                ?.use { c -> if (c.moveToFirst() && !c.isNull(0)) c.getLong(0) else null }
        } catch (_: Exception) {
            null
        }
    }

    // ------------------------------------------------------------- methods

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "copyToCache" -> background(result) {
                copyToCache(call.argument<String>("uri")!!, call.argument<String>("dest")!!)
            }
            "saveToDocuments" -> background(result) {
                saveToDocuments(
                    call.argument<String>("source")!!,
                    call.argument<String>("subdir")!!,
                    call.argument<String>("name")!!,
                    call.argument<String>("mime") ?: "application/octet-stream",
                )
            }
            "openWith" -> result.success(
                openWith(call.argument<String>("path")!!, call.argument<String>("mime")),
            )
            "share" -> result.success(
                share(call.argument<List<String>>("paths")!!, call.argument<String>("mime")),
            )
            "pickTree" -> pickTree(result)
            "pickFiles" -> pickFiles(
                result,
                call.argument<List<String>>("mimes") ?: listOf("*/*"),
                call.argument<Boolean>("multiple") ?: false,
            )
            "persistedTrees" -> result.success(
                activity.contentResolver.persistedUriPermissions
                    .filter { it.isReadPermission }
                    .map { it.uri.toString() },
            )
            "hasAllFilesAccess" -> result.success(hasAllFilesAccess())
            "hasStorageAccess" -> result.success(hasStorageAccess())
            "requestLegacyStorage" -> requestLegacyStorage(result)
            "storageRoot" -> {
                @Suppress("DEPRECATION")
                result.success(Environment.getExternalStorageDirectory().absolutePath)
            }
            "listTree" -> background(result) { listTree(call.argument<String>("uri")!!) }
            "treeName" -> result.success(treeName(call.argument<String>("uri")!!))
            "releaseTree" -> {
                try {
                    activity.contentResolver.releasePersistableUriPermission(
                        Uri.parse(call.argument<String>("uri")!!),
                        Intent.FLAG_GRANT_READ_URI_PERMISSION,
                    )
                } catch (_: SecurityException) {
                }
                result.success(null)
            }
            "deleteDocument" -> background(result) { deleteDocument(call.argument<String>("uri")!!) }
            "renameDocument" -> background(result) {
                renameDocument(call.argument<String>("uri")!!, call.argument<String>("name")!!)
            }
            "requestAllFilesAccess" -> result.success(requestAllFilesAccess())
            "setSecure" -> {
                secure = call.argument<Boolean>("on") ?: false
                applySecureFlag()
                result.success(null)
            }
            "sdkInt" -> result.success(Build.VERSION.SDK_INT)
            "totalMemoryMb" -> {
                val info = android.app.ActivityManager.MemoryInfo()
                (activity.getSystemService(Activity.ACTIVITY_SERVICE) as android.app.ActivityManager)
                    .getMemoryInfo(info)
                result.success((info.totalMem / (1024 * 1024)).toInt())
            }
            "openTtsSettings" -> result.success(
                startSafely(Intent("com.android.settings.TTS_SETTINGS")),
            )
            else -> result.notImplemented()
        }
    }

    /** Runs [work] off the main thread and replies on it. */
    private fun background(result: MethodChannel.Result, work: () -> Any?) {
        io.execute {
            try {
                val value = work()
                activity.runOnUiThread { result.success(value) }
            } catch (e: SecurityException) {
                activity.runOnUiThread { result.error("permissionDenied", null, null) }
            } catch (e: java.io.FileNotFoundException) {
                activity.runOnUiThread { result.error("notFound", null, null) }
            } catch (e: java.io.IOException) {
                val code = if (e.message?.contains("ENOSPC") == true) "outOfSpace" else "io"
                activity.runOnUiThread { result.error(code, null, null) }
            } catch (e: Exception) {
                activity.runOnUiThread { result.error("unknown", e.javaClass.simpleName, null) }
            }
        }
    }

    /** Streams a content URI into an app-private file; returns bytes copied. */
    private fun copyToCache(uriString: String, dest: String): Long {
        val uri = Uri.parse(uriString)
        val target = File(dest)
        target.parentFile?.mkdirs()
        val partial = File("$dest.part")
        val input = if (uri.scheme == "file") {
            FileInputStream(File(uri.path!!))
        } else {
            activity.contentResolver.openInputStream(uri)
                ?: throw java.io.FileNotFoundException()
        }
        var total = 0L
        input.use { inp ->
            partial.outputStream().use { out ->
                val buffer = ByteArray(256 * 1024)
                while (true) {
                    val n = inp.read(buffer)
                    if (n < 0) break
                    out.write(buffer, 0, n)
                    total += n
                }
            }
        }
        if (!partial.renameTo(target)) {
            partial.delete()
            throw java.io.IOException("rename")
        }
        return total
    }

    /**
     * Saves a finished file to Documents/DocNook/<subdir>/ and returns its
     * absolute path when one exists (all Android versions) plus its URI.
     * Android 10+ uses MediaStore and needs no permission.
     */
    private fun saveToDocuments(source: String, subdir: String, name: String, mime: String): Map<String, String?> {
        val src = File(source)
        if (Build.VERSION.SDK_INT >= 29) {
            val relative = "${Environment.DIRECTORY_DOCUMENTS}/DocNook/$subdir/"
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, name)
                put(MediaStore.MediaColumns.MIME_TYPE, mime)
                put(MediaStore.MediaColumns.RELATIVE_PATH, relative)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val resolver = activity.contentResolver
            val collection = MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            val uri = resolver.insert(collection, values) ?: throw java.io.IOException("insert")
            try {
                resolver.openOutputStream(uri)?.use { out -> src.inputStream().use { it.copyTo(out) } }
                    ?: throw java.io.IOException("open")
                values.clear()
                values.put(MediaStore.MediaColumns.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
            } catch (e: Exception) {
                resolver.delete(uri, null, null)
                throw e
            }
            // MediaStore may rename on collision ("x (1).pdf"); report the real name.
            val finalName = resolver.query(uri, arrayOf(MediaStore.MediaColumns.DISPLAY_NAME), null, null, null)
                ?.use { c -> if (c.moveToFirst()) c.getString(0) else null } ?: name
            @Suppress("DEPRECATION")
            val root = Environment.getExternalStorageDirectory()
            val path = File(root, "$relative$finalName").absolutePath
            return mapOf("uri" to uri.toString(), "path" to path, "name" to finalName)
        }
        @Suppress("DEPRECATION")
        val dir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS), "DocNook/$subdir")
        dir.mkdirs()
        val target = File(dir, name)
        src.copyTo(target, overwrite = false)
        return mapOf("uri" to Uri.fromFile(target).toString(), "path" to target.absolutePath, "name" to target.name)
    }

    private fun contentUri(path: String): Uri {
        val file = File(path)
        return FileProvider.getUriForFile(activity, "${activity.packageName}.files", file)
    }

    /** A content:// URI for a file, or a MediaStore URI passed straight through. */
    private fun shareableUri(pathOrUri: String): Uri =
        if (pathOrUri.startsWith("content://")) Uri.parse(pathOrUri) else contentUri(pathOrUri)

    private fun openWith(path: String, mime: String?): Boolean {
        val uri = try {
            shareableUri(path)
        } catch (_: IllegalArgumentException) {
            return false
        }
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, mime ?: "*/*")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        return startSafely(Intent.createChooser(intent, null))
    }

    private fun share(paths: List<String>, mime: String?): Boolean {
        val uris = try {
            ArrayList(paths.map(::shareableUri))
        } catch (_: IllegalArgumentException) {
            return false
        }
        val intent = if (uris.size == 1) {
            Intent(Intent.ACTION_SEND).apply { putExtra(Intent.EXTRA_STREAM, uris[0]) }
        } else {
            Intent(Intent.ACTION_SEND_MULTIPLE).apply { putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris) }
        }
        intent.type = mime ?: "*/*"
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        return startSafely(Intent.createChooser(intent, null))
    }

    private fun startSafely(intent: Intent): Boolean = try {
        activity.startActivity(intent)
        true
    } catch (_: ActivityNotFoundException) {
        false
    }

    // ---------------------------------------------------- storage access

    private fun pickTree(result: MethodChannel.Result) {
        pendingTreeResult?.success(null)
        pendingTreeResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
        }
        @Suppress("DEPRECATION")
        try {
            activity.startActivityForResult(intent, REQUEST_TREE)
        } catch (_: ActivityNotFoundException) {
            pendingTreeResult = null
            result.success(null)
        }
    }

    /**
     * The system document picker (ACTION_OPEN_DOCUMENT). Needs no storage
     * permission; the grant is made persistable so Recents can reopen it.
     */
    private fun pickFiles(result: MethodChannel.Result, mimes: List<String>, multiple: Boolean) {
        pendingFilesResult?.success(null)
        pendingFilesResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = if (mimes.size == 1) mimes[0] else "*/*"
            if (mimes.size > 1) putExtra(Intent.EXTRA_MIME_TYPES, mimes.toTypedArray())
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, multiple)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
        }
        @Suppress("DEPRECATION")
        try {
            activity.startActivityForResult(intent, REQUEST_FILES)
        } catch (_: ActivityNotFoundException) {
            pendingFilesResult = null
            result.success(null)
        }
    }

    private fun onFilesPicked(resultCode: Int, data: Intent?) {
        val result = pendingFilesResult ?: return
        pendingFilesResult = null
        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(null)
            return
        }
        val uris = mutableListOf<Uri>()
        val clip = data.clipData
        if (clip != null) {
            for (i in 0 until clip.itemCount) clip.getItemAt(i).uri?.let(uris::add)
        } else {
            data.data?.let(uris::add)
        }
        result.success(
            uris.map { uri ->
                try {
                    activity.contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                } catch (_: SecurityException) {
                    // Not persistable (some providers); usable for this session.
                }
                mapOf(
                    "uri" to uri.toString(),
                    "name" to displayName(uri),
                    "size" to sizeOf(uri),
                    "mime" to activity.contentResolver.getType(uri),
                )
            },
        )
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_FILES) {
            onFilesPicked(resultCode, data)
            return true
        }
        if (requestCode != REQUEST_TREE) return false
        val result = pendingTreeResult ?: return true
        pendingTreeResult = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return true
        }
        try {
            activity.contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        } catch (_: SecurityException) {
            // Grant could not be persisted; still usable for this session.
        }
        result.success(uri.toString())
        return true
    }

    /** True when DocNook may list documents across shared storage. */
    private fun hasStorageAccess(): Boolean =
        if (Build.VERSION.SDK_INT >= 30) {
            Environment.isExternalStorageManager()
        } else {
            ContextCompat.checkSelfPermission(activity, android.Manifest.permission.READ_EXTERNAL_STORAGE) ==
                PackageManager.PERMISSION_GRANTED
        }

    private var pendingPermissionResult: MethodChannel.Result? = null

    /** Android 7-10: the runtime READ_EXTERNAL_STORAGE prompt. */
    private fun requestLegacyStorage(result: MethodChannel.Result) {
        if (hasStorageAccess()) {
            result.success(true)
            return
        }
        pendingPermissionResult?.success(false)
        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            activity,
            arrayOf(android.Manifest.permission.READ_EXTERNAL_STORAGE),
            REQUEST_STORAGE,
        )
    }

    fun onRequestPermissionsResult(requestCode: Int, grantResults: IntArray): Boolean {
        if (requestCode != REQUEST_STORAGE) return false
        val result = pendingPermissionResult ?: return true
        pendingPermissionResult = null
        result.success(grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED)
        return true
    }

    private fun treeName(uriString: String): String? = try {
        val tree = Uri.parse(uriString)
        val doc = DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))
        activity.contentResolver.query(doc, arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME), null, null, null)
            ?.use { c -> if (c.moveToFirst()) c.getString(0) else null }
    } catch (_: Exception) {
        null
    }

    /**
     * Lists every file under a granted folder tree (SAF), skipping hidden
     * names and Android/. Capped so a huge tree cannot exhaust memory.
     */
    private fun listTree(uriString: String): List<Map<String, Any?>> {
        val tree = Uri.parse(uriString)
        val resolver = activity.contentResolver
        val out = ArrayList<Map<String, Any?>>()
        val queue = ArrayDeque<String>()
        queue.add(DocumentsContract.getTreeDocumentId(tree))
        val columns = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_SIZE,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED,
        )
        var visitedDirs = 0
        while (queue.isNotEmpty() && out.size < 50000 && visitedDirs < 20000) {
            val parent = queue.removeFirst()
            visitedDirs++
            val children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, parent)
            resolver.query(children, columns, null, null, null)?.use { c ->
                while (c.moveToNext()) {
                    val id = c.getString(0) ?: continue
                    val name = c.getString(1) ?: continue
                    if (name.startsWith(".")) continue
                    val mime = c.getString(2)
                    if (mime == DocumentsContract.Document.MIME_TYPE_DIR) {
                        if (name != "Android") queue.add(id)
                        continue
                    }
                    out.add(
                        mapOf(
                            "uri" to DocumentsContract.buildDocumentUriUsingTree(tree, id).toString(),
                            "name" to name,
                            "mime" to mime,
                            "size" to (if (c.isNull(3)) null else c.getLong(3)),
                            "modified" to (if (c.isNull(4)) null else c.getLong(4)),
                        ),
                    )
                }
            }
        }
        return out
    }

    /** Deletes a document given as a path or a document URI. */
    private fun deleteDocument(target: String): Boolean {
        if (!target.startsWith("content://")) return File(target).delete()
        val uri = Uri.parse(target)
        return try {
            DocumentsContract.deleteDocument(activity.contentResolver, uri)
        } catch (_: Exception) {
            activity.contentResolver.delete(uri, null, null) > 0
        }
    }

    /** Renames in place; returns the new path or URI, or null on failure. */
    private fun renameDocument(target: String, name: String): String? {
        if (!target.startsWith("content://")) {
            val file = File(target)
            val renamed = File(file.parentFile, name)
            if (renamed.exists()) return null
            return if (file.renameTo(renamed)) renamed.absolutePath else null
        }
        return try {
            DocumentsContract.renameDocument(activity.contentResolver, Uri.parse(target), name)?.toString()
        } catch (_: Exception) {
            null
        }
    }

    private fun hasAllFilesAccess(): Boolean =
        if (Build.VERSION.SDK_INT >= 30) Environment.isExternalStorageManager() else false

    private fun requestAllFilesAccess(): Boolean {
        if (Build.VERSION.SDK_INT < 30) return false
        val specific = Intent(
            Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
            Uri.parse("package:${activity.packageName}"),
        )
        return startSafely(specific) || startSafely(Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION))
    }

    // ------------------------------------------------- shortcuts, secure

    private fun publishShortcuts() {
        if (Build.VERSION.SDK_INT < 25) return
        val manager = activity.getSystemService(ShortcutManager::class.java) ?: return
        fun shortcut(id: String, label: String, icon: Int) = ShortcutInfo.Builder(activity, id)
            .setShortLabel(label)
            .setIcon(Icon.createWithResource(activity, icon))
            .setIntent(
                Intent(activity, MainActivity::class.java)
                    .setAction(Intent.ACTION_MAIN)
                    .putExtra(EXTRA_SHORTCUT, id)
                    .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP),
            )
            .build()
        try {
            manager.dynamicShortcuts = listOf(
                shortcut("scan", activity.getString(R.string.shortcut_scan), R.drawable.ic_shortcut_scan),
                shortcut("merge", activity.getString(R.string.shortcut_merge), R.drawable.ic_shortcut_merge),
                shortcut("recent", activity.getString(R.string.shortcut_recent), R.drawable.ic_shortcut_recent),
            )
        } catch (_: Exception) {
            // Launchers may reject shortcuts (rate limits); they are optional.
        }
    }

    fun applySecureFlag() {
        if (secure) {
            activity.window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        } else {
            activity.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }

    companion object {
        private const val REQUEST_TREE = 4107
        private const val REQUEST_FILES = 4108
        private const val REQUEST_STORAGE = 4109
        const val EXTRA_SHORTCUT = "docnook.shortcut"
    }
}
