module tetris_stat(
  input                   clk_i,
  
  // sync reset - when starts new game
  input                   srst_i,
  
  input        [2:0]      disappear_lines_cnt_i,
  input                   update_stat_en_i,
  
  output logic [5:0][3:0] score_o,
  output logic [5:0][3:0] lines_o,
  output logic [5:0][3:0] level_o,

  output logic            level_changed_o

);

logic [3:0][3:0] score_hundred;
logic [2:0][3:0] lines_cnt;
logic [1:0][3:0] level_num;

logic [4:0][3:0][3:0] add_score_pos;

assign add_score_pos[0] = 'h0;
assign add_score_pos[1] = 'h0_0_0_1;
assign add_score_pos[2] = 'h0_0_0_3;
assign add_score_pos[3] = 'h0_0_0_7;
assign add_score_pos[4] = 'h0_0_1_5;


dec_adder
#( 
  .DIGIT_CNT                              ( 4                                    ) 
) dec_adder_score (

  .clk_i                                  ( clk_i                                ),
  .srst_i                                 ( srst_i                               ),

  .add_value_i                            ( add_score_pos[disappear_lines_cnt_i] ),
  .add_en_i                               ( update_stat_en_i                     ),

  .value_o                                ( score_hundred                        )

);

assign score_o = { score_hundred, 4'h0, 4'h0 };

logic [2:0][3:0] lines_add_value;

assign lines_add_value = { 4'h0, 4'h0, 1'b0, disappear_lines_cnt_i };

dec_adder
#( 
  .DIGIT_CNT                              ( 3                                    ) 
) dec_adder_lines (

  .clk_i                                  ( clk_i                                ),
  .srst_i                                 ( srst_i                               ),

  .add_value_i                            ( lines_add_value                      ),
  .add_en_i                               ( update_stat_en_i                     ),

  .value_o                                ( lines_cnt                            )

);

assign lines_o = { 4'h0, 4'h0, 4'h0, lines_cnt };

always_comb
  begin
    level_num = lines_cnt[2:1];

    level_num[0] = level_num[0] + 4'd1;

    if( level_num[0] == 'd10 )
      begin
        level_num[0] = 'd0;
        level_num[1] = level_num[1] + 'd1;
      end
  end

assign level_o = { 4'h0, 4'h0, 4'h0, 4'h0, level_num };

logic [3:0] level_num_0_d1;

always_ff @( posedge clk_i )
  if( srst_i )
    level_num_0_d1 <= 'd0;
  else
    level_num_0_d1 <= level_num[0];

assign level_changed_o = ( level_num_0_d1 != level_num[0] );

endmodule
