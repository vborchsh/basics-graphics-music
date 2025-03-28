`include "config.svh"
`include "lab_specific_config.svh"

module board_specific_top
# (
    parameter clk_mhz   = 50,
              w_key     = 4,
              w_sw      = 18,
              w_led     = 18,
              w_digit   = 8,
              w_gpio    = 36,        // GPIO[5:0] reserved for mic
              vga_clock = 25         // Pixel clock of VGA in MHz, recommend be equal with VGA_CLOCK from labs/common/vga.sv
)
(
    input                   CLOCK_50,

    input  [w_key    - 1:0] KEY,
    input  [w_sw     - 1:0] SW,
    output [w_led    - 1:0] LEDR,    // The last 8 LEDR are used like a 7SEG dp

    output logic [     6:0] HEX0,    // HEX[7] aka dp doesn't connected to FPGA at DE2-115
    output logic [     6:0] HEX1,
    output logic [     6:0] HEX2,
    output logic [     6:0] HEX3,
    output logic [     6:0] HEX4,
    output logic [     6:0] HEX5,
    output logic [     6:0] HEX6,
    output logic [     6:0] HEX7,

    output                  VGA_CLK, // VGA DAC input triggers CLK
    output                  VGA_HS,
    output                  VGA_VS,
    output [           7:0] VGA_R,
    output [           7:0] VGA_G,
    output [           7:0] VGA_B,
    output                  VGA_BLANK_N,
    output                  VGA_SYNC_N,

    inout  [w_gpio   - 1:0] GPIO
);

    //------------------------------------------------------------------------

    localparam w_top_sw = w_sw - 1;                // One sw is used as a reset

    wire                  clk     = CLOCK_50;
    wire                  rst     = SW [w_top_sw];
    wire [w_top_sw - 1:0] top_sw  = SW [w_top_sw - 1:0];
    wire [w_key    - 1:0] top_key = ~ KEY;

    //------------------------------------------------------------------------

    wire  [w_led - w_digit - 1:0] top_led;

    wire  [                  7:0] abcdefgh;
    wire  [        w_digit - 1:0] digit;

    wire  [                  3:0] vga_red_4b,vga_green_4b,vga_blue_4b;

    wire  [                 23:0] mic;

    //------------------------------------------------------------------------

    top
    # (
        .clk_mhz ( clk_mhz         ),
        .w_key   ( w_key           ),
        .w_sw    ( w_top_sw        ),
        .w_led   ( w_led - w_digit ),              // The last 8 LEDR are used like a 7SEG dp
        .w_digit ( w_digit         ),
        .w_gpio  ( w_gpio          )               // GPIO[5:0] reserved for mic
    )
    i_top
    (
        .clk      (   clk          ),
        .rst      (   rst          ),

        .key      (   top_key      ),
        .sw       (   top_sw       ),

        .led      (   top_led      ),

        .abcdefgh (   abcdefgh     ),
        .digit    (   digit        ),

        .vsync    (   VGA_VS       ),
        .hsync    (   VGA_HS       ),

        .red      (   vga_red_4b   ),
        .green    (   vga_green_4b ),
        .blue     (   vga_blue_4b  ),

        .mic      (   mic          ),
        .gpio     (   GPIO         )
    );

    //------------------------------------------------------------------------

    assign LEDR [w_led - w_digit - 1:0] = top_led; // The last 8 LEDR are used like a 7SEG dp

    assign VGA_R   = { vga_red_4b,   4'd0 };
    assign VGA_G   = { vga_green_4b, 4'd0 };
    assign VGA_B   = { vga_blue_4b,  4'd0 };

    assign VGA_BLANK_N = 1'b1;
    assign VGA_SYNC_N  = 0;

    // Divide VGA DAC clock from clk_mhz to vga_clock
    localparam CLK_DIV = $clog2 (clk_mhz / vga_clock) - 1;

    logic [CLK_DIV:0] clk_en_cnt;
    logic clk_en;

    always_ff @ (posedge clk or posedge rst)
    begin
        if (rst)
        begin
            clk_en_cnt <= 'b0;
            clk_en     <= 'b0;
        end
        else
        begin
            if (clk_en_cnt == (clk_mhz / vga_clock) - 1)
            begin
                clk_en_cnt <= 'b0;
                clk_en     <= 'b1;
            end
            else
            begin
                clk_en_cnt <= clk_en_cnt + 1;
                clk_en     <= 'b0;
            end
        end
    end

    assign VGA_CLK = clk_en;

    //------------------------------------------------------------------------

    wire  [$left (abcdefgh):0] hgfedcba;
    logic [$left    (digit):0] dp;

    generate
        genvar i;

        for (i = 0; i < $bits (abcdefgh); i ++)
        begin : abc
            assign hgfedcba [i] = abcdefgh [$left (abcdefgh) - i];
        end
    endgenerate

    //------------------------------------------------------------------------

    `ifdef EMULATE_DYNAMIC_7SEG_WITHOUT_STICKY_FLOPS

        // Pro: This implementation is necessary for the lab 7segment_word
        // to properly demonstrate the idea of dynamic 7-segment display
        // on a static 7-segment display.
        //

        // Con: This implementation makes the 7-segment LEDs dim
        // on most boards with the static 7-sigment display.

        // inverted logic

        assign HEX0 = digit [0] ? ~ hgfedcba [$left (HEX0):0] : '1;
        assign HEX1 = digit [1] ? ~ hgfedcba [$left (HEX1):0] : '1;
        assign HEX2 = digit [2] ? ~ hgfedcba [$left (HEX2):0] : '1;
        assign HEX3 = digit [3] ? ~ hgfedcba [$left (HEX3):0] : '1;
        assign HEX4 = digit [4] ? ~ hgfedcba [$left (HEX4):0] : '1;
        assign HEX5 = digit [5] ? ~ hgfedcba [$left (HEX5):0] : '1;
        assign HEX6 = digit [6] ? ~ hgfedcba [$left (HEX6):0] : '1;
        assign HEX7 = digit [7] ? ~ hgfedcba [$left (HEX7):0] : '1;

        // positive logic

        assign LEDR [    w_led - w_digit] = digit [0] ? hgfedcba [$left (HEX0) + 1] : '0;
        assign LEDR [w_led - w_digit + 1] = digit [1] ? hgfedcba [$left (HEX1) + 1] : '0;
        assign LEDR [w_led - w_digit + 2] = digit [2] ? hgfedcba [$left (HEX2) + 1] : '0;
        assign LEDR [w_led - w_digit + 3] = digit [3] ? hgfedcba [$left (HEX3) + 1] : '0;
        assign LEDR [w_led - w_digit + 4] = digit [4] ? hgfedcba [$left (HEX4) + 1] : '0;
        assign LEDR [w_led - w_digit + 5] = digit [5] ? hgfedcba [$left (HEX5) + 1] : '0;
        assign LEDR [w_led - w_digit + 6] = digit [6] ? hgfedcba [$left (HEX6) + 1] : '0;
        assign LEDR [w_led - w_digit + 7] = digit [7] ? hgfedcba [$left (HEX7) + 1] : '0;

    `else

        always_ff @ (posedge clk or posedge rst)
        begin
            if (rst)
            begin
                { HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7 } <= '1;
                dp <= '0;
            end
            else
            begin
                if (digit [0]) HEX0 <= ~ hgfedcba [$left (HEX0):0];
                if (digit [1]) HEX1 <= ~ hgfedcba [$left (HEX1):0];
                if (digit [2]) HEX2 <= ~ hgfedcba [$left (HEX2):0];
                if (digit [3]) HEX3 <= ~ hgfedcba [$left (HEX3):0];
                if (digit [4]) HEX4 <= ~ hgfedcba [$left (HEX4):0];
                if (digit [5]) HEX5 <= ~ hgfedcba [$left (HEX5):0];
                if (digit [6]) HEX6 <= ~ hgfedcba [$left (HEX6):0];
                if (digit [7]) HEX7 <= ~ hgfedcba [$left (HEX7):0];

                if (digit [0]) dp[0] <=  hgfedcba [$left (HEX0) + 1];
                if (digit [1]) dp[1] <=  hgfedcba [$left (HEX1) + 1];
                if (digit [2]) dp[2] <=  hgfedcba [$left (HEX2) + 1];
                if (digit [3]) dp[3] <=  hgfedcba [$left (HEX3) + 1];
                if (digit [4]) dp[4] <=  hgfedcba [$left (HEX4) + 1];
                if (digit [5]) dp[5] <=  hgfedcba [$left (HEX5) + 1];
                if (digit [6]) dp[6] <=  hgfedcba [$left (HEX6) + 1];
                if (digit [7]) dp[7] <=  hgfedcba [$left (HEX7) + 1];
            end
        end

        assign LEDR [w_led - 1:w_led - w_digit] = dp;  // The last 8 LEDR are used like a 7SEG dp

    `endif

    //------------------------------------------------------------------------

    inmp441_mic_i2s_receiver i_microphone
    (
        .clk   ( clk      ),
        .rst   ( rst      ),
        .lr    ( GPIO [0] ), // JP1 pin 1
        .ws    ( GPIO [2] ), // JP1 pin 3
        .sck   ( GPIO [4] ), // JP1 pin 5
        .sd    ( GPIO [5] ), // JP1 pin 6
        .value ( mic      )
    );

    assign GPIO [1] = 1'b0;  // GND - JP1 pin 2
    assign GPIO [3] = 1'b1;  // VCC - JP1 pin 4

endmodule
