import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Rectangle {
    id: chip
    property string name: ""
    property string mimeType: ""
    property bool removable: true

    signal removeClicked()

    implicitWidth: chipRow.implicitWidth + Style.margin2M
    implicitHeight: Math.round(Style.baseWidgetSize * 0.7)
    radius: Style.radiusM
    color: Color.mSurface
    border.color: Color.mOutline
    border.width: 1

    RowLayout {
        id: chipRow
        anchors.centerIn: parent
        spacing: Style.marginXS

        NIcon {
            icon: chip.mimeType.startsWith("image/") ? "photo"
                : chip.mimeType.startsWith("video/") ? "video"
                : chip.mimeType === "application/pdf" ? "file-type-pdf"
                : "file"
            pointSize: Style.fontSizeS
            color: Color.mOnSurfaceVariant
        }

        NText {
            text: chip.name.length > 20
                ? chip.name.substring(0, 17) + "..."
                : chip.name
            pointSize: Style.fontSizeXS
            color: Color.mOnSurfaceVariant
        }

        NIconButton {
            visible: chip.removable
            icon: "x"
            baseSize: Style.baseWidgetSize * 0.5
            onClicked: chip.removeClicked()
        }
    }
}
