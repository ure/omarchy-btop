import QtQuick
import Quickshell
import qs.Ui

// A bar icon that opens btop filling the display it is clicked from.
BarWidget {
  id: root
  moduleName: "ure.btop"

  readonly property string launcher: Quickshell.env("HOME") + "/.config/omarchy/plugins/ure.btop/scripts/btop-screen"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰍛"
    tooltipText: "btop · system monitor filling this display"

    onPressed: function(mouseButton) {
      //? Right click forces btop's normal stacked layout, whatever the screen shape
      if (mouseButton === Qt.RightButton) root.bar.run(root.launcher + " --layout standard")
      else root.bar.run(root.launcher)
    }
  }
}
