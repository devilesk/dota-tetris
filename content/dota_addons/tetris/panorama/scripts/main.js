GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_TIMEOFDAY, false);
GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_HEROES, false);
GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_FLYOUT_SCOREBOARD, false);
GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ACTION_PANEL, false);
GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ACTION_MINIMAP, false);
GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_PANEL, false);
GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_SHOP, false);
GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_MENU_BUTTONS, false);
GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_BAR_BACKGROUND, false);

keys = "abcdefghijklmnopqrstuvwxyz1234567890".split("");
keys = keys.concat(["up","down","left","right","lshift","rshift","tab","backspace","lcontrol","rcontrol","lalt","ralt","slash","enter","backquote","backslash","space","escape","period","lbracket","rbracket","minus","equal","semicolon","apostrophe","comma","home","home","insert","delete","pageup","pagedown","end","f1","f2","f3","f4","f5","f6","f7","f8","f9","f10","f11","f12","capslock","numlock","pad_0","pad_1","pad_2","pad_3","pad_4","pad_5","pad_6","pad_7","pad_8","pad_9","pad_divide","pad_multiply","pad_enter","pad_decimal","pad_minus","pad_plus","lwin","rwin","break","scrolllock"]);
keys.forEach(function (c) {
    $.RegisterKeyBind($.GetContextPanel(), "key_" + c, keyPressHandler.bind(this, c));
});

function keyPressHandler(key, e) {
    $.Msg(key, " ", e);
    GameEvents.SendCustomGameEventToServer("key_press", {key:key});
    if (key === "enter") {
        chatActive = true;
        $.Msg("chat enter");
        $("#ChatInput").SetFocus();
    }
    else if (key === "escape") {
        chatActive = false;
        $.Msg("chat enter");
        $.GetContextPanel().SetFocus();
    }
}

var lastGhostCells = [];

function OnGameNetTableChange(tableName, key, data) {
    $.Msg( "Table ", tableName, " changed: '", key, "' = ", data, " ", JSON.stringify(data).length);
    if (tableName !== "game") return;
    if (key === "pending_1") {
        tetris.pending.clear();
        for (var i = 1; i <= 5; i++) {
            var cells = data[i].cells;
            for (var j in cells) {
                var cell = tetris.pending.get(cells[j][1] - 1, cells[j][2] - 1);
                cell.render(OCCUPIED, data[i].t);
            }
        }
    }
    else if (key === "ghost_1") {
        lastGhostCells.forEach(function (cell) {
            cell.clearGhost();
        });
        lastGhostCells.length = 0;
        for (var j in data) {
            var cell = tetris.board.get(data[j][1] - 1, data[j][2] - 1);
            $.Msg("RENDER GHOST", data[j][1] - 1, data[j][2] - 1);
            cell.render(GHOST);
            lastGhostCells.push(cell);
        }
    }
    else if (key === "hold_1") {
        tetris.holding.clear();
        var cells = data.cells;
        for (var j in cells) {
            var cell = tetris.holding.get(cells[j][1] - 1, cells[j][2] - 1);
            cell.render(OCCUPIED, data.t);
        }
    }
    else if (key === "score_1") {
        $("#score").text = data.value;
    }
    else if (key === "level_1") {
        $("#level").text = data.value;
    }
}

function LoadGameNetTable() {
    $.Msg("LoadGameNetTable");
    var table = CustomNetTables.GetAllTableValues("game");
    if (table) {
        table.forEach(function (kv) {
            OnGameNetTableChange("game", kv.key, kv.value);
        });
    }
}

function LoadGridNetTable() {
    $.Msg("LoadGridNetTable");
    var table = CustomNetTables.GetAllTableValues("grid_1");
    if (table) {
        table.forEach(function (kv) {
            OnGridNetTableChange("grid_1", kv.key, kv.value);
        });
    }
}

function OnGridNetTableChange(tableName, key, data) {
    // $.Msg( "Table ", tableName, " changed: '", key, "' = ", data, " ", JSON.stringify(data).length);
    if (tableName !== "grid_1") return;
    var row = parseInt(key) - 1;
    for (var i = 1; i <= 10; i++) {
        var col = i - 1;
        var cell = tetris.board.get(row, col);
        var state = data[i];
        cell.render(state[1], state[2]);
    }
}

function Tetris(parentPanel) {
    var panel = $.CreatePanel("Panel", $("#center-container"), "");
    panel.BLoadLayoutSnippet("tetris");
    
    this.panel = panel;
    this.board = new Board(panel.FindChildTraverse("board"), 22, 10);
    this.pending = new Board(panel.FindChildTraverse("pending"), 15, 4);
    this.holding = new Board(panel.FindChildTraverse("holding"), 3, 4);
}

$("#center-container").RemoveAndDeleteChildren();
var tetris = new Tetris($("#center-container"));

CustomNetTables.SubscribeNetTableListener("grid_1", OnGridNetTableChange);
CustomNetTables.SubscribeNetTableListener("game", OnGameNetTableChange);

LoadGridNetTable();
LoadGameNetTable();


