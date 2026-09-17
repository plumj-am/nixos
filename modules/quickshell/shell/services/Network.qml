pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../common"

Item {
   id: root

   property string activeInterface: ""
   property int networkType: Types.networkWired
   property real rateUp: 0.0
   property real rateDown: 0.0
   property var lanIPs: []
   property var prevRx: 0
   property var prevTx: 0

   function defaultRouteInterface(routes) {
	  const lines = routes.split("\n").slice(1)
	  for (const line of lines) {
		 const fields = line.trim().split(/\s+/)
		 if (fields.length > 3 && fields[1] === "00000000")
			return fields[0]
	  }
	  return ""
   }

   function interfaceType(name) {
	  if (!name)
		 return Types.networkWired
	  ueventView.reload()
	  return ueventView.text().includes("DEVTYPE=wlan") ? Types.networkWireless : Types.networkWired
   }

   function updateInterface() {
	  routesView.reload()
	  const name = defaultRouteInterface(routesView.text())
	  if (name === activeInterface)
		 return
	  activeInterface = name
	  networkType = interfaceType(name)
	  prevRx = 0
	  prevTx = 0
	  rateUp = 0
	  rateDown = 0
	  lanIPs = []
	  lanIPProc.running = name !== ""
   }

   function updateRates() {
	  if (!activeInterface)
		 return
	  rxBytesView.reload()
	  txBytesView.reload()
	  const rx = parseInt(rxBytesView.text().trim()) || 0
	  const tx = parseInt(txBytesView.text().trim()) || 0
	  const elapsed = rateTimer.interval / 1000
	  if (prevRx > 0)
		 rateDown = Math.max(0, rx - prevRx) / elapsed
	  if (prevTx > 0)
		 rateUp = Math.max(0, tx - prevTx) / elapsed
	  prevRx = rx
	  prevTx = tx
   }

   FileView {
	  id: routesView

	  path: "/proc/net/route"
	  blockAllReads: true

	  onLoadFailed: err => console.log("Network: route table load failed:", err)
   }

   FileView {
	  id: ueventView

	  path: root.activeInterface ? `/sys/class/net/${root.activeInterface}/uevent` : ""
	  blockAllReads: true

	  onLoadFailed: err => console.log("Network: uevent load failed:", err)
   }

   FileView {
	  id: rxBytesView

	  path: root.activeInterface ? `/sys/class/net/${root.activeInterface}/statistics/rx_bytes` : ""
	  blockAllReads: true

	  onLoadFailed: err => console.log("Network: rx_bytes load failed:", err)
   }

   FileView {
	  id: txBytesView

	  path: root.activeInterface ? `/sys/class/net/${root.activeInterface}/statistics/tx_bytes` : ""
	  blockAllReads: true

	  onLoadFailed: err => console.log("Network: tx_bytes load failed:", err)
   }

   Process {
	  id: lanIPProc

	  running: false
	  command: ["ip", "-json", "addr", "show", root.activeInterface]

	  stdout: StdioCollector {
		 onStreamFinished: {
			try {
			   const data = JSON.parse(text)
			   if (data && data.length > 0) {
				  lanIPs = (data[0].addr_info || []).map(i => i.local).filter(Boolean)
			   }
			} catch (e) {
			   lanIPs = []
			}
		 }
	  }
   }

   // Detection is a poll so a route change (cable, wifi switch) is picked up without events.
   Timer {
	  interval: 30000
	  running: true
	  repeat: true
	  triggeredOnStart: true

	  onTriggered: updateInterface()
   }

   Timer {
	  id: rateTimer

	  interval: Config.data.network?.updateInterval ?? 5000
	  running: true
	  repeat: true
	  triggeredOnStart: true

	  onTriggered: updateRates()
   }
}
