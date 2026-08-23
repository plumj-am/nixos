import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../common/widgets"
import "../common" as Common

PanelWindow {
   id: root

   property bool isOpen: false
   property string searchText: ""
   property int selectedIndex: 0
   property var allEntries: []
   property var filteredEntries: []
   property var screen: null
   readonly property int clipboardWidth: 500
   readonly property int clipboardHeight: 440
   readonly property int itemHeight: 40

   function loadEntries() {
	  listProc.running = false
	  listProc.running = true
   }

   function parseEntries(raw) {
	  var lines = raw.split("\n")
	  var entries = []
	  for (var i = 0; i < lines.length && entries.length < 50; i++) {
		 var line = lines[i].trim()
		 if (line === "")
			continue
		 // clipcatctl list format: "<16-hex id>: <preview>"
		 var sep = line.indexOf(": ")
		 if (sep < 0)
			continue
		 var id = line.slice(0, sep)
		 var text = line.slice(sep + 2)
		 if (text.indexOf("[image/") === 0)
			continue
		 entries.push({
						 id: id,
						 text: text
					  })
	  }
	  allEntries = entries
	  filterEntries()
   }

   function filterEntries() {
	  if (!searchText || searchText.trim() === "") {
		 filteredEntries = allEntries.slice()
	  } else {
		 var query = searchText.toLowerCase()
		 var results = []
		 for (var i = 0; i < allEntries.length; i++) {
			if (allEntries[i].text.toLowerCase().indexOf(query) !== -1) {
			   results.push(allEntries[i])
			}
		 }
		 filteredEntries = results
	  }
	  selectedIndex = 0
   }

   function selectEntry() {
	  if (filteredEntries.length > 0 && filteredEntries[selectedIndex]) {
		 var id = filteredEntries[selectedIndex].id
		 copyProc.command = ["clipcatctl", "promote", id]
		 copyProc.running = true
		 // Close on copy; flash feedback briefly in case the panel is still visible.
		 copiedFlash.visible = true
		 copiedFlashTimer.restart()
		 isOpen = false
	  }
   }

   function deleteEntry(index) {
	  if (filteredEntries[index]) {
		 var id = filteredEntries[index].id
		 deleteProc.command = ["clipcatctl", "remove", id]
		 deleteProc.running = true
		 var newAll = []
		 for (var i = 0; i < allEntries.length; i++) {
			if (allEntries[i].id !== id)
			   newAll.push(allEntries[i])
		 }
		 allEntries = newAll
		 filterEntries()
	  }
   }

   function clearAll() {
	  wipeProc.running = true
	  allEntries = []
	  filteredEntries = []
	  isOpen = false
   }

   visible: isOpen || clipboardClip.implicitHeight > 0
   color: "transparent"
   WlrLayershell.namespace: "quickshell-clipboard"
   WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
   WlrLayershell.layer: WlrLayer.Overlay
   exclusionMode: ExclusionMode.Ignore

   onIsOpenChanged: {
	  if (isOpen) {
		 searchText = ""
		 selectedIndex = 0
		 loadEntries()
		 searchField.forceActiveFocus()
	  }
   }

   anchors {
	  top: true
	  bottom: true
	  left: true
	  right: true
   }

   Process {
	  id: listProc

	  command: ["clipcatctl", "list"]
	  running: false

	  stdout: StdioCollector {
		 onStreamFinished: root.parseEntries(this.text)
	  }
   }

   Process {
	  id: copyProc

	  running: false
   }

   Process {
	  id: deleteProc

	  running: false
   }

   Process {
	  id: wipeProc

	  command: ["clipcatctl", "clear"]
	  running: false
   }

   MouseArea {
	  anchors.fill: parent
	  acceptedButtons: Qt.AllButtons

	  onPressed: root.isOpen = false
   }

   Item {
	  id: clipboardClip

	  anchors.horizontalCenter: parent.horizontalCenter
	  anchors.bottom: parent.bottom
	  width: clipboardWidth
	  implicitHeight: root.isOpen ? clipboardHeight : 0
	  visible: implicitHeight > 0
	  clip: true

	  Behavior on implicitHeight {
		 Common.NAnim {}
	  }

	  Item {
		 id: clipboardBody

		 anchors.bottom: parent.bottom
		 width: clipboardWidth
		 height: clipboardHeight

		 Rectangle {
			anchors.fill: parent
			color: Common.Theme.background
			radius: 0
			topLeftRadius: Common.Theme.radius.big
			topRightRadius: Common.Theme.radius.big
			clip: true

			ColumnLayout {
			   id: contentColumn

			   anchors.fill: parent
			   anchors.topMargin: 12
			   anchors.bottomMargin: 12
			   anchors.leftMargin: 12
			   anchors.rightMargin: 12
			   spacing: 8

			   SearchField {
				  id: searchField

				  Layout.fillWidth: true
				  placeholderText: "Search clipboard..."

				  onSearchTriggered: function (query) {
					 root.searchText = query
					 root.filterEntries()
				  }
				  Keys.onEscapePressed: root.isOpen = false
				  Keys.onReturnPressed: root.selectEntry()
				  Keys.onEnterPressed: root.selectEntry()
				  Keys.onUpPressed: {
					 if (root.selectedIndex > 0)
						root.selectedIndex--
				  }
				  Keys.onDownPressed: {
					 if (root.selectedIndex < root.filteredEntries.length - 1)
						root.selectedIndex++
				  }
			   }

			   ListView {
				  id: entryList

				  Layout.fillWidth: true
				  Layout.fillHeight: true
				  model: root.filteredEntries
				  clip: true
				  currentIndex: root.selectedIndex

				  delegate: Rectangle {
					 property bool isHovered: delegateMouseArea.containsMouse

					 width: entryList.width
					 height: root.itemHeight
					 color: index === root.selectedIndex ? Common.Theme.background2 : "transparent"
					 radius: Common.Theme.radius.small

					 onIsHoveredChanged: {
						if (isHovered)
						   root.selectedIndex = index
					 }

					 RowLayout {
						anchors.fill: parent
						anchors.leftMargin: 6
						anchors.rightMargin: 6
						spacing: 8

						Text {
						   text: "\uf0c7"
						   font.family: Common.Theme.font.mono.family
						   font.pixelSize: 13
						   color: Common.Theme.textMuted
						   Layout.alignment: Qt.AlignVCenter
						}

						Text {
						   text: modelData.text
						   color: Common.Theme.text
						   font.family: Common.Theme.font.mono.family
						   font.pixelSize: 12
						   elide: Text.ElideRight
						   Layout.fillWidth: true
						   Layout.alignment: Qt.AlignVCenter
						}

						Text {
						   text: "\uf00d"
						   font.family: Common.Theme.font.mono.family
						   font.pixelSize: 12
						   color: deleteBtnMA.containsMouse ? Common.Theme.error : Common.Theme.textMuted
						   Layout.alignment: Qt.AlignVCenter
						   visible: delegateMouseArea.containsMouse

						   MouseArea {
							  id: deleteBtnMA

							  anchors.fill: parent
							  hoverEnabled: true
							  cursorShape: Qt.PointingHandCursor

							  onClicked: function (mouse) {
								 mouse.accepted = true
								 root.deleteEntry(index)
							  }
						   }
						}
					 }

					 MouseArea {
						id: delegateMouseArea

						anchors.fill: parent
						hoverEnabled: true
						cursorShape: Qt.PointingHandCursor

						onClicked: {
						   root.selectedIndex = index
						   root.selectEntry()
						}
					 }
				  }

				  onCurrentIndexChanged: {
					 if (currentIndex >= 0)
						positionViewAtIndex(currentIndex, ListView.Contain)
				  }
			   }

			   RowLayout {
				  Layout.fillWidth: true

				  Text {
					 text: root.filteredEntries.length + " entries"
					 color: Common.Theme.textMuted
					 font.family: Common.Theme.font.sans.family
					 font.pixelSize: 11
				  }

				  Item {
					 Layout.fillWidth: true
				  }

				  Text {
					 text: "Clear all"
					 color: clearAllMA.containsMouse ? Common.Theme.error : Common.Theme.textMuted
					 font.family: Common.Theme.font.sans.family
					 font.pixelSize: 11

					 MouseArea {
						id: clearAllMA

						anchors.fill: parent
						hoverEnabled: true
						cursorShape: Qt.PointingHandCursor

						onClicked: root.clearAll()
					 }
				  }
			   }
			}
		 }

		 // Copy feedback: flashes when an entry is promoted.
		 Rectangle {
			id: copiedFlash

			visible: false
			anchors.horizontalCenter: parent.horizontalCenter
			anchors.bottom: parent.bottom
			anchors.bottomMargin: 12
			z: 10
			implicitWidth: copiedFlashLabel.implicitWidth + 16
			implicitHeight: copiedFlashLabel.implicitHeight + 8
			color: Common.Theme.background2
			radius: Common.Theme.radius.small

			Text {
			   id: copiedFlashLabel

			   anchors.centerIn: parent
			   text: "Copied"
			   color: Common.Theme.text
			   font.family: Common.Theme.font.sans.family
			   font.pixelSize: 12
			}
		 }
	  }

	  Common.Border {
		 anchors.fill: parent
	  }
   }

   Timer {
	  id: copiedFlashTimer

	  interval: 900
	  repeat: false

	  onTriggered: copiedFlash.visible = false
   }
}
