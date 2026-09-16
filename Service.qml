import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// btop drawn on the background layer: above the wallpaper, below every window,
// taking no input at all. One surface per monitor, the same shape Motion
// Wallpaper uses for video. A headless btop feeds each surface its frames.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property string pluginDir: Quickshell.env("HOME") + "/.config/omarchy/plugins/ure.btop"
  readonly property string frameScript: pluginDir + "/scripts/btop-frame"

  property int refreshMs: 1000
  property string fontFamily: "JetBrainsMono Nerd Font"
  property int maxFontPixelSize: 16
  //? A touch of dark behind the text, so btop stays readable over a bright
  //? wallpaper while the wallpaper still shows through
  property real scrim: 0.25

  //? Monitor name -> what a bar reserves at its top, in logical pixels
  property var reservedTop: ({})
  //? Monitor name -> shown by hand, which beats the automatic pick either way
  property var overrides: ({})

  function ping() { return "ok" }

  //? A screen worth filling: wide and short, like the Xeneon Edge
  function isWide(screen) {
    if (!screen || !screen.height) return false
    return screen.width >= screen.height * 2.2 || screen.height < 600
  }

  function shows(screen) {
    if (!screen) return false
    var override = overrides[screen.name]
    if (override !== undefined) return override
    return isWide(screen)
  }

  function setShown(name, shown) {
    var next = Object.assign({}, overrides)
    next[name] = shown
    overrides = next
  }

  function toggle(name) {
    var screen = null
    for (var i = 0; i < Quickshell.screens.length; i++) {
      if (Quickshell.screens[i].name === name) screen = Quickshell.screens[i]
    }
    setShown(name, !(screen ? shows(screen) : false))
  }

  //? One glyph measured big, so a cell's size at any font size is just a
  //? multiplication. Used to pick the largest font that still fits btop's grid.
  FontMetrics {
    id: reference
    font.family: root.fontFamily
    font.pixelSize: 100
  }

  //? TextMetrics exposes the advance as a property, so the binding updates once
  //? the font is loaded; FontMetrics.advanceWidth() is a call and would not.
  TextMetrics {
    id: referenceCell
    font.family: root.fontFamily
    font.pixelSize: 100
    text: "W"
  }

  readonly property real cellWidthUnit: referenceCell.advanceWidth > 0 ? referenceCell.advanceWidth / 100 : 0.6
  readonly property real cellHeightUnit: reference.height > 0 ? reference.height / 100 : 1.3

  //? Hyprland reports what each bar reserves, which is how a surface knows to
  //? start below one and to use the whole screen where there is none.
  Process {
    id: reservedProc
    command: ["hyprctl", "monitors", "-j"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var monitors = JSON.parse(this.text)
          var map = {}
          for (var i = 0; i < monitors.length; i++) {
            var monitor = monitors[i]
            var reserved = monitor.reserved || [0, 0, 0, 0]
            map[monitor.name] = reserved[1] || 0
          }
          root.reservedTop = map
        } catch (error) {
          console.warn("ure.btop: could not read monitor reserved areas:", error)
        }
      }
    }
  }

  Component.onCompleted: reservedProc.running = true

  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: if (!reservedProc.running) reservedProc.running = true
  }

  IpcHandler {
    target: "ure.btop"

    function toggleBackground(screen: string): string {
      root.toggle(screen)
      return "ok"
    }

    function showBackground(screen: string): string {
      root.setShown(screen, true)
      return "ok"
    }

    function hideBackground(screen: string): string {
      root.setShown(screen, false)
      return "ok"
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: surface

      required property var modelData

      readonly property int barInset: root.reservedTop[modelData.name] || 0
      readonly property string sessionName: "ure-btop-" + modelData.name.replace(/[^A-Za-z0-9_-]/g, "-")
      readonly property string layout: root.isWide(modelData) ? "wide" : "standard"

      //? The grid btop needs at its smallest: the wide layout puts four boxes
      //? side by side, the stacked one wants room for the process list.
      readonly property int minColumns: layout === "wide" ? 176 : 80
      readonly property int minRows: layout === "wide" ? 17 : 24

      //? Largest font that still gives btop that grid on this surface
      readonly property int fontPixelSize: Math.max(6, Math.min(root.maxFontPixelSize,
        Math.floor(Math.min(width / (minColumns * root.cellWidthUnit),
                            height / (minRows * root.cellHeightUnit)))))

      readonly property int columns: Math.floor(width / Math.max(1, cell.advanceWidth))
      readonly property int rows: Math.floor(height / Math.max(1, metrics.height))

      property string frame: ""

      screen: modelData
      visible: root.shows(modelData)
      color: Qt.rgba(0, 0, 0, root.scrim)

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }
      margins.top: barInset

      WlrLayershell.namespace: "ure-btop-background"
      WlrLayershell.layer: WlrLayer.Background
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore

      FontMetrics {
        id: metrics
        font.family: root.fontFamily
        font.pixelSize: surface.fontPixelSize
      }

      TextMetrics {
        id: cell
        font.family: root.fontFamily
        font.pixelSize: surface.fontPixelSize
        text: "W"
      }

      Process {
        id: frameProc
        command: [root.frameScript,
          "--session", surface.sessionName,
          "--cols", String(surface.columns),
          "--rows", String(surface.rows),
          "--layout", surface.layout]
        stdout: StdioCollector {
          onStreamFinished: if (this.text.length > 0) surface.frame = this.text
        }
      }

      Process {
        id: stopProc
        command: [root.frameScript, "--session", surface.sessionName, "--stop"]
      }

      Timer {
        interval: root.refreshMs
        running: surface.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!frameProc.running) frameProc.running = true
      }

      //? Nothing to draw for a hidden screen, and no btop to keep running either
      onVisibleChanged: if (!visible && !stopProc.running) stopProc.running = true

      Text {
        anchors.fill: parent
        textFormat: Text.RichText
        text: surface.frame
        color: "#a9b1d6"
        font.family: root.fontFamily
        font.pixelSize: surface.fontPixelSize
        lineHeight: metrics.height
        lineHeightMode: Text.FixedHeight
        renderType: Text.NativeRendering
      }
    }
  }
}
