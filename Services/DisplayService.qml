pragma Singleton

pragma ComponentBehavior

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

Singleton {
    id: root

    property bool brightnessAvailable: devices.length > 0
    property var devices: []
    property var deviceBrightness: ({})
    property string currentDevice: ""
    property string lastIpcDevice: ""
    property int brightnessLevel: {
        const deviceToUse = lastIpcDevice === "" ? getDefaultDevice() : (lastIpcDevice || currentDevice)
        if (!deviceToUse) {
            return 50
        }

        return getDeviceBrightness(deviceToUse)
    }
    property int maxBrightness: 100
    property bool brightnessInitialized: false

    signal brightnessChanged
    signal deviceSwitched

    property bool nightModeActive: nightModeEnabled

    property bool nightModeEnabled: false
    property bool automationAvailable: false
    property bool gammaControlAvailable: false

    function updateFromBrightnessState(state) {
        if (!state || !state.devices) {
            return
        }

        devices = state.devices.map(d => ({
                                              "id": d.id,
                                              "name": d.id,
                                              "class": d.class,
                                              "current": d.current,
                                              "percentage": d.currentPercent,
                                              "max": d.max,
                                              "backend": d.backend
                                          }))

        const newBrightness = {}
        for (const device of state.devices) {
            newBrightness[device.id] = device.currentPercent
        }
        deviceBrightness = newBrightness

        brightnessAvailable = devices.length > 0

        if (devices.length > 0 && !currentDevice) {
            const lastDevice = SessionData.lastBrightnessDevice || ""
            const deviceExists = devices.some(d => d.id === lastDevice)
            if (deviceExists) {
                setCurrentDevice(lastDevice, false)
            } else {
                const backlight = devices.find(d => d.class === "backlight")
                const nonKbdDevice = devices.find(d => !d.id.includes("kbd"))
                const defaultDevice = backlight || nonKbdDevice || devices[0]
                setCurrentDevice(defaultDevice.id, false)
            }
        }

        if (!brightnessInitialized) {
            brightnessInitialized = true
        }
    }

    function setBrightness(percentage, device, suppressOsd) {
        const clampedValue = Math.max(1, Math.min(100, percentage))
        const actualDevice = device === "" ? getDefaultDevice() : (device || currentDevice || getDefaultDevice())

        if (!actualDevice) {
            console.warn("DisplayService: No device selected for brightness change")
            return
        }

        if (!DMSService.isConnected) {
            console.warn("DisplayService: Not connected to DMS")
            return
        }

        DMSService.sendRequest("brightness.setBrightness", {
                                   "device": actualDevice,
                                   "percent": clampedValue
                               }, response => {
                                   if (response.error) {
                                       console.error("DisplayService: Failed to set brightness:", response.error)
                                       ToastService.showError("Failed to set brightness: " + response.error)
                                       return
                                   }

                                   if (!suppressOsd) {
                                       brightnessChanged()
                                   }
                               })
    }

    function setCurrentDevice(deviceName, saveToSession = false) {
        if (currentDevice === deviceName) {
            return
        }

        currentDevice = deviceName
        lastIpcDevice = deviceName

        if (saveToSession) {
            SessionData.setLastBrightnessDevice(deviceName)
        }

        deviceSwitched()
    }

    function getDeviceBrightness(deviceName) {
        if (!deviceName) {
            return 50
        }

        if (deviceName in deviceBrightness) {
            return deviceBrightness[deviceName]
        }

        return 50
    }

    function getDefaultDevice() {
        for (const device of devices) {
            if (device.class === "backlight") {
                return device.id
            }
        }
        return devices.length > 0 ? devices[0].id : ""
    }

    function getCurrentDeviceInfo() {
        const deviceToUse = lastIpcDevice === "" ? getDefaultDevice() : (lastIpcDevice || currentDevice)
        if (!deviceToUse) {
            return null
        }

        for (const device of devices) {
            if (device.id === deviceToUse) {
                return device
            }
        }
        return null
    }

    function isCurrentDeviceReady() {
        const deviceToUse = lastIpcDevice === "" ? getDefaultDevice() : (lastIpcDevice || currentDevice)
        return deviceToUse !== ""
    }

    function getCurrentDeviceInfoByName(deviceName) {
        if (!deviceName) {
            return null
        }

        for (const device of devices) {
            if (device.id === deviceName) {
                return device
            }
        }
        return null
    }

    // Night Mode Functions - Simplified
    function enableNightMode() {
        if (!gammaControlAvailable) {
            ToastService.showWarning("Night mode failed: DMS gamma control not available")
            return
        }

        nightModeEnabled = true
        SessionData.setNightModeEnabled(true)

        DMSService.sendRequest("wayland.gamma.setEnabled", {
                                   "enabled": true
                               }, response => {
                                   if (response.error) {
                                       console.error("DisplayService: Failed to enable gamma control:", response.error)
                                       ToastService.showError("Failed to enable night mode: " + response.error)
                                       nightModeEnabled = false
                                       SessionData.setNightModeEnabled(false)
                                       return
                                   }

                                   if (SessionData.nightModeAutoEnabled) {
                                       startAutomation()
                                   } else {
                                       applyNightModeDirectly()
                                   }
                               })
    }

    function disableNightMode() {
        nightModeEnabled = false
        SessionData.setNightModeEnabled(false)

        if (!gammaControlAvailable) {
            return
        }

        DMSService.sendRequest("wayland.gamma.setEnabled", {
                                   "enabled": false
                               }, response => {
                                   if (response.error) {
                                       console.error("DisplayService: Failed to disable gamma control:", response.error)
                                       ToastService.showError("Failed to disable night mode: " + response.error)
                                   }
                               })
    }

    function toggleNightMode() {
        if (nightModeEnabled) {
            disableNightMode()
        } else {
            enableNightMode()
        }
    }

    function applyNightModeDirectly() {
        const temperature = SessionData.nightModeTemperature || 4000

        DMSService.sendRequest("wayland.gamma.setManualTimes", {
                                   "sunrise": null,
                                   "sunset": null
                               }, response => {
                                   if (response.error) {
                                       console.error("DisplayService: Failed to clear manual times:", response.error)
                                       return
                                   }

                                   DMSService.sendRequest("wayland.gamma.setUseIPLocation", {
                                                              "use": false
                                                          }, response => {
                                                              if (response.error) {
                                                                  console.error("DisplayService: Failed to disable IP location:", response.error)
                                                                  return
                                                              }

                                                              DMSService.sendRequest("wayland.gamma.setTemperature", {
                                                                                         "temp": temperature
                                                                                     }, response => {
                                                                                         if (response.error) {
                                                                                             console.error("DisplayService: Failed to set temperature:", response.error)
                                                                                             ToastService.showError("Failed to set night mode temperature: " + response.error)
                                                                                         }
                                                                                     })
                                                          })
                               })
    }

    function startAutomation() {
        if (!automationAvailable) {
            return
        }

        const mode = SessionData.nightModeAutoMode || "time"

        switch (mode) {
        case "time":
            startTimeBasedMode()
            break
        case "location":
            startLocationBasedMode()
            break
        }
    }

    function startTimeBasedMode() {
        const temperature = SessionData.nightModeTemperature || 4000
        const highTemp = SessionData.nightModeHighTemperature || 6500
        const sunriseHour = SessionData.nightModeEndHour
        const sunriseMinute = SessionData.nightModeEndMinute
        const sunsetHour = SessionData.nightModeStartHour
        const sunsetMinute = SessionData.nightModeStartMinute

        const sunrise = `${String(sunriseHour).padStart(2, '0')}:${String(sunriseMinute).padStart(2, '0')}`
        const sunset = `${String(sunsetHour).padStart(2, '0')}:${String(sunsetMinute).padStart(2, '0')}`

        DMSService.sendRequest("wayland.gamma.setUseIPLocation", {
                                   "use": false
                               }, response => {
                                   if (response.error) {
                                       console.error("DisplayService: Failed to disable IP location:", response.error)
                                       return
                                   }

                                   DMSService.sendRequest("wayland.gamma.setTemperature", {
                                                              "low": temperature,
                                                              "high": highTemp
                                                          }, response => {
                                                              if (response.error) {
                                                                  console.error("DisplayService: Failed to set temperature:", response.error)
                                                                  ToastService.showError("Failed to set night mode temperature: " + response.error)
                                                                  return
                                                              }

                                                              DMSService.sendRequest("wayland.gamma.setManualTimes", {
                                                                                         "sunrise": sunrise,
                                                                                         "sunset": sunset
                                                                                     }, response => {
                                                                                         if (response.error) {
                                                                                             console.error("DisplayService: Failed to set manual times:", response.error)
                                                                                             ToastService.showError("Failed to set night mode schedule: " + response.error)
                                                                                         }
                                                                                     })
                                                          })
                               })
    }

    function startLocationBasedMode() {
        const temperature = SessionData.nightModeTemperature || 4000
        const highTemp = SessionData.nightModeHighTemperature || 6500

        DMSService.sendRequest("wayland.gamma.setManualTimes", {
                                   "sunrise": null,
                                   "sunset": null
                               }, response => {
                                   if (response.error) {
                                       console.error("DisplayService: Failed to clear manual times:", response.error)
                                       return
                                   }

                                   DMSService.sendRequest("wayland.gamma.setTemperature", {
                                                              "low": temperature,
                                                              "high": highTemp
                                                          }, response => {
                                                              if (response.error) {
                                                                  console.error("DisplayService: Failed to set temperature:", response.error)
                                                                  ToastService.showError("Failed to set night mode temperature: " + response.error)
                                                                  return
                                                              }

                                                              if (SessionData.nightModeUseIPLocation) {
                                                                  DMSService.sendRequest("wayland.gamma.setUseIPLocation", {
                                                                                             "use": true
                                                                                         }, response => {
                                                                                             if (response.error) {
                                                                                                 console.error("DisplayService: Failed to enable IP location:", response.error)
                                                                                                 ToastService.showError("Failed to enable IP location: " + response.error)
                                                                                             }
                                                                                         })
                                                              } else if (SessionData.latitude !== 0.0 && SessionData.longitude !== 0.0) {
                                                                  DMSService.sendRequest("wayland.gamma.setUseIPLocation", {
                                                                                             "use": false
                                                                                         }, response => {
                                                                                             if (response.error) {
                                                                                                 console.error("DisplayService: Failed to disable IP location:", response.error)
                                                                                                 return
                                                                                             }

                                                                                             DMSService.sendRequest("wayland.gamma.setLocation", {
                                                                                                                        "latitude": SessionData.latitude,
                                                                                                                        "longitude": SessionData.longitude
                                                                                                                    }, response => {
                                                                                                                        if (response.error) {
                                                                                                                            console.error("DisplayService: Failed to set location:", response.error)
                                                                                                                            ToastService.showError("Failed to set night mode location: " + response.error)
                                                                                                                        }
                                                                                                                    })
                                                                                         })
                                                              } else {
                                                                  console.warn("DisplayService: Location mode selected but no coordinates set and IP location disabled")
                                                              }
                                                          })
                               })
    }

    function setNightModeAutomationMode(mode) {
        SessionData.setNightModeAutoMode(mode)
    }

    function evaluateNightMode() {
        if (!nightModeEnabled) {
            return
        }

        if (SessionData.nightModeAutoEnabled) {
            restartTimer.nextAction = "automation"
            restartTimer.start()
        } else {
            restartTimer.nextAction = "direct"
            restartTimer.start()
        }
    }

    function checkGammaControlAvailability() {
        if (!DMSService.isConnected) {
            return
        }

        if (DMSService.apiVersion < 6) {
            gammaControlAvailable = false
            automationAvailable = false
            return
        }

        if (!DMSService.capabilities.includes("gamma")) {
            gammaControlAvailable = false
            automationAvailable = false
            return
        }

        DMSService.sendRequest("wayland.gamma.getState", null, response => {
                                   if (response.error) {
                                       gammaControlAvailable = false
                                       automationAvailable = false
                                       console.error("DisplayService: Gamma control not available:", response.error)
                                   } else {
                                       gammaControlAvailable = true
                                       automationAvailable = true

                                       if (nightModeEnabled) {
                                           DMSService.sendRequest("wayland.gamma.setEnabled", {
                                                                      "enabled": true
                                                                  }, enableResponse => {
                                                                      if (enableResponse.error) {
                                                                          console.error("DisplayService: Failed to enable gamma control on startup:", enableResponse.error)
                                                                          return
                                                                      }

                                                                      if (SessionData.nightModeAutoEnabled) {
                                                                          startAutomation()
                                                                      } else {
                                                                          applyNightModeDirectly()
                                                                      }
                                                                  })
                                       }
                                   }
                               })
    }

    Timer {
        id: restartTimer
        property string nextAction: ""
        interval: 100
        repeat: false

        onTriggered: {
            if (nextAction === "automation") {
                startAutomation()
            } else if (nextAction === "direct") {
                applyNightModeDirectly()
            }
            nextAction = ""
        }
    }

    Component.onCompleted: {
        nightModeEnabled = SessionData.nightModeEnabled
        if (DMSService.isConnected) {
            checkGammaControlAvailability()
        }
    }

    Connections {
        target: DMSService

        function onConnectionStateChanged() {
            if (DMSService.isConnected) {
                checkGammaControlAvailability()
            } else {
                brightnessAvailable = false
                gammaControlAvailable = false
                automationAvailable = false
            }
        }

        function onCapabilitiesReceived() {
            checkGammaControlAvailability()
        }

        function onBrightnessStateUpdate(data) {
            updateFromBrightnessState(data)
        }
    }

    // Session Data Connections
    Connections {
        target: SessionData

        function onNightModeEnabledChanged() {
            nightModeEnabled = SessionData.nightModeEnabled
            evaluateNightMode()
        }

        function onNightModeAutoEnabledChanged() {
            evaluateNightMode()
        }
        function onNightModeAutoModeChanged() {
            evaluateNightMode()
        }
        function onNightModeStartHourChanged() {
            evaluateNightMode()
        }
        function onNightModeStartMinuteChanged() {
            evaluateNightMode()
        }
        function onNightModeEndHourChanged() {
            evaluateNightMode()
        }
        function onNightModeEndMinuteChanged() {
            evaluateNightMode()
        }
        function onNightModeTemperatureChanged() {
            evaluateNightMode()
        }
        function onNightModeHighTemperatureChanged() {
            evaluateNightMode()
        }
        function onLatitudeChanged() {
            evaluateNightMode()
        }
        function onLongitudeChanged() {
            evaluateNightMode()
        }
        function onNightModeUseIPLocationChanged() {
            evaluateNightMode()
        }
    }

    // IPC Handler for external control
    IpcHandler {
        function set(percentage: string, device: string): string {
            if (!root.brightnessAvailable) {
                return "Brightness control not available"
            }

            const value = parseInt(percentage)
            if (isNaN(value)) {
                return "Invalid brightness value: " + percentage
            }

            const clampedValue = Math.max(1, Math.min(100, value))
            const targetDevice = device || ""

            if (targetDevice && !root.devices.some(d => d.id === targetDevice)) {
                return "Device not found: " + targetDevice
            }

            root.lastIpcDevice = targetDevice
            if (targetDevice && targetDevice !== root.currentDevice) {
                root.setCurrentDevice(targetDevice, false)
            }
            root.setBrightness(clampedValue, targetDevice)

            if (targetDevice) {
                return "Brightness set to " + clampedValue + "% on " + targetDevice
            } else {
                return "Brightness set to " + clampedValue + "%"
            }
        }

        function increment(step: string, device: string): string {
            if (!root.brightnessAvailable) {
                return "Brightness control not available"
            }

            const targetDevice = device || ""
            const actualDevice = targetDevice === "" ? root.getDefaultDevice() : targetDevice

            if (actualDevice && !root.devices.some(d => d.id === actualDevice)) {
                return "Device not found: " + actualDevice
            }

            const currentLevel = actualDevice ? root.getDeviceBrightness(actualDevice) : root.brightnessLevel
            const stepValue = parseInt(step || "10")
            const newLevel = Math.max(1, Math.min(100, currentLevel + stepValue))

            root.lastIpcDevice = targetDevice
            if (targetDevice && targetDevice !== root.currentDevice) {
                root.setCurrentDevice(targetDevice, false)
            }
            root.setBrightness(newLevel, targetDevice)

            if (targetDevice) {
                return "Brightness increased to " + newLevel + "% on " + targetDevice
            } else {
                return "Brightness increased to " + newLevel + "%"
            }
        }

        function decrement(step: string, device: string): string {
            if (!root.brightnessAvailable) {
                return "Brightness control not available"
            }

            const targetDevice = device || ""
            const actualDevice = targetDevice === "" ? root.getDefaultDevice() : targetDevice

            if (actualDevice && !root.devices.some(d => d.id === actualDevice)) {
                return "Device not found: " + actualDevice
            }

            const currentLevel = actualDevice ? root.getDeviceBrightness(actualDevice) : root.brightnessLevel
            const stepValue = parseInt(step || "10")
            const newLevel = Math.max(1, Math.min(100, currentLevel - stepValue))

            root.lastIpcDevice = targetDevice
            if (targetDevice && targetDevice !== root.currentDevice) {
                root.setCurrentDevice(targetDevice, false)
            }
            root.setBrightness(newLevel, targetDevice)

            if (targetDevice) {
                return "Brightness decreased to " + newLevel + "% on " + targetDevice
            } else {
                return "Brightness decreased to " + newLevel + "%"
            }
        }

        function status(): string {
            if (!root.brightnessAvailable) {
                return "Brightness control not available"
            }

            return "Device: " + root.currentDevice + " - Brightness: " + root.brightnessLevel + "%"
        }

        function list(): string {
            if (!root.brightnessAvailable) {
                return "No brightness devices available"
            }

            let result = "Available devices:\\n"
            for (const device of root.devices) {
                result += device.id + " (" + device.class + ")\\n"
            }
            return result
        }

        target: "brightness"
    }

    // IPC Handler for night mode control
    IpcHandler {
        function toggle(): string {
            root.toggleNightMode()
            return root.nightModeEnabled ? "Night mode enabled" : "Night mode disabled"
        }

        function enable(): string {
            root.enableNightMode()
            return "Night mode enabled"
        }

        function disable(): string {
            root.disableNightMode()
            return "Night mode disabled"
        }

        function status(): string {
            return root.nightModeEnabled ? "Night mode is enabled" : "Night mode is disabled"
        }

        function temperature(value: string): string {
            if (!value) {
                return "Current temperature: " + SessionData.nightModeTemperature + "K"
            }

            const temp = parseInt(value)
            if (isNaN(temp)) {
                return "Invalid temperature. Use a value between 2500 and 6000 (in steps of 500)"
            }

            // Validate temperature is in valid range and steps
            if (temp < 2500 || temp > 6000) {
                return "Temperature must be between 2500K and 6000K"
            }

            // Round to nearest 500
            const rounded = Math.round(temp / 500) * 500

            SessionData.setNightModeTemperature(rounded)

            // Restart night mode with new temperature if active
            if (root.nightModeEnabled) {
                if (SessionData.nightModeAutoEnabled) {
                    root.startAutomation()
                } else {
                    root.applyNightModeDirectly()
                }
            }

            if (rounded !== temp) {
                return "Night mode temperature set to " + rounded + "K (rounded from " + temp + "K)"
            } else {
                return "Night mode temperature set to " + rounded + "K"
            }
        }

        target: "night"
    }
}
