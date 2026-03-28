pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: theme

    property string mode: "dark"
    property string scheme: "gruvbox"

    readonly property var schemes: ({
            gruvbox: {
                dark: {
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
                },
                light: {
                    base00: "#faf9f7",
                    base01: "#ebdbb2",
                    base02: "#d5c4a1",
                    base03: "#bdae93",
                    base04: "#665c54",
                    base05: "#504945",
                    base06: "#3c3836",
                    base07: "#1d2021",
                    base08: "#9d0006",
                    base09: "#af3a03",
                    base0A: "#b57614",
                    base0B: "#79740e",
                    base0C: "#427b58",
                    base0D: "#076678",
                    base0E: "#8f3f71",
                    base0F: "#d65d0e"
                }
            }
        })

    readonly property var colors: schemes[scheme] ? (schemes[scheme][mode] || schemes.gruvbox.dark) : schemes.gruvbox.dark

    readonly property var font: ({
            sans: {
                family: "Lexend",
                size: 15
            },
            mono: {
                family: "Hasklug Nerd Font Mono",
                size: 13
            }
        })

    readonly property var radius: ({
            tiny: 1,
            small: 2,
            normal: 4,
            big: 8
        })
    readonly property var border: ({
            small: 2,
            normal: 4
        })
    readonly property var margin: ({
            small: 4,
            normal: 8
        })
    readonly property var padding: ({
            small: 4,
            normal: 8
        })

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

    property var themeFile: FileView {
        path: "/home/jam/nixos/modules/theme.json"
        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (data.mode)
                    theme.mode = data.mode;
                if (data.scheme)
                    theme.scheme = data.scheme;
            } catch (e) {
                console.log("Failed to parse theme.json:", e);
            }
        }
    }
}
