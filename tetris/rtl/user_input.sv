`include "defs.vh"

module user_input(
  input               rst_i,
  
  input               key_clk_i,
  input [63:0]        key_i,
  input               key_en_i,

  input               main_logic_clk_i,

  input               user_event_rd_req_i,
  output user_event_t user_event_o,
  output              user_event_ready_o

);

logic key_en_d1;
logic key_en_d2;
logic key_en_d3;
logic key_en_stb;

always_ff @( posedge key_clk_i )
  begin
    key_en_d1 <= key_en_i;
    key_en_d2 <= key_en_d1;
    key_en_d3 <= key_en_d2;
  end

assign key_en_stb = key_en_d2 && !key_en_d3;

user_event_t wr_event;
logic        wr_event_val;

`define KEY_DOWN  33
`define KEY_LEFT  40
`define KEY_RIGHT 42
`define KEY_UP    41
`define KEY_F4    58

always_comb
  begin
    wr_event     = EV_DOWN;
    wr_event_val = 1'b0;
    
    if( key_i[`KEY_DOWN] )
      begin
        wr_event = EV_DOWN;
        wr_event_val = 1'b1;
      end

    if( key_i[`KEY_UP] )
      begin
        wr_event = EV_ROTATE;
        wr_event_val = 1'b1;
      end
    
    if( key_i[`KEY_LEFT] )
      begin
        wr_event = EV_LEFT;
        wr_event_val = 1'b1;
      end
    
    if( key_i[`KEY_RIGHT] )
      begin
        wr_event = EV_RIGHT;
        wr_event_val = 1'b1;
      end
    
    if( key_i[`KEY_F4] )
      begin
        wr_event = EV_NEW_GAME;
        wr_event_val = 1'b1;
      end

  end

logic fifo_wr_req;
logic fifo_empty;
logic fifo_full;

assign fifo_wr_req = wr_event_val && key_en_stb && ( !fifo_full ); 

user_input_fifo 
#( 
  .DWIDTH                                 ( $bits( wr_event )   )
) user_input_fifo (
  .aclr                                   ( rst_i               ),
  
  .wrclk                                  ( key_clk_i          ),
  .wrreq                                  ( fifo_wr_req         ),
  .data                                   ( wr_event            ),

  .rdclk                                  ( main_logic_clk_i    ),
  .rdreq                                  ( user_event_rd_req_i ),
  .q                                      ( user_event_o        ),

  .rdempty                                ( fifo_empty          ),
  .wrfull                                 ( fifo_full           )
);

assign user_event_ready_o = !fifo_empty;

endmodule
