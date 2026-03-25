pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../common"

Item {
    id: root

    property bool available: UPower.displayDevice.isLaptopBattery
    property int chargeState: UPower.displayDevice.state
    property bool isCharging: chargeState === UPowerDeviceState.Charging
    property bool isPluggedIn: isCharging || chargeState === UPowerDeviceState.PendingCharge
    property real percentage: UPower.displayDevice.percentage ?? 1.0
    property bool isLow: available && percentage <= 0.2
    property bool isCritical: available && percentage <= 0.1
    property real energyRate: UPower.displayDevice.changeRate ?? 0
    property real timeToEmpty: UPower.displayDevice.timeToEmpty ?? 0
    property real timeToFull: UPower.displayDevice.timeToFull ?? 0
}
