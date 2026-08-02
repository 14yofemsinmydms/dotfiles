import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
    id: root
    focus: true
    property var pluginApi: null

    // SmartPanel contract
    readonly property var geometryPlaceholder: mainContainer
    readonly property bool allowAttach: true
    property real contentPreferredWidth: 550 * Style.uiScaleRatio
    property var contentPreferredHeight: {
        const scale = Style.uiScaleRatio;
        
        if (!(pluginApi?.mainInstance?.hasApiKey ?? false)) {
            return Math.round(250 * scale); // Setup screen minimum height
        }
        
        // Chat screen
        const _rev = pluginApi?.mainInstance?.messagesRevision ?? 0;
        const msgCount = pluginApi?.mainInstance?.messages?.length ?? 0;
        
        // Ensure a proper rectangle size when empty (welcome state)
        if (msgCount === 0) {
            return Math.round(420 * scale);
        }
        
        const chrome = Math.round(180 * scale); // header + input padding
        const msgHeight = Math.min(msgCount * Math.round(100 * scale),
                                   Math.round(500 * scale));
        return Math.min(chrome + msgHeight,
                        Math.round(650 * scale));
    }
    property color panelBackgroundColor: Color.mSurface

    // Hide panel timer
    Timer {
        id: closePanelTimer
        interval: 50
        repeat: false
        onTriggered: {
            if (!root.pluginApi?.closePanel) return;
            var targetScreen = root.pluginApi.panelOpenScreen;
            root.pluginApi.closePanel(targetScreen);
        }
    }

    // Auto-scroll on new message
    Connections {
        target: pluginApi?.mainInstance
        function onMessagesRevisionChanged() {
            if (historyList.count > 0) {
                historyList.positionViewAtEnd();
            }
        }
    }

    // File picker for attachments
    NFilePicker {
        id: attachmentPicker
        title: pluginApi?.tr("panel.attach-file")
        onAccepted: files => {
            if (files && files.length > 0) {
                // files[0] is typically file://..., strip it for bash
                let path = files[0];
                if (path.startsWith("file://")) path = path.substring(7);
                pluginApi?.mainInstance?.addAttachment(path);
            }
        }
    }

    Item {
        id: mainContainer
        anchors.fill: parent
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            // ─── Setup Card (No API Key) ─────────────────────────────
            NBox {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !(pluginApi?.mainInstance?.hasApiKey ?? false)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Style.marginM
                    spacing: Style.marginM

                    Item { Layout.fillHeight: true }

                    NIcon {
                        icon: "sparkles"
                        pointSize: Style.baseWidgetSize * 1.5
                        color: Color.mPrimary
                        Layout.alignment: Qt.AlignHCenter
                    }

                    NText {
                        text: pluginApi?.tr("panel.setup-title")
                        pointSize: Style.fontSizeL
                        font.weight: Style.fontWeightBold
                        color: Color.mOnSurface
                        Layout.alignment: Qt.AlignHCenter
                    }

                    NText {
                        text: pluginApi?.tr("panel.setup-subtitle")
                        pointSize: Style.fontSizeS
                        color: Color.mOnSurfaceVariant
                        Layout.alignment: Qt.AlignHCenter
                    }

                    NText {
                        text: "<html><a href='https://aistudio.google.com/apikey'>" + pluginApi?.tr("panel.setup-link") + "</a></html>"
                        textFormat: Text.RichText
                        pointSize: Style.fontSizeS
                        color: Color.mPrimary
                        Layout.alignment: Qt.AlignHCenter
                        onLinkActivated: link => Qt.openUrlExternally(link)
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.NoButton
                            cursorShape: Qt.PointingHandCursor
                        }
                    }

                    NTextInput {
                        id: setupApiKeyInput
                        Layout.fillWidth: true
                        placeholderText: "AIza..."
                    }

                    NButton {
                        text: pluginApi?.tr("panel.setup-save")
                        Layout.alignment: Qt.AlignHCenter
                        onClicked: {
                            if (!pluginApi) return;
                            pluginApi.pluginSettings.apiKey = setupApiKeyInput.text;
                            pluginApi.saveSettings();
                            pluginApi.mainInstance?.fetchModels();
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            // ─── Main Chat Interface (Has API Key) ───────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: pluginApi?.mainInstance?.hasApiKey ?? false
                spacing: Style.marginM

                // Header
                NBox {
                    Layout.fillWidth: true
                    implicitHeight: headerLayout.implicitHeight + Style.marginM * 2
                    
                    RowLayout {
                        id: headerLayout
                        anchors.fill: parent
                        anchors.margins: Style.marginM
                        spacing: Style.marginM

                        NIcon {
                            icon: "sparkles"
                            pointSize: Style.fontSizeXL
                            color: Color.mPrimary
                        }

                        NText {
                            text: pluginApi?.tr("panel.title")
                            pointSize: Style.fontSizeL
                            font.weight: Style.fontWeightBold
                            color: Color.mOnSurface
                        }

                        Item { Layout.fillWidth: true }

                        // Chat Selector
                        NComboBox {
                            Layout.preferredWidth: Math.round(150 * Style.uiScaleRatio)
                            model: {
                                const _rev = pluginApi?.mainInstance?.sessionsRevision ?? 0;
                                const sessions = pluginApi?.mainInstance?.chatSessions ?? [];
                                if (sessions.length === 0) return [{ key: "default", name: "New Chat" }];
                                return sessions;
                            }
                            currentKey: pluginApi?.mainInstance?.currentChatId ?? "default"
                            onSelected: key => {
                                pluginApi?.mainInstance?.loadChat(key);
                            }
                        }

                        NIconButton {
                            icon: "trash"
                            tooltipText: pluginApi?.tr("panel.delete-chat") ?? "Delete Chat"
                            baseSize: Style.baseWidgetSize * 0.8
                            enabled: (pluginApi?.mainInstance?.currentChatId ?? "default") !== "default"
                            onClicked: {
                                pluginApi?.mainInstance?.deleteCurrentChat();
                            }
                        }

                        NIconButton {
                            icon: "message-plus"
                            tooltipText: pluginApi?.tr("panel.new-chat")
                            baseSize: Style.baseWidgetSize * 0.8
                            onClicked: pluginApi?.mainInstance?.clearChat()
                        }

                        NIconButton {
                            icon: "x"
                            baseSize: Style.baseWidgetSize * 0.8
                            onClicked: closePanelTimer.restart()
                        }
                    }
                }

                // Error Message
                NBox {
                    Layout.fillWidth: true
                    implicitHeight: errorLayout.implicitHeight + Style.marginS * 2
                    visible: (pluginApi?.mainInstance?.errorMessage ?? "").length > 0
                    color: Color.mErrorContainer
                    
                    RowLayout {
                        id: errorLayout
                        anchors.fill: parent
                        anchors.margins: Style.marginS
                        NIcon { icon: "alert-circle"; color: Color.mOnErrorContainer; pointSize: Style.fontSizeM }
                        NText {
                            Layout.fillWidth: true
                            text: pluginApi?.mainInstance?.errorMessage ?? ""
                            color: Color.mOnErrorContainer
                            pointSize: Style.fontSizeS
                            wrapMode: Text.Wrap
                        }
                    }
                }

                // Welcome / Empty State
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: (pluginApi?.mainInstance?.messages?.length ?? 0) === 0
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Style.marginM
                        
                        NIcon {
                            icon: "message-chatbot"
                            pointSize: Style.baseWidgetSize
                            color: Color.mOnSurfaceVariant
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        NText {
                            text: pluginApi?.tr("panel.welcome")
                            pointSize: Style.fontSizeL
                            color: Color.mOnSurfaceVariant
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        NText {
                            text: pluginApi?.tr("panel.welcome-subtitle")
                            pointSize: Style.fontSizeS
                            color: Color.mOnSurfaceVariant
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
                

                ListView {
                    id: historyList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: (pluginApi?.mainInstance?.messages?.length ?? 0) > 0
                    clip: true
                    spacing: Style.marginM
                    
                    model: {
                        const _rev = pluginApi?.mainInstance?.messagesRevision ?? 0;
                        const msgs = pluginApi?.mainInstance?.messages ?? [];
                        // If loading, append a fake message to render the loading dots
                        if (pluginApi?.mainInstance?.isLoading) {
                            return [...msgs, { role: "model", isLoading: true }];
                        }
                        return msgs;
                    }

                    delegate: ChatMessage {
                        width: historyList.width
                        pluginApi: root.pluginApi
                        role: modelData.role ?? "model"
                        parts: modelData.parts ?? []
                        attachments: modelData._attachments ?? []
                        images: modelData._images ?? []
                        isLoading: modelData.isLoading ?? false
                    }

                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                }

                // Input Area
                NBox {
                    Layout.fillWidth: true
                    implicitHeight: inputLayout.implicitHeight + Style.marginL * 2
                    radius: Style.radiusL
                    color: Color.mSurfaceVariant
                    
                    ColumnLayout {
                        id: inputLayout
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Style.marginS
                        spacing: Style.marginS

                        // Model Selector at the top of the input pill
                        RowLayout {
                            Layout.fillWidth: true
                            visible: pluginApi?.mainInstance?.hasApiKey ?? false
                            
                            Item { Layout.fillWidth: true } // spacer to right-align
                            
                            NComboBox {
                                Layout.preferredWidth: Math.round(150 * Style.uiScaleRatio)
                                model: {
                                    const _rev = pluginApi?.mainInstance?.modelsRevision ?? 0;
                                    const models = pluginApi?.mainInstance?.availableModels ?? [];
                                    if (models.length === 0) {
                                        return [{ key: pluginApi?.mainInstance?.selectedModel ?? "gemini-3.6-flash", name: pluginApi?.mainInstance?.selectedModel ?? "gemini-3.6-flash" }];
                                    }
                                    return models.map(m => ({ key: m.name, name: m.displayName }));
                                }
                                currentKey: pluginApi?.mainInstance?.selectedModel ?? "gemini-3.6-flash"
                                onSelected: key => {
                                    pluginApi?.mainInstance?.setModel(key);
                                }
                            }
                        }

                        // Attachment Preview Area inside the pill
                        Flow {
                            Layout.fillWidth: true
                            spacing: Style.marginXS
                            visible: (pluginApi?.mainInstance?.pendingAttachments?.length ?? 0) > 0
                            
                            Repeater {
                                model: {
                                    const _rev = pluginApi?.mainInstance?.attachmentsRevision ?? 0;
                                    return pluginApi?.mainInstance?.pendingAttachments ?? [];
                                }
                                
                                AttachmentChip {
                                    name: modelData.name
                                    mimeType: modelData.mimeType
                                    removable: true
                                    onRemoveClicked: pluginApi?.mainInstance?.removeAttachment(index)
                                }
                            }
                        }

                        // The input row
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.margins: Style.marginM
                            spacing: Style.marginS

                            NIconButton {
                                icon: "paperclip"
                                tooltipText: pluginApi?.tr("panel.attach-file")
                                baseSize: Style.baseWidgetSize * 0.9
                                onClicked: attachmentPicker.open()
                            }

                            NIconButton {
                                icon: "crop"
                                tooltipText: pluginApi?.tr("panel.attach-screenshot")
                                baseSize: Style.baseWidgetSize * 0.9
                                onClicked: {
                                    pluginApi?.mainInstance?.takeScreenshot();
                                }
                            }

                            NTextInput {
                                id: chatInput
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                placeholderText: pluginApi?.tr("panel.input-placeholder")
                                enabled: !(pluginApi?.mainInstance?.isLoading ?? false)
                                
                                Keys.onReturnPressed: event => {
                                    if (event.modifiers & Qt.ShiftModifier) {
                                        // Let NTextInput handle Shift+Enter for newlines if it supports it
                                        // Otherwise just accept.
                                    } else {
                                        if (chatInput.text.trim().length > 0 || (pluginApi?.mainInstance?.pendingAttachments?.length ?? 0) > 0) {
                                            pluginApi?.mainInstance?.sendMessage(chatInput.text.trim());
                                            chatInput.text = "";
                                        }
                                        event.accepted = true;
                                    }
                                }
                                
                                Keys.onEnterPressed: event => {
                                    if (!(event.modifiers & Qt.ShiftModifier)) {
                                        if (chatInput.text.trim().length > 0 || (pluginApi?.mainInstance?.pendingAttachments?.length ?? 0) > 0) {
                                            pluginApi?.mainInstance?.sendMessage(chatInput.text.trim());
                                            chatInput.text = "";
                                        }
                                        event.accepted = true;
                                    }
                                }
                            }

                        NIconButton {
                            icon: "send"
                            baseSize: Style.baseWidgetSize * 0.9
                            colorBg: Color.mPrimary
                            colorFg: Color.mOnPrimary
                            colorBgHover: Color.mPrimaryContainer
                            colorFgHover: Color.mOnPrimaryContainer
                            enabled: (chatInput.text.trim().length > 0 || (pluginApi?.mainInstance?.pendingAttachments?.length ?? 0) > 0) && !(pluginApi?.mainInstance?.isLoading ?? false)
                            
                            onClicked: {
                                pluginApi?.mainInstance?.sendMessage(chatInput.text.trim());
                                chatInput.text = "";
                            }
                        }
                    }
                }
            }
        }
    }
}
}
