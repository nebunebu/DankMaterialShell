import QtQuick
import QtQuick.Effects
import qs.Common
import qs.Widgets

StyledRect {
    id: delegateRoot

    required property bool fileIsDir
    required property string filePath
    required property string fileName
    required property int index

    property bool weMode: false
    property var iconSizes: [80, 120, 160, 200]
    property int iconSizeIndex: 1
    property int selectedIndex: -1
    property bool keyboardNavigationActive: false

    signal itemClicked(int index, string path, string name, bool isDir)
    signal itemSelected(int index, string path, string name, bool isDir)

    function isImageFile(fileName) {
        if (!fileName) {
            return false
        }
        const ext = fileName.toLowerCase().split('.').pop()
        return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'].includes(ext)
    }

    function getFileIcon(fileName, isDir) {
        if (isDir) {
            return "folder"
        }
        if (!fileName) {
            return "description"
        }
        const ext = fileName.toLowerCase().split('.').pop()
        const iconMap = {
            "mp3": 'music_note',
            "wav": 'music_note',
            "flac": 'music_note',
            "ogg": 'music_note',
            "aac": 'music_note',
            "mp4": 'movie',
            "mkv": 'movie',
            "avi": 'movie',
            "mov": 'movie',
            "webm": 'movie',
            "flv": 'movie',
            "wmv": 'movie',
            "jpg": 'image',
            "jpeg": 'image',
            "png": 'image',
            "gif": 'image',
            "bmp": 'image',
            "webp": 'image',
            "svg": 'image',
            "pdf": 'picture_as_pdf',
            "zip": 'folder_zip',
            "rar": 'folder_zip',
            "7z": 'folder_zip',
            "tar": 'folder_zip',
            "gz": 'folder_zip',
            "bz2": 'folder_zip',
            "xz": 'folder_zip',
            "txt": 'description',
            "md": 'description',
            "doc": 'description',
            "docx": 'description',
            "odt": 'description',
            "rtf": 'description',
            "sh": 'terminal',
            "py": 'code',
            "js": 'code',
            "ts": 'code',
            "cpp": 'code',
            "c": 'code',
            "h": 'code',
            "java": 'code',
            "go": 'code',
            "rs": 'code',
            "php": 'code',
            "rb": 'code',
            "qml": 'code',
            "html": 'code',
            "css": 'code',
            "json": 'data_object',
            "xml": 'data_object',
            "yaml": 'data_object',
            "yml": 'data_object',
            "toml": 'data_object'
        }
        return iconMap[ext] || 'description'
    }

    width: weMode ? 245 : iconSizes[iconSizeIndex] + 16
    height: weMode ? 205 : iconSizes[iconSizeIndex] + 48
    radius: Theme.cornerRadius
    color: {
        if (keyboardNavigationActive && delegateRoot.index === selectedIndex)
            return Theme.surfacePressed

        return mouseArea.containsMouse ? Theme.surfaceContainerHigh : "transparent"
    }
    border.color: keyboardNavigationActive && delegateRoot.index === selectedIndex ? Theme.primary : "transparent"
    border.width: (keyboardNavigationActive && delegateRoot.index === selectedIndex) ? 2 : 0

    Component.onCompleted: {
        if (keyboardNavigationActive && delegateRoot.index === selectedIndex)
            itemSelected(delegateRoot.index, delegateRoot.filePath, delegateRoot.fileName, delegateRoot.fileIsDir)
    }

    onSelectedIndexChanged: {
        if (keyboardNavigationActive && selectedIndex === delegateRoot.index)
            itemSelected(delegateRoot.index, delegateRoot.filePath, delegateRoot.fileName, delegateRoot.fileIsDir)
    }

    Column {
        anchors.centerIn: parent
        spacing: Theme.spacingS

        Item {
            width: weMode ? 225 : (iconSizes[iconSizeIndex] - 8)
            height: weMode ? 165 : (iconSizes[iconSizeIndex] - 8)
            anchors.horizontalCenter: parent.horizontalCenter

            CachingImage {
                id: gridPreviewImage
                anchors.fill: parent
                anchors.margins: 2
                property var weExtensions: [".jpg", ".jpeg", ".png", ".webp", ".gif", ".bmp", ".tga"]
                property int weExtIndex: 0
                source: {
                    if (weMode && delegateRoot.fileIsDir) {
                        return "file://" + delegateRoot.filePath + "/preview" + weExtensions[weExtIndex]
                    }
                    return (!delegateRoot.fileIsDir && isImageFile(delegateRoot.fileName)) ? ("file://" + delegateRoot.filePath) : ""
                }
                onStatusChanged: {
                    if (weMode && delegateRoot.fileIsDir && status === Image.Error) {
                        if (weExtIndex < weExtensions.length - 1) {
                            weExtIndex++
                            source = "file://" + delegateRoot.filePath + "/preview" + weExtensions[weExtIndex]
                        } else {
                            source = ""
                        }
                    }
                }
                fillMode: Image.PreserveAspectCrop
                maxCacheSize: weMode ? 225 : iconSizes[iconSizeIndex]
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                anchors.margins: 2
                source: gridPreviewImage
                maskEnabled: true
                maskSource: gridImageMask
                visible: gridPreviewImage.status === Image.Ready && ((!delegateRoot.fileIsDir && isImageFile(delegateRoot.fileName)) || (weMode && delegateRoot.fileIsDir))
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1
            }

            Item {
                id: gridImageMask
                anchors.fill: parent
                anchors.margins: 2
                layer.enabled: true
                layer.smooth: true
                visible: false

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.cornerRadius
                    color: "black"
                    antialiasing: true
                }
            }

            DankIcon {
                anchors.centerIn: parent
                name: getFileIcon(delegateRoot.fileName, delegateRoot.fileIsDir)
                size: iconSizes[iconSizeIndex] * 0.45
                color: delegateRoot.fileIsDir ? Theme.primary : Theme.surfaceText
                visible: (!delegateRoot.fileIsDir && !isImageFile(delegateRoot.fileName)) || (delegateRoot.fileIsDir && !weMode)
            }
        }

        StyledText {
            text: delegateRoot.fileName || ""
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceText
            width: delegateRoot.width - Theme.spacingM
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
            maximumLineCount: 2
            wrapMode: Text.Wrap
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            itemClicked(delegateRoot.index, delegateRoot.filePath, delegateRoot.fileName, delegateRoot.fileIsDir)
        }
    }
}
