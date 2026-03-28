pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../common"

Item {
    id: root

    property bool available: UPower.displayDevice.isLaptopBattery
    property bool isCharging: UPower.displayDevice.state === UPowerDeviceState.Charging
    property bool isPluggedIn: isCharging || UPower.displayDevice.state === UPowerDeviceState.PendingCharge
    property real percentage: UPower.displayDevice.percentage ?? 1.0
    property bool isLow: available && percentage <= ((Config.data.battery?.low ?? 20) / 100)
    property bool isCritical: available && percentage <= ((Config.data.battery?.critical ?? 10) / 100)
    property real energyRate: UPower.displayDevice.changeRate ?? 0
}
