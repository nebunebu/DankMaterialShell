pragma Singleton

pragma ComponentBehavior

import QtCore
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

Singleton {
    id: root

    property bool dsearchAvailable: false
    property bool isConnected: false
    property bool isConnecting: false
    property int apiVersion: 0
    readonly property int expectedApiVersion: 1
    property bool handshakeReceived: false

    property var pendingRequests: ({})
    property int requestIdCounter: 0

    signal connectionStateChanged
    signal searchResultsReceived(var results)
    signal statsReceived(var stats)
    signal errorOccurred(string error)
    signal apiVersionReceived(int version)

    Component.onCompleted: {
        discoverAndConnect()
    }

    function discoverAndConnect() {
        if (requestSocket.connected) {
            requestSocket.connected = false
            Qt.callLater(() => {
                             performDiscovery()
                         })
            return
        }

        performDiscovery()
    }

    function performDiscovery() {
        dsearchAvailable = false
        isConnecting = false
        isConnected = false

        requestSocket.connected = false
        requestSocket.path = ""

        const xdgRuntimeDir = Quickshell.env("XDG_RUNTIME_DIR")
        if (xdgRuntimeDir && xdgRuntimeDir.length > 0) {
            findSocketProcess.searchPath = xdgRuntimeDir
            findSocketProcess.running = true
        } else {
            findSocketProcess.searchPath = "/tmp"
            findSocketProcess.running = true
        }
    }

    Process {
        id: findSocketProcess
        property string searchPath: ""

        command: ["find", searchPath, "-maxdepth", "1", "-type", "s", "-name", "danksearch-*.sock"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split('\n').filter(line => line.length > 0)

                if (lines.length > 0) {
                    const socketPath = lines[0]
                    testSocketProcess.socketPath = socketPath
                    testSocketProcess.running = true
                } else {
                    if (findSocketProcess.searchPath !== "/tmp") {
                        findSocketProcess.searchPath = "/tmp"
                        findSocketProcess.running = true
                    } else {
                        root.dsearchAvailable = false
                    }
                }
            }
        }

        onExited: exitCode => {
            if (exitCode !== 0) {
                root.dsearchAvailable = false
            }
        }
    }

    Process {
        id: testSocketProcess
        property string socketPath: ""

        command: ["test", "-S", socketPath]
        running: false

        onExited: exitCode => {
            if (exitCode === 0) {
                root.dsearchAvailable = true
                requestSocket.path = socketPath
                connectSocket()
            } else {
                root.dsearchAvailable = false
            }
        }
    }

    function connectSocket() {
        if (!dsearchAvailable || isConnected || isConnecting) {
            return
        }

        if (!requestSocket.path || requestSocket.path.length === 0) {
            return
        }

        isConnecting = true
        handshakeReceived = false
        requestSocket.connected = true
    }

    DankSocket {
        id: requestSocket
        path: ""
        connected: false

        onConnectionStateChanged: {
            if (!connected) {
                root.isConnected = false
                root.isConnecting = false
                root.apiVersion = 0
                root.handshakeReceived = false
                root.dsearchAvailable = false
                root.pendingRequests = {}

                requestSocket.connected = false
                requestSocket.path = ""

                root.connectionStateChanged()
            }
        }

        parser: SplitParser {
            onRead: line => {
                if (!line || line.length === 0) {
                    return
                }

                try {
                    const message = JSON.parse(line)

                    if (!root.handshakeReceived && message.apiVersion !== undefined) {
                        handleHandshake(message)
                    } else {
                        handleResponse(message)
                    }
                } catch (e) {
                    console.warn("DSearchService: Failed to parse message:", e)
                }
            }
        }
    }

    function handleHandshake(message) {
        handshakeReceived = true
        apiVersion = message.apiVersion || 0

        isConnected = true
        isConnecting = false
        connectionStateChanged()
        apiVersionReceived(apiVersion)
    }

    function sendRequest(method, params, callback) {
        if (!isConnected) {
            if (callback) {
                callback({
                             "error": "not connected to dsearch socket"
                         })
            }
            return
        }

        requestIdCounter++
        const id = Date.now() + requestIdCounter

        const request = {
            "id": id,
            "method": method
        }

        if (params && Object.keys(params).length > 0) {
            request.params = params
        }

        if (callback) {
            pendingRequests[id] = callback
        }

        requestSocket.send(request)
    }

    function handleResponse(response) {
        const callback = pendingRequests[response.id]

        if (callback) {
            delete pendingRequests[response.id]

            if (response.error) {
                errorOccurred(response.error)
            }

            callback(response)
        }
    }

    function ping(callback) {
        sendRequest("ping", null, callback)
    }

    function search(query, params, callback) {
        if (!query || query.length === 0) {
            if (callback) {
                callback({
                             "error": "query is required"
                         })
            }
            return
        }

        if (!isConnected) {
            discoverAndConnect()
            if (callback) {
                callback({
                             "error": "not connected - attempting reconnection"
                         })
            }
            return
        }

        const searchParams = {
            "query": query
        }

        if (params) {
            for (const key in params) {
                searchParams[key] = params[key]
            }
        }

        sendRequest("search", searchParams, response => {
                        if (response.result) {
                            searchResultsReceived(response.result)
                        }
                        if (callback) {
                            callback(response)
                        }
                    })
    }

    function getStats(callback) {
        sendRequest("stats", null, response => {
                        if (response.result) {
                            statsReceived(response.result)
                        }
                        if (callback) {
                            callback(response)
                        }
                    })
    }

    function sync(callback) {
        sendRequest("sync", null, callback)
    }

    function reindex(callback) {
        sendRequest("reindex", null, callback)
    }

    function watchStart(callback) {
        sendRequest("watch.start", null, callback)
    }

    function watchStop(callback) {
        sendRequest("watch.stop", null, callback)
    }

    function watchStatus(callback) {
        sendRequest("watch.status", null, callback)
    }

    function rediscover() {
        if (isConnected) {
            requestSocket.connected = false
        }
        discoverAndConnect()
    }

    function disconnect() {
        if (isConnected || isConnecting) {
            requestSocket.connected = false
        }
    }
}
