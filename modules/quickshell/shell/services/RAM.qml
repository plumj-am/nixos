pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../common" as Common

Item {
    id: root

    property real total: 0.0
    property real used: 0.0

    FileView {
        id: meminfoFile
        path: "/proc/meminfo"
        onLoadFailed: function (error) {
            console.log("RAM Service: FileView load failed:", error);
        }
    }

    Timer {
        interval: Common.Config.data.ram?.updateInterval ?? 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: updateRamStats()
    }

    function updateRamStats() {
        meminfoFile.reload();
        const content = meminfoFile.text();
        if (content === "")
            return;
        const lines = content.split('\n');
        const stats = {};

        for (const line of lines) {
            const parts = line.split(/\s+/);
            if (parts.length >= 2) {
                const key = parts[0].slice(0, -1);
                const value = parseFloat(parts[1]);
                stats[key] = value;
            }
        }

        total = stats.MemTotal || 0.0;
        const free = stats.MemFree || 0.0;
        const buffers = stats.Buffers || 0.0;
        const cached = stats.Cached || 0.0;
        const available = stats.MemAvailable || (free + buffers + cached);
        used = Math.max(0, total - available);
    }
}
