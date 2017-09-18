var isChatActive = false;
var chatEnterKey = "enter";
var chatLeaveKey = "escape";

function Update() {
    if (!isChatActive) $.GetContextPanel().SetFocus();
    if (isChatActive) $("#ChatInput").SetFocus();
    $("#CustomChat").SetHasClass("Active", isChatActive);
    $.Schedule(0.01, Update);
}
Update();

function ChatInput(key) {
    if (key === chatEnterKey) {
        isChatActive = true;
        $.Msg("chat enter");
        $("#ChatInput").SetFocus();
    }
    else if (key === chatLeaveKey) {
        isChatActive = false;
        $.Msg("chat enter");
        $.GetContextPanel().SetFocus();
    }
}

function ChatScrollUp() {
    $.Msg("ChatScrollUp");
    $.DispatchEvent("ScrollUp", $("#ChatLinesWrapper"));
}

function ChatScrollDown() {
    $.Msg("ChatScrollDown");
    $.DispatchEvent("ScrollDown", $("#ChatLinesWrapper"));
}

function ChatTextSubmitted() {
    $.Msg("chat submitted");
    $("#ChatInput").text = "";
}

function ChatFocus() {
    $.Msg("chat ChatFocus");
    isChatActive = true;
}

function ChatBlur() {
    $.Msg("chat ChatBlur");
    isChatActive = false;
}