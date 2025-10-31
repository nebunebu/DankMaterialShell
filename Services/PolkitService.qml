pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property bool disablePolkitIntegration: Quickshell.env("DMS_DISABLE_POLKIT") === "1"

    property bool polkitAvailable: false

    property var agent: null
    property var currentFlow: null
    property bool isActive: false

    property string message: ""
    property string supplementaryMessage: ""
    property string inputPrompt: ""
    property bool failed: false
    property bool responseVisible: false
    property bool isResponseRequired: false

    signal authenticationRequested()
    signal authenticationCompleted()
    signal authenticationFailed()

    function createPolkitAgent() {
        try {
            const qmlString = `
                import QtQuick
                import Quickshell.Services.Polkit

                PolkitAgent {
                }
            `

            agent = Qt.createQmlObject(qmlString, root, "PolkitService.Agent")

            agent.isActiveChanged.connect(function() {
                root.isActive = agent.isActive
                if (agent.isActive) {
                    root.authenticationRequested()
                } else {
                    root.authenticationCompleted()
                }
            })

            agent.flowChanged.connect(function() {
                currentFlow = agent.flow
                if (currentFlow) {
                    updateFlowProperties()

                    if (currentFlow.messageChanged) currentFlow.messageChanged.connect(() => updateFlowProperties())
                    if (currentFlow.supplementaryMessageChanged) currentFlow.supplementaryMessageChanged.connect(() => updateFlowProperties())
                    if (currentFlow.inputPromptChanged) currentFlow.inputPromptChanged.connect(() => updateFlowProperties())
                    if (currentFlow.failedChanged) currentFlow.failedChanged.connect(() => updateFlowProperties())
                    if (currentFlow.responseVisibleChanged) currentFlow.responseVisibleChanged.connect(() => updateFlowProperties())
                    if (currentFlow.isResponseRequiredChanged) currentFlow.isResponseRequiredChanged.connect(() => updateFlowProperties())
                }
            })

            polkitAvailable = true
            console.info("PolkitService: Initialized successfully")
        } catch (e) {
            polkitAvailable = false
            console.warn("PolkitService: Polkit not available - authentication prompts disabled. This requires a newer version of Quickshell.")
        }
    }

    function updateFlowProperties() {
        if (!currentFlow) return

        message = currentFlow.message !== undefined ? currentFlow.message : ""
        supplementaryMessage = currentFlow.supplementaryMessage !== undefined ? currentFlow.supplementaryMessage : ""
        inputPrompt = currentFlow.inputPrompt !== undefined ? currentFlow.inputPrompt : ""
        failed = currentFlow.failed !== undefined ? currentFlow.failed : false
        responseVisible = currentFlow.responseVisible !== undefined ? currentFlow.responseVisible : false
        isResponseRequired = currentFlow.isResponseRequired !== undefined ? currentFlow.isResponseRequired : false
    }

    function submit(response) {
        if (currentFlow && isResponseRequired) {
            currentFlow.submit(response)
        }
    }

    function cancel() {
        if (currentFlow) {
            currentFlow.cancelAuthenticationRequest()
        }
    }

    Component.onCompleted: {
        if (disablePolkitIntegration) {
            return
        }
        createPolkitAgent()
    }
}
