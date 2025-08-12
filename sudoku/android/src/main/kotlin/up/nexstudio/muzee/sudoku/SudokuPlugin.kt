package up.nexstudio.muzee.sudoku

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin

class SudokuPlugin: FlutterPlugin {
    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        // Nếu plugin bạn không expose method channel thì để trống
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        // cleanup
    }
}
