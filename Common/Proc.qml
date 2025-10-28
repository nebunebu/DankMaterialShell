pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int defaultDebounceMs: 50
    property int defaultTimeoutMs: 10000
    property var _procDebouncers: ({}) // id -> { timer, command, callback, waitMs }

    function runCommand(id, command, callback, debounceMs, timeoutMs) {
        const wait = (typeof debounceMs === "number" && debounceMs >= 0) ? debounceMs : defaultDebounceMs
        const timeout = (typeof timeoutMs === "number" && timeoutMs > 0) ? timeoutMs : defaultTimeoutMs
        let procId = id ? id : Math.random()

        if (!_procDebouncers[procId]) {
            const t = Qt.createQmlObject('import QtQuick; Timer { repeat: false }', root)
            t.triggered.connect(function() { _launchProc(procId) })
            _procDebouncers[procId] = { timer: t, command: command, callback: callback, waitMs: wait, timeoutMs: timeout }
        } else {
            _procDebouncers[procId].command = command
            _procDebouncers[procId].callback = callback
            _procDebouncers[procId].waitMs = wait
            _procDebouncers[procId].timeoutMs = timeout
        }

        const entry = _procDebouncers[procId]
        entry.timer.interval = entry.waitMs
        entry.timer.restart()
    }

    function _launchProc(id) {
        const entry = _procDebouncers[id]
        if (!entry) return

        const proc = Qt.createQmlObject('import Quickshell.Io; Process { running: false }', root)
        const out = Qt.createQmlObject('import Quickshell.Io; StdioCollector {}', proc)
        const err = Qt.createQmlObject('import Quickshell.Io; StdioCollector {}', proc)
        const timeoutTimer = Qt.createQmlObject('import QtQuick; Timer { repeat: false }', root)

        proc.stdout = out
        proc.stderr = err
        proc.command = entry.command

        let capturedOut = ""
        let capturedErr = ""
        let exitSeen = false
        let exitCodeValue = -1
        let outSeen = false
        let errSeen = false
        let timedOut = false

        timeoutTimer.interval = entry.timeoutMs
        timeoutTimer.triggered.connect(function() {
            if (!exitSeen) {
                timedOut = true
                proc.running = false
                exitSeen = true
                exitCodeValue = 124
                maybeComplete()
            }
        })

        out.streamFinished.connect(function() {
            capturedOut = out.text || ""
            outSeen = true
            maybeComplete()
        })

        err.streamFinished.connect(function() {
            capturedErr = err.text || ""
            errSeen = true
            maybeComplete()
        })

        proc.exited.connect(function(code) {
            timeoutTimer.stop()
            exitSeen = true
            exitCodeValue = code
            maybeComplete()
        })

        function maybeComplete() {
            if (!exitSeen || !outSeen || !errSeen) return
            timeoutTimer.stop()
            if (typeof entry.callback === "function") {
                try { entry.callback(capturedOut, exitCodeValue) } catch (e) { console.warn("runCommand callback error:", e) }
            }
            try { proc.destroy() } catch (_) {}
            try { timeoutTimer.destroy() } catch (_) {}
        }

        proc.running = true
        timeoutTimer.start()
    }
}
