// Add to your shell.json:
// {
//   "id": "kanata",
//   "type": "qml",
//   "source": "/path/to/quickshell-kanata-vim-status.qml",
//   "port": "10000"
// }

import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

Item {
  id: root

  property var bar
  property string moduleName: "kanata"
  property var settings: ({})

  property string labelText: ""
  property string tooltipText: ""
  property string layerClass: "insert"
  property string watcherCommand: ""

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function applyPayload(raw) {
    var payload
    try {
      payload = JSON.parse(String(raw || "{}"))
    } catch (e) {
      labelText = ""
      tooltipText = ""
      layerClass = "insert"
      return
    }

    labelText = String(payload.text || "")
    tooltipText = String(payload.tooltip || "")
    layerClass = String(payload.class || "insert")
  }

  function restartWatcher() {
    var port = String(setting("port", "10000")).trim()
    var command = String(setting("exec", "")).trim()
    if (!command) command = "bash $HOME/path/to/quickshell-kanata-vim-status.sh " + port

    if (watcherCommand === command && statusProc.running) return

    watcherCommand = command
    if (statusProc.running) statusProc.running = false
    if (watcherCommand !== "") statusProc.running = true
  }

  readonly property color normalBackground: "#80A6FA"
  readonly property color visualBackground: "#BC96FA"
  readonly property color visualLineBackground: "#C099FF"
  readonly property color modeBackground: layerClass === "normal" ? normalBackground : (layerClass === "visual" ? visualBackground : (layerClass === "visual-line" ? visualLineBackground : "transparent"))

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Rectangle {
    anchors.centerIn: button
    width: Math.max(Style.space(20), button.labelWidth + Style.spaceReal(16))
    height: Math.max(Style.space(16), button.implicitHeight - Style.spaceReal(8))
    radius: Math.max(2, Style.cornerRadius)
    color: root.modeBackground
    visible: root.labelText !== ""
    z: 0
  }

  Process {
    id: statusProc
    command: ["bash", "-lc", root.watcherCommand]
    running: false
    stdout: SplitParser {
      onRead: function(data) { root.applyPayload(data) }
    }
  }

  onSettingsChanged: restartWatcher()
  Component.onCompleted: Qt.callLater(restartWatcher)

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.labelText
    tooltipText: root.tooltipText
    foreground: "#222222"
    useActiveColor: false
    horizontalMargin: Number(root.setting("horizontalMargin", 7.5))
    fontSize: Number(root.setting("fontSize", 12))
    keepSpace: root.setting("keepSpace", false) === true
    z: 1
  }
}
