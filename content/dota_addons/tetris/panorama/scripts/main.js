var DialogLibrary = GameUI.CustomUIConfig().DialogLibrary;

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
    $.RegisterKeyBind($.GetContextPanel(), "key_" + c, KeyPressHandler.bind(this, c));
});

function KeyPressHandler(key, e) {
    GameEvents.SendCustomGameEventToServer("key_press", {key:key});
    // ChatInput(key);
}

function UpdatePanelFocus() {
    if (!isChatActive) $.GetContextPanel().SetFocus();
    // if (isChatActive) $("#ChatInput").SetFocus();
    // $("#CustomChat").SetHasClass("Active", isChatActive);
    $.Schedule(0.01, UpdatePanelFocus);
}
UpdatePanelFocus();

function pad(num, size, ch) {
    ch = ch || "0";
    var s = num + "";
    while (s.length < size) s = ch + s;
    return s;
}

function formatTime(t) {
    if (t == null) return "00:00";
    if (t < 3600) {
        return " " + pad(Math.floor(t / 60), 2) + ":" + pad(Math.floor(t) % 60, 2);
    }
    else {
        return pad(Math.floor(t / 3600), 2) + ":" + pad(Math.floor((t % 3600) / 60), 2) + ":" + pad(Math.floor(t) % 60, 2);
    }
}

function Tetris(parentPanel, index) {
    var panel = $.CreatePanel("Panel", $("#center-container"), "");
    panel.BLoadLayoutSnippet("tetris");
    this.index = index;
    this.panel = panel;
    this.board = new Board(panel.FindChildTraverse("board"), 22, 10);
    this.pending = new Board(panel.FindChildTraverse("pending"), 15, 4);
    this.holding = new Board(panel.FindChildTraverse("holding"), 3, 4);
    CustomNetTables.SubscribeNetTableListener("grid_" + this.index, this.OnGridNetTableChange.bind(this));
    CustomNetTables.SubscribeNetTableListener("game_" + this.index, this.OnGameNetTableChange.bind(this));
    this.LoadGridNetTable();
    this.LoadGameNetTable();
}
Tetris.prototype.OnGridNetTableChange = function (tableName, key, data) {
    // $.Msg("OnGridNetTableChange", tableName, key, data);
    if (tableName !== "grid_" + this.index) return;
    var row = parseInt(key) - 1;
    for (var i = 1; i <= 10; i++) {
        var col = i - 1;
        var cell = this.board.get(row, col);
        var state = data[i];
        // $.Msg("OnGridNetTableChange cell", row, col, state[1], state[2]);
        cell.render(state[1], state[2]);
    }
}
Tetris.prototype.OnGameNetTableChange = function (tableName, key, data) {
    // $.Msg( "Table ", tableName, " changed: '", key, "' = ", data, " ", JSON.stringify(data).length);
    if (tableName !== "game_" + this.index) return;
    if (key === "pending") {
        this.pending.clear();
        for (var i = 1; i <= 5; i++) {
            var cells = data[i].cells;
            for (var j in cells) {
                var cell = this.pending.get(cells[j][1] - 1, cells[j][2] - 1);
                cell.render(Cell.OCCUPIED, data[i].t);
            }
        }
    }
    else if (key === "hold") {
        this.holding.clear();
        var cells = data.cells;
        for (var j in cells) {
            var cell = this.holding.get(cells[j][1] - 1, cells[j][2] - 1);
            cell.render(Cell.OCCUPIED, data.t);
        }
    }
    else if (key === "score") {
        $("#score").text = data.value;
    }
    else if (key === "level") {
        $("#level").text = data.value;
    }
    else if (key === "linesClearedTotal") {
        $("#lines-cleared").text = data.value;
    }
    else if (key === "time") {
        $("#time").text = formatTime(data.value);
    }
    else if (key === "gameMode") {
        $("#game-mode").text = $.Localize("#game_mode_" + data.value);
    }
}
Tetris.prototype.LoadGameNetTable = function () {
    // $.Msg("LoadGameNetTable");
    var table = CustomNetTables.GetAllTableValues("game_" + this.index);
    if (table) {
        var self = this;
        table.forEach(function (kv) {
            self.OnGameNetTableChange("game_" + self.index, kv.key, kv.value);
        });
    }
}
Tetris.prototype.LoadGridNetTable = function () {
    // $.Msg("LoadGridNetTable");
    var table = CustomNetTables.GetAllTableValues("grid_" + this.index);
    if (table) {
        var self = this;
        table.forEach(function (kv) {
            self.OnGridNetTableChange("grid_" + self.index, kv.key, kv.value);
        });
    }
}

