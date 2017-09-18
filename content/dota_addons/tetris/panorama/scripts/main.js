var TYPES = "IJLOSTZ".split("");
var INVALID = -1;
var EMPTY = 0;
var OCCUPIED = 1;
var LOCKED = 2;
var GHOST = 3;

/**
 * Returns a random integer between min (inclusive) and max (inclusive)
 * Using Math.round() will give you a non-uniform distribution!
 */
function getRandomInt(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}

function Board(panel, rows, columns) {
    this.panel = panel;
    this.rows = rows;
    this.columns = columns;
    this.cells = [];
    this.init();
}
Board.prototype.init = function () {
    this.panel.RemoveAndDeleteChildren();
    for (var r = 0; r < this.rows; r++) {
        var row = [];
        var rowPanel = $.CreatePanel("Panel", this.panel, "");
        rowPanel.AddClass("row");
        for (var c = 0; c < this.columns; c++) {
            var cell = new Cell(this, rowPanel, r, c);
            cell.render();
            row.push(cell);
        }
        this.cells.push(row);
    }
}
Board.prototype.clear = function (r, c) {
    this.cells.forEach(function (row) {
        row.forEach(function (cell) {
            cell.clear();
        });
    });
}
Board.prototype.get = function (r, c) {
    return this.cells[r][c];
}

function Cell(board, parentPanel, r, c) {
    this.board = board;
    this.row = r;
    this.col = c;
    this.panel = $.CreatePanel("Panel", parentPanel, this.row + "-" + this.col);
    this.panel.AddClass("cell");
}
Cell.prototype.clear = function () {
    var self = this;
    TYPES.forEach(function (t) {
        self.panel.SetHasClass(t, false);
    });
    this.panel.SetHasClass("locked", false);
    this.panel.SetHasClass("ghost", false);
}
Cell.prototype.clearGhost = function () {
    this.panel.SetHasClass("ghost", false);
}
Cell.prototype.render = function (state, type) {
    this.panel.SetHasClass("border", this.row < 2);
    this.panel.SetHasClass("locked", state === LOCKED);
    this.panel.SetHasClass("ghost", state === GHOST);
    var self = this;
    TYPES.forEach(function (t) {
        self.panel.SetHasClass(t, t === type);
    });
}
Cell.prototype.toString = function () {
    return "(" + this.row + "," + this.col + ")";
}

function Update() {
    $.GetContextPanel().SetFocus();
    $.Schedule(0.01, Update);
}
Update();

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
    // $.Msg("binding", c);
    // Game.CreateCustomKeyBind(c, "key_pressed_" + c);
    // Game.AddCommand("key_pressed_" + c, keyPressHandler.bind(this, c), "", 0 );
    $.RegisterKeyBind($.GetContextPanel(), "key_" + c, keyPressHandler.bind(this, c));
});

function keyPressHandler(key, e) {
    $.Msg(key, " ", e);
    GameEvents.SendCustomGameEventToServer("key_press", {key:key});
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


