package android.print;

public class FlutterWriteResultCallback extends PrintDocumentAdapter.WriteResultCallback {

    public interface Callback {
        void onWriteFinished(PageRange[] pages);
        void onWriteFailed(CharSequence error);
        void onWriteCancelled();
    }

    private final Callback callback;

    public FlutterWriteResultCallback(Callback callback) {
        this.callback = callback;
    }

    @Override
    public void onWriteFinished(PageRange[] pages) {
        if (callback != null) {
            callback.onWriteFinished(pages);
        }
    }

    @Override
    public void onWriteFailed(CharSequence error) {
        if (callback != null) {
            callback.onWriteFailed(error);
        }
    }

    @Override
    public void onWriteCancelled() {
        if (callback != null) {
            callback.onWriteCancelled();
        }
    }
}

