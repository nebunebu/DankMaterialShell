pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool dwlAvailable: false
    property var outputs: ({})
    property var tagCount: 0
    property var layouts: []
    property string activeOutput: ""
    property var outputScales: ({})

    signal stateChanged()

    Connections {
        target: DMSService
        function onCapabilitiesReceived() {
            checkCapabilities()
        }
        function onConnectionStateChanged() {
            if (DMSService.isConnected) {
                checkCapabilities()
            } else {
                dwlAvailable = false
            }
        }
        function onDwlStateUpdate(data) {
            if (dwlAvailable) {
                handleStateUpdate(data)
            }
        }
    }

    Component.onCompleted: {
        if (DMSService.dmsAvailable) {
            checkCapabilities()
        }
        refreshOutputScales()
    }

    Timer {
        id: scaleRefreshTimer
        interval: 2000
        repeat: true
        running: dwlAvailable
        onTriggered: refreshOutputScales()
    }

    function checkCapabilities() {
        if (!DMSService.capabilities || !Array.isArray(DMSService.capabilities)) {
            dwlAvailable = false
            return
        }

        const hasDwl = DMSService.capabilities.includes("dwl")
        if (hasDwl && !dwlAvailable) {
            dwlAvailable = true
            console.info("DwlService: DWL capability detected")
            requestState()
        } else if (!hasDwl) {
            dwlAvailable = false
        }
    }

    function requestState() {
        if (!DMSService.isConnected || !dwlAvailable) {
            return
        }

        DMSService.sendRequest("dwl.getState", null, response => {
            if (response.result) {
                handleStateUpdate(response.result)
            }
        })
    }

    function handleStateUpdate(state) {
        outputs = state.outputs || {}
        tagCount = state.tagCount || 0
        layouts = state.layouts || []
        activeOutput = state.activeOutput || ""
        stateChanged()
    }

    function setTags(outputName, tagmask, toggleTagset) {
        if (!DMSService.isConnected || !dwlAvailable) {
            return
        }

        DMSService.sendRequest("dwl.setTags", {
            "output": outputName,
            "tagmask": tagmask,
            "toggleTagset": toggleTagset
        }, response => {
            if (response.error) {
                console.warn("DwlService: setTags error:", response.error)
            }
        })
    }

    function setClientTags(outputName, andTags, xorTags) {
        if (!DMSService.isConnected || !dwlAvailable) {
            return
        }

        DMSService.sendRequest("dwl.setClientTags", {
            "output": outputName,
            "andTags": andTags,
            "xorTags": xorTags
        }, response => {
            if (response.error) {
                console.warn("DwlService: setClientTags error:", response.error)
            }
        })
    }

    function setLayout(outputName, index) {
        if (!DMSService.isConnected || !dwlAvailable) {
            return
        }

        DMSService.sendRequest("dwl.setLayout", {
            "output": outputName,
            "index": index
        }, response => {
            if (response.error) {
                console.warn("DwlService: setLayout error:", response.error)
            }
        })
    }

    function getOutputState(outputName) {
        if (!outputs || !outputs[outputName]) {
            return null
        }
        return outputs[outputName]
    }

    function getActiveTags(outputName) {
        const output = getOutputState(outputName)
        if (!output || !output.tags) {
            return []
        }
        return output.tags.filter(tag => tag.state === 1).map(tag => tag.tag)
    }

    function getTagsWithClients(outputName) {
        const output = getOutputState(outputName)
        if (!output || !output.tags) {
            return []
        }
        return output.tags.filter(tag => tag.clients > 0).map(tag => tag.tag)
    }

    function getUrgentTags(outputName) {
        const output = getOutputState(outputName)
        if (!output || !output.tags) {
            return []
        }
        return output.tags.filter(tag => tag.state === 2).map(tag => tag.tag)
    }

    function switchToTag(outputName, tagIndex) {
        const tagmask = 1 << tagIndex
        setTags(outputName, tagmask, 0)
    }

    function toggleTag(outputName, tagIndex) {
        const tagmask = 1 << tagIndex
        setTags(outputName, tagmask, 1)
    }

    function quit() {
        Quickshell.execDetached(["mmsg", "-d", "quit"])
    }

    function refreshOutputScales() {
        if (!dwlAvailable) return

        Proc.runCommand("wlr-randr", ["--json"], (output, exitCode) => {
            if (exitCode !== 0) {
                console.warn("DwlService: wlr-randr failed with exit code:", exitCode)
                return
            }
            try {
                const outputData = JSON.parse(output)
                const newScales = {}
                for (const outputInfo of outputData) {
                    if (outputInfo.name && outputInfo.scale !== undefined) {
                        newScales[outputInfo.name] = outputInfo.scale
                    }
                }
                outputScales = newScales
            } catch (e) {
                console.warn("DwlService: Failed to parse wlr-randr output:", e)
            }
        }, 0)
    }

    function getOutputScale(outputName) {
        return outputScales[outputName]
    }
}
