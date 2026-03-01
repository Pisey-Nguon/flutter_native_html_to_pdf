package android.print;

public class FlutterLayoutResultCallback extends PrintDocumentAdapter.LayoutResultCallback {

    public interface Callback {
        void onLayoutFinished(PrintDocumentInfo info, boolean changed);
        void onLayoutFailed(CharSequence error);
        void onLayoutCancelled();
    }

    private final Callback callback;

    public FlutterLayoutResultCallback(Callback callback) {
        this.callback = callback;
    }

    @Override
    public void onLayoutFinished(PrintDocumentInfo info, boolean changed) {
        if (callback != null) {
            callback.onLayoutFinished(info, changed);
        }
    }

    @Override
    public void onLayoutFailed(CharSequence error) {
        if (callback != null) {
            callback.onLayoutFailed(error);
        }
    }

    @Override
    public void onLayoutCancelled() {
        if (callback != null) {
            callback.onLayoutCancelled();
        }
    }
}

