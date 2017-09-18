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