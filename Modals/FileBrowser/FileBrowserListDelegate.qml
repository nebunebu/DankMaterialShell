import QtQuick
import QtQuick.Effects
import qs.Common
import qs.Widgets

StyledRect {
    id: listDelegateRoot

    required property bool fileIsDir
    required property string filePath
    required property string fileName
    required property int index
    required property var fileModified
    required property int fileSize

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

    function formatFileSize(size) {
        if (size < 1024)
            return size + " B"
        if (size < 1024 * 1024)
            return (size / 1024).toFixed(1) + " KB"
        if (size < 1024 * 1024 * 1024)
            return (size / (1024 * 1024)).toFixed(1) + " MB"
        return (size / (1024 * 1024 * 1024)).toFixed(1) + " GB"
    }

    height: 44
    radius: Theme.cornerRadius
    color: {
        if (keyboardNavigationActive && listDelegateRoot.index === selectedIndex)
            return Theme.surfacePressed
        return listMouseArea.containsMouse ? Theme.surfaceContainerHigh : "transparent"
    }
    border.color: keyboardNavigationActive && listDelegateRoot.index === selectedIndex ? Theme.primary : "transparent"
    border.width: (keyboardNavigationActive && listDelegateRoot.index === selectedIndex) ? 2 : 0

    Component.onCompleted: {
        if (keyboardNavigationActive && listDelegateRoot.index === selectedIndex)
            itemSelected(listDelegateRoot.index, listDelegateRoot.filePath, listDelegateRoot.fileName, listDelegateRoot.fileIsDir)
    }

    onSelectedIndexChanged: {
        if (keyboardNavigationActive && selectedIndex === listDelegateRoot.index)
            itemSelected(listDelegateRoot.index, listDelegateRoot.filePath, listDelegateRoot.fileName, listDelegateRoot.fileIsDir)
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingS
        anchors.rightMargin: Theme.spacingS
        spacing: Theme.spacingS

        Item {
            width: 28
            height: 28
            anchors.verticalCenter: parent.verticalCenter

            CachingImage {
                id: listPreviewImage
                anchors.fill: parent
                source: (!listDelegateRoot.fileIsDir && isImageFile(listDelegateRoot.fileName)) ? ("file://" + listDelegateRoot.filePath) : ""
                fillMode: Image.PreserveAspectCrop
                maxCacheSize: 32
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                source: listPreviewImage
                maskEnabled: true
                maskSource: listImageMask
                visible: listPreviewImage.status === Image.Ready && !listDelegateRoot.fileIsDir && isImageFile(listDelegateRoot.fileName)
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1
            }

            Item {
                id: listImageMask
                anchors.fill: parent
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
                name: getFileIcon(listDelegateRoot.fileName, listDelegateRoot.fileIsDir)
                size: Theme.iconSize - 2
                color: listDelegateRoot.fileIsDir ? Theme.primary : Theme.surfaceText
                visible: listDelegateRoot.fileIsDir || !isImageFile(listDelegateRoot.fileName)
            }
        }

        StyledText {
            text: listDelegateRoot.fileName || ""
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.surfaceText
            width: parent.width - 280
            elide: Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter
            maximumLineCount: 1
            clip: true
        }

        StyledText {
            text: listDelegateRoot.fileIsDir ? "" : formatFileSize(listDelegateRoot.fileSize)
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceTextMedium
            width: 70
            horizontalAlignment: Text.AlignRight
            anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
            text: Qt.formatDateTime(listDelegateRoot.fileModified, "MMM d, yyyy h:mm AP")
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceTextMedium
            width: 140
            horizontalAlignment: Text.AlignRight
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: listMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            itemClicked(listDelegateRoot.index, listDelegateRoot.filePath, listDelegateRoot.fileName, listDelegateRoot.fileIsDir)
        }
    }
}
