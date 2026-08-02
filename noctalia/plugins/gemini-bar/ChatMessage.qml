import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
    id: msg
    property var pluginApi: null
    property string role: "user"        // "user" | "model"
    property var parts: []              // [{text}, {inlineData}]
    property var attachments: []        // [{name, mimeType, path}]
    property var images: []             // ["file:///tmp/gemini-bar-*.png"]
    property bool isLoading: false

    implicitHeight: bubble.implicitHeight + Style.marginS

    // Message bubble
    Rectangle {
        id: bubble
        anchors.right: msg.role === "user" ? parent.right : undefined
        anchors.left: msg.role === "model" ? parent.left : undefined
        width: Math.min(implicitWidth, parent.width * 0.85)
        implicitWidth: contentCol.implicitWidth + Style.margin2M
        implicitHeight: contentCol.implicitHeight + Style.margin2M
        radius: Style.radiusM

        // M3 Expressive: 2nd color (Secondary) for user, SurfaceVariant for model
        color: msg.role === "user"
            ? Color.mSecondary
            : Color.mSurfaceVariant

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginS

            // Attachment chips (user messages only)
            Flow {
                Layout.fillWidth: true
                spacing: Style.marginXS
                visible: msg.attachments.length > 0
                Repeater {
                    model: msg.attachments
                    AttachmentChip {
                        name: modelData.name
                        mimeType: modelData.mimeType
                        removable: false  // Already sent
                    }
                }
            }

            // Text content
            Repeater {
                model: msg.parts
                NText {
                    visible: modelData.text !== undefined
                             && modelData.text !== "[attachment]"
                    text: modelData.text ?? ""
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    pointSize: Style.fontSizeS
                    color: msg.role === "user"
                        ? Color.mOnSecondary
                        : Color.mOnSurfaceVariant
                }
            }

            // Generated images (model responses)
            Repeater {
                model: msg.images
                Image {
                    source: modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: Style.baseWidgetSize * 4
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: true
                    smooth: true

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.openUrlExternally(modelData)
                    }
                }
            }

            // Loading dots animation
            Row {
                visible: msg.isLoading
                spacing: Style.marginXS
                Repeater {
                    model: 3
                    Rectangle {
                        width: 8; height: 8
                        radius: 4
                        color: Color.mOnSurfaceVariant
                        SequentialAnimation on opacity {
                            running: msg.isLoading
                            loops: Animation.Infinite
                            PauseAnimation { duration: index * 200 }
                            NumberAnimation { to: 0.3; duration: 400 }
                            NumberAnimation { to: 1.0; duration: 400 }
                        }
                    }
                }
            }
        }
    }
}
