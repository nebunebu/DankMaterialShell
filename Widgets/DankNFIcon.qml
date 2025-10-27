import QtQuick
import qs.Common

Item {
    id: root

    property string name: ""
    property alias size: icon.font.pixelSize
    property alias color: icon.color

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight
    visible: text.length > 0

    // This is for file browser, particularly - might want another map later for app IDs
    readonly property var iconMap: ({
        // --- special filenames (no extension) ---
        "docker":               "\u{F0868}",
        "makefile":             "\u{F09EE}",
        "license":              "\u{F09EE}",
        "readme":               "\u{F0354}",

        // --- programming languages ---
        "rs":                   "\u{F1617}",
        "go":                   "\u{F07D3}",
        "py":                   "\u{F0320}",
        "js":                   "\u{F031E}",
        "jsx":                  "\u{F031E}",
        "ts":                   "\u{F06E6}",
        "tsx":                  "\u{F06E6}",
        "java":                 "\u{F0B37}",
        "c":                    "\u{F0671}",
        "cpp":                  "\u{F0672}",
        "cxx":                  "\u{F0672}",
        "h":                    "\u{F0672}",
        "hpp":                  "\u{F0672}",
        "cs":                   "\u{F031B}",
        "html":                 "\u{e60e}",
        "htm":                  "\u{e60e}",
        "css":                  "\u{E6b8}",
        "scss":                 "\u{F031C}",
        "less":                 "\u{F031C}",
        "md":                   "\u{F0354}",
        "markdown":             "\u{F0354}",
        "json":                 "\u{eb0f}",
        "jsonc":                "\u{eb0f}",
        "yaml":                 "\u{e8eb}",
        "yml":                  "\u{e8eb}",
        "xml":                  "\u{F09EE}",
        "sql":                  "\u{f1c0}",

        // --- scripts / shells ---
        "sh":                   "\u{F08A9}",
        "bash":                 "\u{F08A9}",
        "zsh":                  "\u{F08A9}",
        "fish":                 "\u{F08A9}",
        "ps1":                  "\u{F08A9}",
        "bat":                  "\u{F08A9}",

        // --- data / config ---
        "toml":                 "\u{F09EE}",
        "ini":                  "\u{F09EE}",
        "conf":                 "\u{F09EE}",
        "cfg":                  "\u{F09EE}",
        "csv":                  "\u{F021C}",
        "tsv":                  "\u{F021C}",

        // --- docs / office ---
        "pdf":                  "\u{F0226}",
        "doc":                  "\u{F09EE}",
        "docx":                 "\u{F09EE}",
        "rtf":                  "\u{F09EE}",
        "ppt":                  "\u{F09EE}",
        "pptx":                 "\u{F09EE}",
        "xls":                  "\u{F021C}",
        "xlsx":                 "\u{F021C}",

        // --- images ---
        "ico":                  "\u{F021F}",

        // --- audio / video ---
        "mp3":                  "\u{e638}",
        "wav":                  "\u{e638}",
        "flac":                 "\u{e638}",
        "ogg":                  "\u{e638}",
        "mp4":                  "\u{f0567}",
        "mkv":                  "\u{f0567}",
        "webm":                 "\u{f0567}",
        "mov":                  "\u{f0567}",

        // --- archives / packages ---
        "zip":                  "\u{e6aa}",
        "tar":                  "\u{f003c}",
        "gz":                   "\u{f003c}",
        "bz2":                  "\u{f003c}",
        "7z":                   "\u{f003c}",

        // --- containers / infra / cloud ---
        "dockerfile":           "\u{F0868}",
        "yml.k8s":              "\u{F09EE}",
        "yaml.k8s":             "\u{F09EE}",
        "tf":                   "\u{F09EE}",
        "tfvars":               "\u{F09EE}"
    })


    readonly property string text: iconMap[name] || ""

    function getIconForFile(fileName) {
        const lowerName = fileName.toLowerCase()
        if (lowerName.startsWith("dockerfile")) {
            return "docker"
        }
        const ext = fileName.split('.').pop()
        return ext || ""
    }

    FontLoader {
        id: firaCodeFont
        source: Qt.resolvedUrl("../assets/fonts/nerd-fonts/FiraCodeNerdFont-Regular.ttf")
    }

    StyledText {
        id: icon

        anchors.fill: parent

        font.family: firaCodeFont.name
        font.pixelSize: Theme.fontSizeMedium
        color: Theme.surfaceText
        text: root.text
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        renderType: Text.NativeRendering
        antialiasing: true
    }
}
