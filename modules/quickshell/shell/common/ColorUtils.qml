pragma Singleton
import QtQuick

QtObject {
    function mix(color1, color2, ratio) {
        if (ratio === undefined) ratio = 0.5
        ratio = Math.max(0, Math.min(1, ratio))

        const c1 = Qt.color(color1)
        const c2 = Qt.color(color2)

        return Qt.rgba(
            c1.r * (1 - ratio) + c2.r * ratio,
            c1.g * (1 - ratio) + c2.g * ratio,
            c1.b * (1 - ratio) + c2.b * ratio,
            c1.a * (1 - ratio) + c2.a * ratio
        )
    }

    function withAlpha(c, alpha) {
        const color = Qt.color(c)
        return Qt.rgba(color.r, color.g, color.b, alpha)
    }
}
