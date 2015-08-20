`include "./tetris/rtl/defs.vh"

`define XKEYW 3  // width of keyboard
`define YKEYW 8  // length of keyboard

`define KEY_CNT ( `YKEYW * `YKEYW ) 

module top(
  input        clk_25m_i,

  output [2:0] r_o,
  output [2:0] g_o,
  output [2:0] b_o,
  
  output       hs_o,
  output       vs_o,

  inout [`YKEYW-1:0] o_keyb_Y, // выходы на контакты клавиатуры объявлены BIDIR потому что должны быть open-drain
  input [`XKEYW-1:0] i_keyb_X  // входы с контактов клавиатуры должны быть подтянуты к VCC
);

logic vga_clk;

pll_c3 pll(
  .areset                                 ( ),
  .locked                                 ( ),
  .inclk0                                 ( clk_25m_i         ),
  .c0                                     ( vga_clk           )
);

logic [7:0] ps2_received_data_w;    
logic       ps2_received_data_en_w; 

/*
PS2_Controller ps2( 
  .CLOCK_50                               ( CLOCK_50                ),
  .reset                                  ( main_reset              ),

  // Bidirectionals
  .PS2_CLK                                ( PS2_CLK                 ),
  .PS2_DAT                                ( PS2_DAT                 ),

  .received_data                          ( ps2_received_data_w     ),
  .received_data_en                       ( ps2_received_data_en_w  )
);
*/

logic        user_event_rd_req_w;
user_event_t user_event_w;
logic        user_event_ready_w;

logic [`KEY_CNT-1:0] key_mask;
logic               key_int;

user_input user_input(
  .rst_i                                  ( main_reset              ),

  .key_clk_i                              ( clk_25m_i               ),
  .key_i                                  ( key_mask                ),
  .key_en_i                               ( key_int                 ),

  .main_logic_clk_i                       ( vga_clk                 ),

  .user_event_rd_req_i                    ( user_event_rd_req_w     ),
  .user_event_o                           ( user_event_w            ),
  .user_event_ready_o                     ( user_event_ready_w      )

);

game_data_t game_data_w;

main_game_logic main_logic(

  .clk_i                                  ( vga_clk             ),
  .rst_i                                  ( main_reset          ),

  .user_event_i                           ( user_event_w        ),
  .user_event_ready_i                     ( user_event_ready_w  ),
  .user_event_rd_req_o                    ( user_event_rd_req_w ),

  .game_data_o                            ( game_data_w         )

);

logic       vga_hs_w;
logic       vga_vs_w;
logic       vga_de_w;
logic [7:0] vga_r_w;
logic [7:0] vga_g_w;
logic [7:0] vga_b_w;

draw_tetris draw_tetris(

  .clk_vga_i                              ( vga_clk           ),

  .game_data_i                            ( game_data_w       ),
    
    // VGA interface
  .vga_hs_o                               ( vga_hs_w           ),
  .vga_vs_o                               ( vga_vs_w           ),
  .vga_de_o                               ( vga_de_w           ),
  .vga_r_o                                ( vga_r_w            ),
  .vga_g_o                                ( vga_g_w            ),
  .vga_b_o                                ( vga_b_w            )

);

assign r_o = ( vga_de_w ) ? vga_r_w[7:5] : ( '0 );
assign g_o = ( vga_de_w ) ? vga_g_w[7:5] : ( '0 );
assign b_o = ( vga_de_w ) ? vga_b_w[7:5] : ( '0 );

assign hs_o = vga_hs_w;
assign vs_o = vga_vs_w;



logic [`KEY_CNT-1:0] key_en;
logic [`KEY_CNT-1:0] key_oY;

logic clk_100hz;
logic [31:0] clk_100hz_cnt;

always_ff @( posedge clk_25m_i )
  if( clk_100hz_cnt == ( 25000000/200 - 1 ) )
    begin
      clk_100hz     <= ~clk_100hz;
      clk_100hz_cnt <= '0;
    end
  else
    begin
      clk_100hz_cnt <= clk_100hz_cnt + 1'd1;
    end

assign key_en = 64'h0707070707070707;

genvar g;
generate 
  for( g = 0; g < `YKEYW; g++ )
  begin : g_y
    OPNDRN( key_oY[g], o_keyb_Y[g] );
  end
endgenerate


keyb_ctrl #( 
  .WIDTH ( `YKEYW ) 
) kbd (
  .iClk                                   ( clk_100hz        ),
  .iX                                     ( i_keyb_X         ),
  .iIsrRdPulse                            ( user_event_rd_req_w ),
  .ikey_en                                ( key_en           ),

  .oY                                     ( key_oY           ),
  .oK                                     ( key_mask         ),
  .oInt                                   ( key_int          )
);

endmodule
