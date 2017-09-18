var chatActive = false;

function Update() {
    if (!chatActive) $.GetContextPanel().SetFocus();
    if (chatActive) $("#ChatInput").SetFocus();
    $("#CustomChat").SetHasClass("Active", chatActive);
    $.Schedule(0.01, Update);
}
Update();

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
    chatActive = true;
}

function ChatBlur() {
    $.Msg("chat ChatBlur");
    chatActive = false;
}