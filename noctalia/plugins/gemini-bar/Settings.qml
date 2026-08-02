import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root
    spacing: Style.marginM
    property var pluginApi: null

    // Pending state (flushed on Apply)
    property string valueApiKey: pluginApi?.pluginSettings?.apiKey ?? ""
    property string valueModel: pluginApi?.pluginSettings?.model ?? "gemini-2.5-flash"
    property string valueSystemPrompt: pluginApi?.pluginSettings?.systemPrompt ?? ""
    property int valueMaxConversations: pluginApi?.pluginSettings?.maxConversations ?? 20

    // API Key (password-masked input)
    NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.apiKey")
        description: pluginApi?.tr("settings.apiKey-description")
        placeholderText: "AIza..."
        text: root.valueApiKey
        onTextChanged: root.valueApiKey = text
    }

    // Default model selector
    NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.defaultModel")
        description: pluginApi?.tr("settings.defaultModel-description")
        model: [
            { "key": "gemini-3.6-flash", "name": "Gemini 3.6 Flash" },
            { "key": "gemini-3.5-flash", "name": "Gemini 3.5 Flash" },
            { "key": "gemini-3.5-flash-lite", "name": "Gemini 3.5 Flash Lite" },
            { "key": "gemini-3.1-pro", "name": "Gemini 3.1 Pro" },
            { "key": "gemini-3.1-flash-lite", "name": "Gemini 3.1 Flash Lite" }
        ]
        currentKey: root.valueModel
        onSelected: key => { root.valueModel = key; }
    }

    // System prompt
    NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.systemPrompt")
        description: pluginApi?.tr("settings.systemPrompt-description")
        placeholderText: "You are a helpful assistant..."
        text: root.valueSystemPrompt
        onTextChanged: root.valueSystemPrompt = text
    }

    // Max conversations
    NSpinBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.maxConversations")
        from: 5
        to: 100
        stepSize: 5
        value: root.valueMaxConversations
        onValueChanged: root.valueMaxConversations = value
    }

    // Apply handler
    function saveSettings() {
        if (!pluginApi) return;
        pluginApi.pluginSettings.apiKey = root.valueApiKey;
        pluginApi.pluginSettings.model = root.valueModel;
        pluginApi.pluginSettings.systemPrompt = root.valueSystemPrompt;
        pluginApi.pluginSettings.maxConversations = root.valueMaxConversations;
        pluginApi.saveSettings();
        pluginApi.saveSettings();
        // Dynamic fetch disabled: pluginApi.mainInstance?.fetchModels();
    }
}
