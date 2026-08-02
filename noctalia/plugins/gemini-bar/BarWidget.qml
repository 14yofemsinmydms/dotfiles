import QtQuick
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

NIconButton {
    id: root
    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    icon: "sparkles"
    tooltipText: pluginApi?.tr("bar.tooltip")
    tooltipDirection: BarService.getTooltipDirection(screen?.name)
    baseSize: Style.getCapsuleHeightForScreen(screen?.name)
    applyUiScale: false
    customRadius: Style.radiusL

    colorBg: Style.capsuleColor
    colorFg: Color.mOnSurface
    colorBgHover: Color.mHover
    colorFgHover: Color.mOnHover
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    // Loading pulse animation
    SequentialAnimation on opacity {
        running: pluginApi?.mainInstance?.isLoading ?? false
        loops: Animation.Infinite
        NumberAnimation { to: 0.4; duration: 600; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
    }
    opacity: (pluginApi?.mainInstance?.isLoading ?? false) ? undefined : 1.0

    onClicked: {
        if (!pluginApi) return;
        const alreadyOpen = pluginApi.isPanelOpen?.(screen) === true;
        if (alreadyOpen && pluginApi.closePanel)
            pluginApi.closePanel(screen);
        else if (pluginApi.openPanel)
            pluginApi.openPanel(screen, root);
    }

    onRightClicked: PanelService.showContextMenu(contextMenu, root, screen)

    NPopupContextMenu {
        id: contextMenu
        model: [
            { "label": pluginApi?.tr("context.toggle"), "action": "toggle", "icon": "sparkles" },
            { "label": pluginApi?.tr("context.newChat"), "action": "new-chat", "icon": "message-plus" },
            { "label": pluginApi?.tr("context.settings"), "action": "open-settings", "icon": "settings" }
        ]
        onTriggered: action => {
            contextMenu.close();
            PanelService.closeContextMenu(screen);
            if (action === "toggle") {
                if (!pluginApi) return;
                const open = pluginApi.isPanelOpen?.(screen) === true;
                if (open && pluginApi.closePanel) pluginApi.closePanel(screen);
                else if (pluginApi.openPanel) pluginApi.openPanel(screen, root);
            } else if (action === "new-chat") {
                pluginApi?.mainInstance?.clearChat();
            } else if (action === "open-settings") {
                if (pluginApi?.manifest)
                    BarService.openPluginSettings(screen, pluginApi.manifest);
            }
        }
    }
}
