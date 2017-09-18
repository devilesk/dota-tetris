var isChatActive = false;
var chatEnterKey = "enter";
var chatLeaveKey = "escape";

function ChatInput(key) {
    if (key === chatEnterKey) {
        isChatActive = true;
        $("#ChatInput").SetFocus();
    }
    else if (key === chatLeaveKey) {
        isChatActive = false;
        $.GetContextPanel().SetFocus();
    }
}

function ChatScrollUp() {
    $.DispatchEvent("ScrollUp", $("#ChatLinesWrapper"));
}

function ChatScrollDown() {
    $.DispatchEvent("ScrollDown", $("#ChatLinesWrapper"));
}

function ChatTextSubmitted() {
    $.Msg("chat submitted");
    if ($("#ChatInput").text != "") {
        GameEvents.SendCustomGameEventToServer("chat_message", {
            "message": $("#ChatInput").text,
            "playerID": currentPlayerId
        });
    }
    $("#ChatInput").text = "";
}

function ChatFocus() {
    isChatActive = true;
}

function ChatBlur() {
    isChatActive = false;
}

function ReceiveChatMessage(msg) {
    CreateChatMessagePanel(msg.message, parseInt(msg.playerID));
    $("#ChatLinesWrapper").ScrollToBottom();
}

function ParseMsg(msg) {
    if (msg.l_message) {
        return Object.keys(msg.l_message).sort().map(function (o) {
            var s = msg.l_message[o];
            return s.charAt(0) == "#" ? $.Localize(s) : s;
        }).join("");
    }
    else {
        return msg.message.charAt(0) == "#" ? $.Localize(msg.message) : msg.message;
    }
}

function ReceiveChatEvent(msg) {
    CreateChatEventPanel(ParseMsg(msg), parseInt(msg.playerID));
    $("#chat-message-container").ScrollToBottom();
}

function CreateChatMessagePanel(message, playerID) {
    var parentPanel = $("#ChatLinesPanel");
    var label = $.CreatePanel("Label", parentPanel, "");
    label.AddClass("ChatLine");
    label.html = true;
    label.hittest = false;    
    label.text = "<span class=\"PlayerColor" + playerID + "\">" + Players.GetPlayerName(playerID) + ": </span>" + message;
}

GameEvents.Subscribe("receive_chat_message", ReceiveChatMessage);
GameEvents.Subscribe("receive_chat_event", ReceiveChatEvent);
