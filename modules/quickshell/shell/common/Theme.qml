pragma Singleton
import QtQuick

QtObject {
    id: theme

    readonly property var colors: ({
        base00: "#1d2021",
        base01: "#3c3836",
        base02: "#504945",
        base03: "#665c54",
        base04: "#bdae93",
        base05: "#d5c4a1",
        base06: "#ebdbb2",
        base07: "#fbf1c7",
        base08: "#fb4934",
        base09: "#fe8019",
        base0A: "#fabd2f",
        base0B: "#b8bb26",
        base0C: "#8ec07c",
        base0D: "#83a598",
        base0E: "#d3869b",
        base0F: "#d65d0e"
    })

    readonly property var font: ({
        sans: { name: "Lexend", size: 12 },
        mono: { name: "Hasklug Nerd Font Mono", size: 12 }
    })

    readonly property var radius: ({ tiny: 1, small: 2, normal: 4, big: 8 })
    readonly property var border: ({ small: 2, normal: 4 })
    readonly property var margin: ({ small: 4, normal: 8 })
    readonly property var padding: ({ small: 4, normal: 8 })

    readonly property color background: colors.base00
    readonly property color background2: colors.base01
    readonly property color surface: colors.base01
    readonly property color surfaceContainer: colors.base02
    readonly property color text: colors.base07
    readonly property color textMuted: colors.base04
    readonly property color foreground: colors.base06
    readonly property color foreground2: colors.base04
    readonly property color primary: colors.base0A
    readonly property color accent: colors.base0D
    readonly property color success: colors.base0B
    readonly property color warning: colors.base09
    readonly property color error: colors.base08
    readonly property color outline: colors.base03

    function alpha(c, opacity) {
        const color = Qt.color(c)
        return Qt.rgba(color.r, color.g, color.b, opacity)
    }
}
