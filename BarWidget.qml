import QtQuick
import Quickshell
import qs.Ui

// Bar icon: left click puts btop on the wallpaper of the monitor under the
// cursor, right click opens it as a window you can actually use.
BarWidget {
  id: root
  moduleName: "ure.btop"

  readonly property string scripts: Quickshell.env("HOME") + "/.config/omarchy/plugins/ure.btop/scripts"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰍛"
    tooltipText: "btop · click for the wallpaper, right click for a window"

    onPressed: function(mouseButton) {
      if (mouseButton === Qt.RightButton) root.bar.run(root.scripts + "/btop-screen")
      else root.bar.run(root.scripts + "/btop-background toggle")
    }
  }
}
