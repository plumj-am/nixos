pragma Singleton
import QtQuick

QtObject {
    readonly property var unitsBinary: ["KiB", "MiB", "GiB", "TiB", "PiB"]
    readonly property var unitsMetric: ["KB", "MB", "GB", "TB", "PB"]

    function getUnitHierarchy(baseUnit) {
        const u = (baseUnit || "KB").toUpperCase()
        if (unitsBinary.includes(u)) return unitsBinary
        return unitsMetric
    }

    function convertSizeUnit(value, fromUnit, toUnit) {
        fromUnit = (fromUnit || "KB").toUpperCase()
        toUnit = (toUnit || "KB").toUpperCase()

        const isBinary = unitsBinary.includes(fromUnit)
        const base = isBinary ? 1024 : 1000
        const unitList = isBinary ? unitsBinary : unitsMetric

        const fromIndex = unitList.indexOf(fromUnit)
        const toIndex = unitList.indexOf(toUnit)

        if (fromIndex === -1 || toIndex === -1) return value

        const diff = fromIndex - toIndex
        if (diff > 0) {
            return value * Math.pow(base, diff)
        } else if (diff < 0) {
            return value / Math.pow(base, -diff)
        }
        return value
    }
}
