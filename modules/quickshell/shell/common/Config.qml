pragma Singleton
import QtQuick

QtObject {
    id: root

    readonly property var data: ({
        bar: {
            size: 32,
            position: "top"
        },
        shell: {
            enableOuterBorder: false,
            outerBorderSize: 4
        },
        clock: {
            time: { format: "HH:mm", enabled: true },
            date: { format: "yyyy-MM-dd", enabled: true }
        },
        battery: {
            showPercentage: true,
            low: 20,
            critical: 10
        },
        cpu: {
            updateInterval: 2000
        },
        ram: {
            updateInterval: 2000
        },
        network: {
            updateInterval: 5000
        },
        disk: {
            updateInterval: 60000
        }
    })
}
