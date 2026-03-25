pragma Singleton
import QtQuick

QtObject {
    property string activeInterface: ""
    property int networkType: 0

    property var data: ({
        network: {
            activeInterface: "",
            type: 0
        }
    })
}
