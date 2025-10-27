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
    property int requestIdCounter: 0

    signal searchResultsReceived(var results)
    signal statsReceived(var stats)
    signal errorOccurred(string error)

    Process {
        id: checkProcess
        command: ["sh", "-c", "command -v dsearch"]
        running: true

        stdout: SplitParser {
            onRead: line => {
                if (line && line.trim().length > 0) {
                    root.dsearchAvailable = true
                }
            }
        }

        onExited: exitCode => {
            if (exitCode !== 0) {
                root.dsearchAvailable = false
            }
        }
    }

    function ping(callback) {
        if (!dsearchAvailable) {
            if (callback) {
                callback({ "error": "dsearch not available" })
            }
            return
        }

        Proc.runCommand("dsearch-ping", ["dsearch", "ping", "--json"], (stdout, exitCode) => {
            if (callback) {
                if (exitCode === 0) {
                    try {
                        const response = JSON.parse(stdout)
                        callback({ "result": response })
                    } catch (e) {
                        callback({ "error": "failed to parse ping response" })
                    }
                } else {
                    callback({ "error": "ping failed" })
                }
            }
        })
    }

    function search(query, params, callback) {
        if (!query || query.length === 0) {
            if (callback) {
                callback({ "error": "query is required" })
            }
            return
        }

        if (!dsearchAvailable) {
            if (callback) {
                callback({ "error": "dsearch not available" })
            }
            return
        }

        const args = ["dsearch", "search", query, "--json"]

        if (params) {
            if (params.limit !== undefined) {
                args.push("-n", String(params.limit))
            }
            if (params.ext) {
                args.push("-e", params.ext)
            }
            if (params.field) {
                args.push("-f", params.field)
            }
            if (params.fuzzy) {
                args.push("--fuzzy")
            }
            if (params.sort) {
                args.push("--sort", params.sort)
            }
            if (params.desc !== undefined) {
                args.push("--desc=" + (params.desc ? "true" : "false"))
            }
            if (params.minSize !== undefined) {
                args.push("--min-size", String(params.minSize))
            }
            if (params.maxSize !== undefined) {
                args.push("--max-size", String(params.maxSize))
            }
        }

        Proc.runCommand("dsearch-search", args, (stdout, exitCode) => {
            if (exitCode === 0) {
                try {
                    const response = JSON.parse(stdout)
                    searchResultsReceived(response)
                    if (callback) {
                        callback({ "result": response })
                    }
                } catch (e) {
                    const error = "failed to parse search response"
                    errorOccurred(error)
                    if (callback) {
                        callback({ "error": error })
                    }
                }
            } else {
                const error = "search failed"
                errorOccurred(error)
                if (callback) {
                    callback({ "error": error })
                }
            }
        }, 100)
    }

    function getStats(callback) {
        if (!dsearchAvailable) {
            if (callback) {
                callback({ "error": "dsearch not available" })
            }
            return
        }

        Proc.runCommand("dsearch-stats", ["dsearch", "stats", "--json"], (stdout, exitCode) => {
            if (exitCode === 0) {
                try {
                    const response = JSON.parse(stdout)
                    statsReceived(response)
                    if (callback) {
                        callback({ "result": response })
                    }
                } catch (e) {
                    const error = "failed to parse stats response"
                    errorOccurred(error)
                    if (callback) {
                        callback({ "error": error })
                    }
                }
            } else {
                const error = "stats failed"
                errorOccurred(error)
                if (callback) {
                    callback({ "error": error })
                }
            }
        })
    }

    function sync(callback) {
        if (!dsearchAvailable) {
            if (callback) {
                callback({ "error": "dsearch not available" })
            }
            return
        }

        Proc.runCommand("dsearch-sync", ["dsearch", "sync", "--json"], (stdout, exitCode) => {
            if (callback) {
                if (exitCode === 0) {
                    try {
                        const response = JSON.parse(stdout)
                        callback({ "result": response })
                    } catch (e) {
                        callback({ "error": "failed to parse sync response" })
                    }
                } else {
                    callback({ "error": "sync failed" })
                }
            }
        })
    }

    function reindex(callback) {
        if (!dsearchAvailable) {
            if (callback) {
                callback({ "error": "dsearch not available" })
            }
            return
        }

        Proc.runCommand("dsearch-reindex", ["dsearch", "reindex", "--json"], (stdout, exitCode) => {
            if (callback) {
                if (exitCode === 0) {
                    try {
                        const response = JSON.parse(stdout)
                        callback({ "result": response })
                    } catch (e) {
                        callback({ "error": "failed to parse reindex response" })
                    }
                } else {
                    callback({ "error": "reindex failed" })
                }
            }
        })
    }

    function watchStart(callback) {
        if (!dsearchAvailable) {
            if (callback) {
                callback({ "error": "dsearch not available" })
            }
            return
        }

        Proc.runCommand("dsearch-watch-start", ["dsearch", "watch", "start", "--json"], (stdout, exitCode) => {
            if (callback) {
                if (exitCode === 0) {
                    try {
                        const response = JSON.parse(stdout)
                        callback({ "result": response })
                    } catch (e) {
                        callback({ "error": "failed to parse watch start response" })
                    }
                } else {
                    callback({ "error": "watch start failed" })
                }
            }
        })
    }

    function watchStop(callback) {
        if (!dsearchAvailable) {
            if (callback) {
                callback({ "error": "dsearch not available" })
            }
            return
        }

        Proc.runCommand("dsearch-watch-stop", ["dsearch", "watch", "stop", "--json"], (stdout, exitCode) => {
            if (callback) {
                if (exitCode === 0) {
                    try {
                        const response = JSON.parse(stdout)
                        callback({ "result": response })
                    } catch (e) {
                        callback({ "error": "failed to parse watch stop response" })
                    }
                } else {
                    callback({ "error": "watch stop failed" })
                }
            }
        })
    }

    function watchStatus(callback) {
        if (!dsearchAvailable) {
            if (callback) {
                callback({ "error": "dsearch not available" })
            }
            return
        }

        Proc.runCommand("dsearch-watch-status", ["dsearch", "watch", "status", "--json"], (stdout, exitCode) => {
            if (callback) {
                if (exitCode === 0) {
                    try {
                        const response = JSON.parse(stdout)
                        callback({ "result": response })
                    } catch (e) {
                        callback({ "error": "failed to parse watch status response" })
                    }
                } else {
                    callback({ "error": "watch status failed" })
                }
            }
        })
    }

    function rediscover() {
        checkProcess.running = true
    }
}
