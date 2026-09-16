import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Bar icon and its popup: a switch per monitor for btop on the wallpaper, a
// switch for the top bar itself, a slider for how much wallpaper shows through,
// and a button that opens btop as an ordinary window.
Panel {
  id: root
  moduleName: "ure.btop"
  ipcTarget: "ure.btop.panel"

  readonly property string scripts: Quickshell.env("HOME") + "/.config/omarchy/plugins/ure.btop/scripts"

  property real transparency: 0.75   //? 1 = nothing behind the text, 0 = solid backing
  property var screens: []
  property bool anyOnWallpaper: false
  property var barHiddenScreens: []
  property string barSupport: "unknown"   //? supported | unsupported | missing
  //? Width of one switch, so the legend lines up with the switches below it
  property real switchWidth: metricsSwitch.implicitWidth

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function refresh() {
    if (!statusProc.running) statusProc.running = true
    if (!barStateProc.running) barStateProc.running = true
    if (!barSupportProc.running) barSupportProc.running = true
  }

  function barShownOn(name) {
    return barHiddenScreens.indexOf(name) === -1
  }

  //? PanelSlider leaves snapping to the caller, so round to the step here
  function snap(value) {
    return Math.max(0, Math.min(1, Math.round(value / 0.05) * 0.05))
  }

  function applyTransparency(value) {
    root.transparency = snap(value)
    applyProc.command = ["omarchy-shell", "ure.btop", "setScrim", String(1 - root.transparency)]
    applyProc.running = true
  }

  function run(command) {
    actionProc.command = ["sh", "-c", command]
    actionProc.running = true
  }

  onOpenedChanged: if (opened) refresh()

  //? The service knows the scrim and which screens are showing btop
  Process {
    id: statusProc
    command: ["omarchy-shell", "ure.btop", "status"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var status = JSON.parse(this.text)
          if (typeof status.scrim === "number") root.transparency = 1 - status.scrim
          root.screens = status.screens || []
          var any = false
          for (var i = 0; i < root.screens.length; i++) {
            if (root.screens[i].shown) any = true
          }
          root.anyOnWallpaper = any
        } catch (error) {
          console.warn("ure.btop: could not read status:", error)
        }
      }
    }
  }

  //? Screens the bar skips, as the bar itself reads them
  Process {
    id: barStateProc
    command: ["sh", "-c", "jq -c '.bar.hiddenScreens // []' \"$HOME/.config/omarchy/shell.json\""]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          root.barHiddenScreens = JSON.parse(this.text)
        } catch (error) {
          root.barHiddenScreens = []
        }
      }
    }
  }

  //? Only a bar that reads bar.hiddenScreens can be hidden per screen
  Process {
    id: barSupportProc
    command: [Quickshell.env("HOME") + "/.config/omarchy/plugins/ure.btop/scripts/bar-support", "status"]
    stdout: StdioCollector {
      onStreamFinished: root.barSupport = this.text.trim()
    }
  }

  //? Never shown, only measured
  ToggleSwitch { id: metricsSwitch; visible: false }

  Process { id: applyProc }

  Process {
    id: actionProc
    onExited: refreshTimer.restart()
  }

  //? Give the shell a moment to move the bar or a surface before reading back
  Timer {
    id: refreshTimer
    interval: 400
    onTriggered: root.refresh()
  }

  Timer {
    interval: 2000
    running: root.opened
    repeat: true
    onTriggered: root.refresh()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰍛"
    active: root.anyOnWallpaper
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
    contentWidth: panel.fittedContentWidth(Style.space(340))
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
        spacing: Style.space(10)

        PanelSectionHeader {
          width: parent.width
          foreground: root.barForeground
          text: "Screens"
        }

        Item {
          width: parent.width
          implicitHeight: legend.implicitHeight

          Row {
            id: legend
            anchors.right: parent.right
            spacing: Style.space(10)

            Text {
              width: root.switchWidth
              horizontalAlignment: Text.AlignHCenter
              textFormat: Text.PlainText
              text: "btop"
              color: Qt.darker(root.barForeground, 1.4)
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }

            Text {
              width: root.switchWidth
              horizontalAlignment: Text.AlignHCenter
              textFormat: Text.PlainText
              text: "bar"
              visible: root.barSupport === "supported"
              color: Qt.darker(root.barForeground, 1.4)
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }
          }
        }

        Repeater {
          model: root.screens

          Item {
            required property var modelData

            width: column.width
            implicitHeight: Math.max(screenLabel.implicitHeight, screenSwitch.implicitHeight)

            Text {
              id: screenLabel
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              textFormat: Text.PlainText
              text: modelData.name + (modelData.wide ? " · wide" : "")
              color: root.barForeground
              font.family: Style.font.family
              font.pixelSize: Style.font.body
            }

            Row {
              id: screenSwitch
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(10)

              ToggleSwitch {
                foreground: root.barForeground
                checked: modelData.shown === true
                onToggled: root.run(root.scripts + "/btop-background toggle " + modelData.name)
              }

              ToggleSwitch {
                foreground: root.barForeground
                visible: root.barSupport === "supported"
                checked: root.barShownOn(modelData.name)
                onToggled: root.run(root.scripts + "/bar-screen toggle " + modelData.name)
              }
            }
          }
        }

        Button {
          width: parent.width
          visible: root.barSupport === "unsupported"
          foreground: root.barForeground
          bordered: true
          iconText: "󰍜"
          text: "Enable per-screen bars"
          tooltipText: "Clones Omarchy's bar and teaches it to skip chosen screens"
          onClicked: root.run(root.scripts + "/bar-support install && omarchy restart shell")
        }

        PanelSeparator {
          width: parent.width
          foreground: root.barForeground
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
          onMoved: function(value) { root.transparency = root.snap(value) }
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
