module uart_tx (
    data,
    divisor,
    clear,
    clock,
    start,
    tx,
    busy
);

    input [7:0] data;
    input [15:0] divisor;
    input clear;
    input clock;
    input start;
    output tx;
    output busy;

    wire [1:0] _21;
    wire _22;
    wire _23;
    wire [7:0] _29;
    wire [7:0] _3;
    wire [7:0] _42;
    wire [6:0] _38;
    wire [7:0] _39;
    wire [7:0] _40;
    wire _27;
    wire [7:0] _41;
    wire _25;
    wire [7:0] _43;
    wire [7:0] _4;
    reg [7:0] _30;
    wire _95;
    wire gnd;
    wire [1:0] _92;
    wire [1:0] _93;
    wire [1:0] _89;
    wire [1:0] _90;
    wire [1:0] _85;
    wire [2:0] _83;
    wire [2:0] _48;
    wire [2:0] _55;
    wire [2:0] _50;
    wire [2:0] _51;
    wire [2:0] _52;
    wire _46;
    wire [2:0] _53;
    wire _45;
    wire [2:0] _56;
    wire [2:0] _5;
    reg [2:0] _49;
    wire _84;
    wire [1:0] _86;
    wire [1:0] _87;
    wire [15:0] _34;
    wire [15:0] _7;
    wire [15:0] _35;
    wire vdd;
    wire [15:0] _32;
    wire _9;
    wire _11;
    wire _13;
    wire [15:0] _74;
    wire [15:0] _71;
    wire [15:0] _68;
    wire [15:0] _63;
    wire [15:0] _65;
    wire _61;
    wire [15:0] _66;
    wire _59;
    wire [15:0] _69;
    wire _58;
    wire [15:0] _72;
    wire _57;
    wire [15:0] _75;
    wire [15:0] _14;
    reg [15:0] _33;
    wire _36;
    wire [1:0] _81;
    wire _79;
    wire [1:0] _82;
    wire _78;
    wire [1:0] _88;
    wire _77;
    wire [1:0] _91;
    wire _76;
    wire [1:0] _94;
    wire [1:0] _15;
    reg [1:0] _20;
    reg _96;
    assign _21 = 2'b00;
    assign _22 = _20 == _21;
    assign _23 = ~ _22;
    assign _29 = 8'b00000000;
    assign _3 = data;
    assign _42 = _13 ? _3 : _30;
    assign _38 = _30[7:1];
    assign _39 = { gnd,
                   _38 };
    assign _40 = _36 ? _39 : _30;
    assign _27 = _20 == _89;
    assign _41 = _27 ? _40 : _30;
    assign _25 = _20 == _21;
    assign _43 = _25 ? _42 : _41;
    assign _4 = _43;
    always @(posedge _11) begin
        if (_9)
            _30 <= _29;
        else
            _30 <= _4;
    end
    assign _95 = _30[0:0];
    assign gnd = 1'b0;
    assign _92 = 2'b01;
    assign _93 = _13 ? _92 : _20;
    assign _89 = 2'b10;
    assign _90 = _36 ? _89 : _20;
    assign _85 = 2'b11;
    assign _83 = 3'b111;
    assign _48 = 3'b000;
    assign _55 = _36 ? _48 : _49;
    assign _50 = 3'b001;
    assign _51 = _49 + _50;
    assign _52 = _36 ? _51 : _49;
    assign _46 = _20 == _89;
    assign _53 = _46 ? _52 : _49;
    assign _45 = _20 == _92;
    assign _56 = _45 ? _55 : _53;
    assign _5 = _56;
    always @(posedge _11) begin
        if (_9)
            _49 <= _48;
        else
            _49 <= _5;
    end
    assign _84 = _49 == _83;
    assign _86 = _84 ? _85 : _20;
    assign _87 = _36 ? _86 : _20;
    assign _34 = 16'b0000000000000001;
    assign _7 = divisor;
    assign _35 = _7 - _34;
    assign vdd = 1'b1;
    assign _32 = 16'b0000000000000000;
    assign _9 = clear;
    assign _11 = clock;
    assign _13 = start;
    assign _74 = _13 ? _32 : _33;
    assign _71 = _36 ? _32 : _63;
    assign _68 = _36 ? _32 : _63;
    assign _63 = _33 + _34;
    assign _65 = _36 ? _32 : _63;
    assign _61 = _20 == _85;
    assign _66 = _61 ? _65 : _33;
    assign _59 = _20 == _89;
    assign _69 = _59 ? _68 : _66;
    assign _58 = _20 == _92;
    assign _72 = _58 ? _71 : _69;
    assign _57 = _20 == _21;
    assign _75 = _57 ? _74 : _72;
    assign _14 = _75;
    always @(posedge _11) begin
        if (_9)
            _33 <= _32;
        else
            _33 <= _14;
    end
    assign _36 = _33 == _35;
    assign _81 = _36 ? _21 : _20;
    assign _79 = _20 == _85;
    assign _82 = _79 ? _81 : _20;
    assign _78 = _20 == _89;
    assign _88 = _78 ? _87 : _82;
    assign _77 = _20 == _92;
    assign _91 = _77 ? _90 : _88;
    assign _76 = _20 == _21;
    assign _94 = _76 ? _93 : _91;
    assign _15 = _94;
    always @(posedge _11) begin
        if (_9)
            _20 <= _21;
        else
            _20 <= _15;
    end
    always @* begin
        case (_20)
        0:
            _96 <= vdd;
        1:
            _96 <= gnd;
        2:
            _96 <= _95;
        default:
            _96 <= vdd;
        endcase
    end
    assign tx = _96;
    assign busy = _23;

endmodule