$("#center-container").RemoveAndDeleteChildren();
new Tetris($("#center-container"), 1);
// new Tetris($("#center-container"), 2);

function NewGame(gameMode) {
    GameEvents.SendCustomGameEventToServer("new_game", {
        "gameMode": gameMode
    });
}

function NewGamePrompt() {
    new DialogLibrary.Dialog({
        parentPanel: DialogLibrary.contextPanel,
        id: "dialog-container",
        hittest: true,
        children: [{
            id: "contents-container",
            cssClasses: ["contents-container"],
            style: {
                width: 400
            },
            children: [
                {
                    cssClasses: ["control"],
                    id: "control-1",
                    children: [{
                        panelType: "Panel",
                        init: function() {
                        },
                        cssClasses: ["horizontal-center"],
                        children: [{
                            cssClasses: [],
                            panelType: "Label",
                            init: function() {
                                this.text($.Localize("game_mode_prompt"));
                            },
                            skipBindHandlers: true
                        }]
                    }]
                },
                {
                    cssClasses: ["control", "horizontal-center"],
                    id: "control-2",
                    children: [{
                        events: {
                            OnActivate: function() {
                                NewGame("MARATHON");
                                this.root.close();
                            },
                            OnTabForward: function() {
                                this.root.focusNextInput(this);
                            }
                        },
                        panelType: "Button",
                        init: function() {
                            this.root.controls.push(this);
                        },
                        cssClasses: ["btn"],
                        children: [{
                            cssClasses: [],
                            panelType: "Label",
                            init: function() {
                                this.text($.Localize("game_mode_MARATHON"));
                            },
                            skipBindHandlers: true
                        }]
                    }]
                },
                {
                    cssClasses: ["control", "horizontal-center"],
                    id: "control-3",
                    children: [{
                        events: {
                            OnActivate: function() {
                                NewGame("SPRINT");
                                this.root.close();
                            },
                            OnTabForward: function() {
                                this.root.focusNextInput(this);
                            }
                        },
                        panelType: "Button",
                        init: function() {
                            this.root.controls.push(this);
                        },
                        cssClasses: ["btn"],
                        children: [{
                            cssClasses: [],
                            panelType: "Label",
                            init: function() {
                                this.text($.Localize("game_mode_SPRINT"));
                            },
                            skipBindHandlers: true
                        }]
                    }]
                },
                {
                    cssClasses: ["control", "horizontal-center"],
                    id: "control-4",
                    children: [{
                        events: {
                            OnActivate: function() {
                                NewGame("ULTRA");
                                this.root.close();
                            },
                            OnTabForward: function() {
                                this.root.focusNextInput(this);
                            }
                        },
                        panelType: "Button",
                        init: function() {
                            this.root.controls.push(this);
                        },
                        cssClasses: ["btn"],
                        children: [{
                            cssClasses: [],
                            panelType: "Label",
                            init: function() {
                                this.text($.Localize("game_mode_ULTRA"));
                            },
                            skipBindHandlers: true
                        }]
                    }]
                },
                {
                    cssClasses: ["control", "horizontal-center"],
                    id: "control-4",
                    children: [{
                        events: {
                            OnActivate: function() {
                                this.root.close();
                            },
                            OnTabForward: function() {
                                this.root.focusNextInput(this);
                            }
                        },
                        panelType: "Button",
                        init: function() {
                            this.root.controls.push(this);
                        },
                        cssClasses: ["btn"],
                        children: [{
                            cssClasses: [],
                            panelType: "Label",
                            init: function() {
                                this.text($.Localize("cancel"));
                            },
                            skipBindHandlers: true
                        }]
                    }]
                }
            ]
        }]
    });
}