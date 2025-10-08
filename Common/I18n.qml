import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root

    property string currentLocale: Qt.locale().name.substring(0, 2)
    property var translations: ({})
    property bool translationsLoaded: false

    Component.onCompleted: {
        translationLoader.running = true
    }

    Process {
        id: translationLoader
        command: ["cat", Qt.resolvedUrl(`../translations/${currentLocale}.json`).toString().replace("file://", "")]
        running: false

        stdout: StdioCollector {
            onStreamFinished: () => {
                try {
                    root.translations = JSON.parse(data)
                    root.translationsLoaded = true
                    console.log(`I18n: Loaded translations for locale '${currentLocale}' (${Object.keys(root.translations).length} contexts)`)
                } catch (e) {
                    console.warn(`I18n: Error parsing translations for locale '${currentLocale}':`, e, "- falling back to English")
                    root.translationsLoaded = false
                }
            }
        }

        onExited: (code, status) => {
            if (code !== 0) {
                console.warn(`I18n: Failed to load translations for locale '${currentLocale}' (exit code ${code}), falling back to English`)
                root.translationsLoaded = false
            }
        }
    }

    function tr(term, context) {
        if (!translationsLoaded || !translations) {
            return term
        }

        const actualContext = context || term

        if (translations[actualContext] && translations[actualContext][term]) {
            return translations[actualContext][term]
        }

        for (const ctx in translations) {
            if (translations[ctx][term]) {
                return translations[ctx][term]
            }
        }

        return term
    }

    function trContext(context, term) {
        if (!translationsLoaded || !translations) {
            return term
        }

        if (translations[context] && translations[context][term]) {
            return translations[context][term]
        }

        return term
    }
}
