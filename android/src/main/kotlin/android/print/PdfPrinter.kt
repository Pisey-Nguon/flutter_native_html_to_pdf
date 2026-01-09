package android.print

import android.os.Build
import android.os.CancellationSignal
import android.os.ParcelFileDescriptor
import java.io.File

class PdfPrinter(private val printAttributes: PrintAttributes) {

    interface Callback {
        fun onSuccess(filePath: String)
        fun onFailure()
    }


    fun print(
        printAdapter: PrintDocumentAdapter,
        path: File,
        fileName: String,
        callback: Callback
    ) {
        // Support for min API 16 is required
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            printAdapter.onLayout(
                null,
                printAttributes,
                null,
                object : PrintDocumentAdapter.LayoutResultCallback() {

                    override fun onLayoutFinished(info: PrintDocumentInfo, changed: Boolean) {
                        val outputFileDescriptor = getOutputFile(path, fileName)
                        printAdapter.onWrite(arrayOf(PageRange.ALL_PAGES),
                            outputFileDescriptor,
                            CancellationSignal(),
                            object : PrintDocumentAdapter.WriteResultCallback() {

                                override fun onWriteFinished(pages: Array<PageRange>) {
                                    super.onWriteFinished(pages)

                                    // Close the file descriptor to ensure data is flushed
                                    try {
                                        outputFileDescriptor.close()
                                    } catch (e: Exception) {
                                        android.util.Log.e("PdfPrinter", "Error closing file descriptor", e)
                                    }

                                    if (pages.isEmpty()) {
                                        callback.onFailure()
                                        return
                                    }

                                    File(path, fileName).let {
                                        callback.onSuccess(it.absolutePath)
                                    }

                                }

                                override fun onWriteFailed(error: CharSequence?) {
                                    super.onWriteFailed(error)
                                    
                                    // Close the file descriptor on failure
                                    try {
                                        outputFileDescriptor.close()
                                    } catch (e: Exception) {
                                        android.util.Log.e("PdfPrinter", "Error closing file descriptor", e)
                                    }
                                    
                                    callback.onFailure()
                                }

                                override fun onWriteCancelled() {
                                    super.onWriteCancelled()
                                    
                                    // Close the file descriptor on cancellation
                                    try {
                                        outputFileDescriptor.close()
                                    } catch (e: Exception) {
                                        android.util.Log.e("PdfPrinter", "Error closing file descriptor", e)
                                    }
                                    
                                    callback.onFailure()
                                }
                            })
                    }
                },
                null
            )
        }
    }
}


private fun getOutputFile(path: File, fileName: String): ParcelFileDescriptor {
    if (!path.exists()) {
        path.mkdirs()
    }

    File(path, fileName).let {
        it.createNewFile()
        return ParcelFileDescriptor.open(it, ParcelFileDescriptor.MODE_READ_WRITE)
    }
}
