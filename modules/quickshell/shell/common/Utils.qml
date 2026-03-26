pragma Singleton
import QtQuick

QtObject {
    function formatBytes(bytes) {
        if (bytes < 1024) return bytes + "B"
        if (bytes < 1048576) return (bytes / 1024).toFixed(1) + "K"
        if (bytes < 1073741824) return (bytes / 1048576).toFixed(1) + "M"
        return (bytes / 1073741824).toFixed(1) + "G"
    }
}
