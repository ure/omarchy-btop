import QtQuick
import Quickshell
import Quickshell.Io

// Summoning this plugin opens btop on the focused monitor:
//   omarchy-shell shell summon ure.btop '{}'
Item {
  id: root

  property var shell: null
  property var manifest: null
  readonly property string launcher: Quickshell.env("HOME") + "/.config/omarchy/plugins/ure.btop/scripts/btop-screen"

  function open(payloadJson) {
    if (!launchProcess.running) {
      launchProcess.command = [launcher]
      launchProcess.running = true
    }
  }

  function close() {}
  function ping() { return "ok" }

  Process {
    id: launchProcess
  }
}
