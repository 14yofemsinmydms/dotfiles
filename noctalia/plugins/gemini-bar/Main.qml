import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
    id: root
    property var pluginApi: null

    // ─── Chat State ─────────────────────────────────────────
    property var messages: []           // [{role, parts, timestamp}]
    property int messagesRevision: 0
    property bool isLoading: false
    property string errorMessage: ""

    // ─── Model Selection ────────────────────────────────────
    property var availableModels: [
        {name: "gemini-3.6-flash", displayName: "Gemini 3.6 Flash"},
        {name: "gemini-3.5-flash", displayName: "Gemini 3.5 Flash"},
        {name: "gemini-3.5-flash-lite", displayName: "Gemini 3.5 Flash Lite"},
        {name: "gemini-3.1-pro", displayName: "Gemini 3.1 Pro"},
        {name: "gemini-3.1-flash-lite", displayName: "Gemini 3.1 Flash Lite"}
    ]
    property int modelsRevision: 0
    property string selectedModel: pluginApi?.pluginSettings?.model ?? "gemini-3.6-flash"

    // ─── File Attachments ───────────────────────────────────
    property var pendingAttachments: [] // [{path, mimeType, name, base64, fileUri, uploading}]
    property int attachmentsRevision: 0

    // ─── Persistence ────────────────────────────────────────
    property string chatDirPath: "/home/lwk3yhighoncaffeine/.local/share/noctalia/gemini-bar/chats"
    property string currentChatId: "default"
    property string historyPath: root.chatDirPath + "/" + root.currentChatId + ".json"
    property var chatSessions: [{key: "default", name: "New Chat"}]
    property int sessionsRevision: 0
    
    Process {
        id: listChatsProc
        command: ["bash", "-c", 
            "mkdir -p " + root.chatDirPath + " && " +
            "for f in " + root.chatDirPath + "/*.json; do " +
            "  [ -e \"$f\" ] || continue; " +
            "  id=$(basename \"$f\" .json); " +
            "  name=$(jq -r '.name // empty' \"$f\"); " +
            "  if [ -z \"$name\" ]; then name=\"Chat ${id:0:6}\"; fi; " +
            "  echo \"$id|$name\"; " +
            "done | sort -r"
        ]
        stdout: StdioCollector {}
        onExited: exitCode => {
            if (exitCode === 0) {
                const lines = String(stdout.text).trim().split('\n').filter(x => x.length > 0);
                let sessions = lines.map(line => {
                    const parts = line.split('|');
                    const id = parts[0];
                    let name = parts.slice(1).join('|');
                    if (id === "default" && name.startsWith("Chat ")) name = "New Chat";
                    return { key: id, name: name };
                });
                // Ensure 'default' (New Chat) is always in the list if not present or if we need a blank slate
                if (!sessions.find(s => s.key === "default")) {
                    sessions.unshift({ key: "default", name: "New Chat" });
                }
                root.chatSessions = sessions;
                root.sessionsRevision++;
            }
        }
    }
    
    function refreshSessions() {
        listChatsProc.running = true;
    }
    
    Component.onCompleted: {
        refreshSessions();
    }
    
    property string modelPrefPath: "/home/lwk3yhighoncaffeine/.local/share/noctalia/gemini-bar/model.json"

    // ─── API Config ─────────────────────────────────────────
    readonly property string apiKey: pluginApi?.pluginSettings?.apiKey ?? ""
    readonly property string systemPrompt:
        pluginApi?.pluginSettings?.systemPrompt ?? ""
    readonly property bool hasApiKey: root.apiKey.length > 0

    // ═══════════════════════════════════════════════════════
    // Fetch available models from the API
    // ═══════════════════════════════════════════════════════
    function fetchModels() {
        // Disabled dynamic fetching; using static supported models
    }

    // ═══════════════════════════════════════════════════════
    // Send message with optional file attachments
    // ═══════════════════════════════════════════════════════
    function sendMessage(text) {
        if (root.isLoading || !root.hasApiKey) return;
        if (!text && root.pendingAttachments.length === 0) return;

        // Build user message parts
        const userParts = [];
        if (text) userParts.push({ text: text });

        // Attach files as inlineData (base64) or fileData (uploaded URI)
        for (let i = 0; i < root.pendingAttachments.length; i++) {
            const att = root.pendingAttachments[i];
            if (att.fileUri) {
                userParts.push({
                    fileData: { mimeType: att.mimeType, fileUri: att.fileUri }
                });
            } else if (att.base64) {
                userParts.push({
                    inlineData: { mimeType: att.mimeType, data: att.base64 }
                });
            }
        }

        // If this is the first message in the default chat, give it a new ID and name
        if (root.messages.length === 0 && root.currentChatId === "default") {
            const promptText = userParts.find(p => p.text)?.text || "New Chat";
            root.currentChatId = "chat_" + new Date().getTime();
            root.currentChatName = promptText.substring(0, 30) + (promptText.length > 30 ? "..." : "");
        }

        const userMsg = {
            role: "user",
            parts: userParts,
            timestamp: new Date().toISOString(),
            // Store attachment metadata for display (not sent to API)
            _attachments: root.pendingAttachments.map(a => ({
                name: a.name, mimeType: a.mimeType, path: a.path
            }))
        };
        root.messages = [...root.messages, userMsg];
        root.pendingAttachments = [];
        root.attachmentsRevision++;
        root.messagesRevision++;
        root.isLoading = true;
        root.errorMessage = "";

        // Build API request contents (full conversation history)
        const contents = root.messages.map(m => ({
            role: m.role === "model" ? "model" : "user",
            parts: m.parts
        }));

        const body = {};
        if (root.systemPrompt) {
            body.system_instruction = { parts: [{ text: root.systemPrompt }] };
        }
        body.contents = contents;
        body.generationConfig = { temperature: 0.7 };

        // Request image output if model supports it
        const modelName = root.selectedModel;
        if (modelName.includes("image") || modelName.includes("imagen")) {
            body.generationConfig.responseModalities = ["TEXT", "IMAGE"];
        }

        const xhr = new XMLHttpRequest();
        const url = "https://generativelanguage.googleapis.com/v1beta/models/"
                  + modelName + ":generateContent?key=" + root.apiKey;
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            root.isLoading = false;
            if (xhr.status === 200) {
                try {
                    const data = JSON.parse(xhr.responseText);
                    const candidate = data.candidates?.[0]?.content;
                    if (candidate) {
                        const assistantMsg = {
                            role: "model",
                            parts: candidate.parts || [],
                            timestamp: new Date().toISOString(),
                            _images: []  // populated below
                        };
                        // Extract any generated images from response
                        for (let p = 0; p < (candidate.parts || []).length; p++) {
                            const part = candidate.parts[p];
                            if (part.inlineData?.data) {
                                const ext = part.inlineData.mimeType === "image/jpeg"
                                    ? ".jpg" : ".png";
                                const imgPath = "/tmp/gemini-bar-"
                                    + Date.now() + "-" + p + ext;
                                root._saveBase64ToFile(
                                    part.inlineData.data, imgPath);
                                assistantMsg._images.push(
                                    "file://" + imgPath);
                            }
                        }
                        root.messages = [...root.messages, assistantMsg];
                        root.messagesRevision++;
                        root.saveHistory();
                    }
                } catch (e) {
                    root.errorMessage = "Failed to parse response";
                    root.messagesRevision++;
                }
            } else {
                try {
                    const err = JSON.parse(xhr.responseText);
                    root.errorMessage = err.error?.message
                        || ("API error " + xhr.status);
                } catch (_) {
                    root.errorMessage = "API error " + xhr.status;
                }
                root.messagesRevision++;
            }
        };
        xhr.open("POST", url);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.send(JSON.stringify(body));
    }

    // ═══════════════════════════════════════════════════════
    // File attachment: base64 encode via Process
    // ═══════════════════════════════════════════════════════
    function addAttachment(filePath) {
        // Detect MIME type and base64 encode
        encodeProc.command = ["bash", "-c",
            'mime=$(file -b --mime-type "$1"); ' +
            'b64=$(base64 -w0 "$1"); ' +
            'printf "%s\\n%s" "$mime" "$b64"',
            "--", filePath];
        encodeProc._pendingPath = filePath;
        encodeProc.running = true;
    }

    Process {
        id: encodeProc
        property string _pendingPath: ""
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: exitCode => {
            if (exitCode === 0 && encodeProc._pendingPath) {
                const output = String(encodeProc.stdout.text).trim();
                const newline = output.indexOf("\n");
                if (newline > 0) {
                    const mime = output.substring(0, newline);
                    const b64 = output.substring(newline + 1);
                    const name = encodeProc._pendingPath
                        .split("/").pop();
                    root.pendingAttachments = [
                        ...root.pendingAttachments,
                        {
                            path: encodeProc._pendingPath,
                            mimeType: mime,
                            name: name,
                            base64: b64,
                            fileUri: "",
                            uploading: false
                        }
                    ];
                    root.attachmentsRevision++;
                }
            }
            encodeProc._pendingPath = "";
        }
    }

    // Save base64 data to file (for image output)
    Process {
        id: saveImageProc
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    function _saveBase64ToFile(base64Data, path) {
        saveImageProc.command = ["bash", "-c",
            'printf "%s" "$1" | base64 -d > "$2"',
            "--", base64Data, path];
        saveImageProc.running = true;
    }

    // ═══════════════════════════════════════════════════════
    // IPC Handler for keybinding
    // ═══════════════════════════════════════════════════════
    IpcHandler {
        target: "plugin:gemini-bar"
        function toggle() {
            root.pluginApi?.withCurrentScreen(screen => {
                root.pluginApi?.togglePanel(screen);
            });
        }
        function add_screenshot() {
            root.addAttachment(root.screenshotPath);
        }
    }

    function deleteCurrentChat() {
        if (root.currentChatId === "default") return;
        
        // Remove file
        deleteProc.command = ["bash", "-c", 'rm -f "$1"', "--", root._home + "/.local/share/noctalia/gemini-bar/chats/" + root.currentChatId + ".json"];
        deleteProc.running = true;
        
        // Remove from memory
        root.chatSessions = root.chatSessions.filter(s => s.key !== root.currentChatId);
        
        // Switch to default
        root.clearChat();
    }
    
    Process {
        id: deleteProc
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    // ═══════════════════════════════════════════════════════
    // IPC Handler
    // ═══════════════════════════════════════════════════════
    property string currentChatName: "New Chat"

    function clearChat() {
        if (root.messages.length === 0) return; // Don't create new if already empty
        root.messages = [];
        root.pendingAttachments = [];
        root.attachmentsRevision++;
        root.messagesRevision++;
        root.errorMessage = "";
        
        root.currentChatId = "default";
        root.currentChatName = "New Chat";
        root.refreshSessions();
    }
    
    function loadChat(chatId) {
        if (root.currentChatId === chatId) return;
        root.currentChatId = chatId;
        root.messages = [];
        root.messagesRevision++;
        // update currentChatName from sessions list
        const session = root.chatSessions.find(s => s.key === chatId);
        if (session) root.currentChatName = session.name;
    }

    function removeAttachment(index) {
        root.pendingAttachments = root.pendingAttachments
            .filter((_, i) => i !== index);
        root.attachmentsRevision++;
    }

    // ─── Screenshot ─────────────────────────────────────────
    property string screenshotPath: "/tmp/gemini_screenshot.png"

    function takeScreenshot() {
        // Use bash to coordinate closing the panel, capturing, and reopening.
        // We use IPC to close it, slurp/grim to capture, and IPC to add the attachment and reopen.
        var cmd = ["bash", "-c", 
            "qs -c noctalia-shell ipc call plugin:gemini-bar toggle && " +
            "sleep 0.3 && " +
            "grim -g \"$(slurp)\" " + root.screenshotPath + " && " +
            "qs -c noctalia-shell ipc call plugin:gemini-bar add_screenshot && " +
            "qs -c noctalia-shell ipc call plugin:gemini-bar toggle"
        ];
        screenshotRunner.command = cmd;
        screenshotRunner.running = true;
    }

    Process {
        id: screenshotRunner
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    // Model selection persists to disk
    function setModel(modelName) {
        root.selectedModel = modelName;
        modelPrefWriteProc.command = ["bash", "-c",
            'printf "%s" "$1" > "$2"',
            "--", JSON.stringify({ model: modelName }),
            root.modelPrefPath];
        modelPrefWriteProc.running = true;
    }

    Process {
        id: modelPrefWriteProc
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    // ═══════════════════════════════════════════════════════
    // Persistence (FileView pattern from clipboard plugin)
    // ═══════════════════════════════════════════════════════
    Process {
        id: mkdirProc
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    Process {
        id: historyWriteProc
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    function saveHistory() {
        if (historyWriteProc.running) return;
        if (root.messages.length === 0 && root.currentChatId === "default") return; // Don't save empty default chat
        
        const clean = root.messages.map(m => ({
            role: m.role,
            parts: (m.parts || []).map(p => {
                if (p.inlineData) return { text: "[attachment]" };
                return p;
            }),
            timestamp: m.timestamp,
            _attachments: m._attachments || [],
            _images: m._images || []
        }));
        const payload = JSON.stringify({ name: root.currentChatName, messages: clean }, null, 2);
        historyWriteProc.command = ["bash", "-c",
            'printf "%s" "$1" > "$2"', "--", payload, root.historyPath];
        historyWriteProc.running = true;
    }

    FileView {
        id: historyFile
        path: root.historyPath
        watchChanges: false
        printErrors: false
        onLoaded: {
            try {
                const text = String(historyFile.text()).trim();
                if (text.length === 0) {
                    root.messages = [];
                    root.messagesRevision++;
                    return;
                }
                const data = JSON.parse(text);
                if (data && Array.isArray(data.messages)) {
                    root.messages = data.messages;
                    root.messagesRevision++;
                }
            } catch (e) {
                Logger.w("GeminiBar", "History parse failed:", e);
                root.messages = [];
                root.messagesRevision++;
            }
        }
    }

    FileView {
        id: modelPrefFile
        path: root.modelPrefPath
        watchChanges: false
        printErrors: false
        onLoaded: {
            try {
                const data = JSON.parse(String(modelPrefFile.text()));
                if (data?.model) root.selectedModel = data.model;
            } catch (_) {}
        }
    }

    // Bootstrap: create cache dir + fetch models on API key set
    onPluginApiChanged: {
        if (!pluginApi) return;
        mkdirProc.command = ["mkdir", "-p", root.dataDir];
        mkdirProc.running = true;
        if (root.hasApiKey) root.fetchModels();
    }
}
