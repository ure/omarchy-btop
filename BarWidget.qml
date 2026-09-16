import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Bar icon and its popup: a switch for btop on the wallpaper, a slider for how
// much of the wallpaper shows through it, and a way to open btop as a window.
Panel {
  id: root
  moduleName: "ure.btop"
  ipcTarget: "ure.btop.panel"

  readonly property string scripts: Quickshell.env("HOME") + "/.config/omarchy/plugins/ure.btop/scripts"

  property real transparency: 0.75   //? 1 = nothing behind the text, 0 = solid backing
  property bool onWallpaper: false
  property string targetScreen: ""
  property bool targetIsWide: false

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  function applyTransparency(value) {
    root.transparency = value
    applyProc.command = ["omarchy-shell", "ure.btop", "setScrim", String(1 - value)]
    applyProc.running = true
  }

  onOpenedChanged: if (opened) refresh()

  //? The service knows the scrim and which screens show btop
  Process {
    id: statusProc
    command: ["omarchy-shell", "ure.btop", "status"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var status = JSON.parse(this.text)
          if (typeof status.scrim === "number") root.transparency = 1 - status.scrim
          var screens = status.screens || []
          var target = null
          for (var i = 0; i < screens.length; i++) {
            if (screens[i].wide) { target = screens[i]; break }
            if (!target && screens[i].focused) target = screens[i]
          }
          if (target) {
            root.targetScreen = target.name
            root.targetIsWide = target.wide === true
            root.onWallpaper = target.shown === true
          }
        } catch (error) {
          console.warn("ure.btop: could not read status:", error)
        }
      }
    }
  }

  Process { id: applyProc }

  Process {
    id: actionProc
    onExited: Qt.callLater(root.refresh)
  }

  function run(command) {
    actionProc.command = ["sh", "-c", command]
    actionProc.running = true
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰍛"
    active: root.onWallpaper
    tooltipText: "btop"
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.RightButton) root.run(root.scripts + "/btop-screen")
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(320))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(12)

        PanelSectionHeader {
          width: parent.width
          foreground: root.barForeground
          text: "On the wallpaper"
        }

        Item {
          width: parent.width
          implicitHeight: Math.max(wallpaperLabel.implicitHeight, wallpaperSwitch.implicitHeight)

          Text {
            id: wallpaperLabel
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            textFormat: Text.PlainText
            text: root.targetScreen === "" ? "No screen" : root.targetScreen
            color: root.barForeground
            font.family: Style.font.family
            font.pixelSize: Style.font.body
          }

          ToggleSwitch {
            id: wallpaperSwitch
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            foreground: root.barForeground
            checked: root.onWallpaper
            onToggled: root.run(root.scripts + "/btop-background toggle")
          }
        }

        PanelSectionHeader {
          width: parent.width
          foreground: root.barForeground
          text: "Transparency · " + Math.round(root.transparency * 100) + "%"
        }

        PanelSlider {
          id: transparencySlider
          width: parent.width
          bar: root.bar
          minimum: 0
          maximum: 1
          step: 0.05
          value: root.transparency
          onMoved: function(value) { root.transparency = value }
          onReleased: function(value) { root.applyTransparency(value) }
        }

        PanelSeparator {
          width: parent.width
          foreground: root.barForeground
        }

        Button {
          width: parent.width
          foreground: root.barForeground
          bordered: true
          iconText: "󰖲"
          text: "Open as a window"
          onClicked: {
            root.run(root.scripts + "/btop-screen")
            root.close()
          }
        }
      }
    }
  }
}
