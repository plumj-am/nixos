pragma Singleton
import QtQuick

QtObject {
    id: root

    readonly property var data: ({
        theme: {
            text: "#d5c4a1",
            textMuted: "#bdae93",
            foreground: "#ebdbb2",
            foreground2: "#a89984",
            background: "#1d2021",
            background2: "#282828",
            ok: "#b8bb26",
            error: "#fb4934",
            warning: "#fe8019",
            colors: {
                text: "#d5c4a1",
                textMuted: "#bdae93",
                foreground: "#ebdbb2",
                foreground2: "#a89984",
                background: "#1d2021",
                background2: "#282828",
                ok: "#b8bb26",
                error: "#fb4934",
                warning: "#fe8019"
            },
            font: {
                family: "Lexend",
                size: 15
            },
            fontMono: {
                family: "Hasklug Nerd Font Mono",
                size: 14
            },
            radius: { tiny: 1, small: 2, normal: 4, big: 8 },
            margin: { small: 4, normal: 8 }
        },
        bar: {
            size: 32,
            position: "top"
        },
        clock: {
            time: { format: "HH:mm", enabled: true },
            date: { format: "yyyy-MM-dd", enabled: true },
            font: { family: "Lexend", scale: 0.7 }
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
        }
    })
}
