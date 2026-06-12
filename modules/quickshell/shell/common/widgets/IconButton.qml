import QtQuick
import ".."

Item {
   id: root

   property string icon: ""

   signal clicked

   implicitWidth: 24
   implicitHeight: 24

   Text {
	  anchors.centerIn: parent
	  text: root.icon
	  font.family: Theme.font.icons.family
	  font.pixelSize: Theme.font.sans.size
	  color: mouseArea.containsMouse ? Theme.accent : Theme.foreground
   }

   MouseArea {
	  id: mouseArea

	  anchors.fill: parent
	  hoverEnabled: true
	  cursorShape: Qt.PointingHandCursor

	  onClicked: root.clicked()
   }
}
