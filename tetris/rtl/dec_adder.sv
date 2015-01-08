module dec_adder
#( 
  parameter DIGIT_CNT = 4 
)
(
  input                             clk_i,

  input                             srst_i,

  input        [DIGIT_CNT-1:0][3:0] add_value_i,
  input                             add_en_i,

  output logic [DIGIT_CNT-1:0][3:0] value_o

);

logic [DIGIT_CNT-1:0][3:0] next_value;
logic [DIGIT_CNT-1:0][4:0] pre_next_value;
logic [DIGIT_CNT-1:0]      digit_overflow;

always_ff @( posedge clk_i )
  if( srst_i )
    value_o <= '0;
  else
    if( add_en_i ) 
      begin
        value_o <= next_value;
      end

always_comb
  begin
    for( int i = 0; i < DIGIT_CNT; i++ )
      begin
        if( i == 0 )
          begin
            pre_next_value[i] = value_o[i] + add_value_i[i]; 
          end
        else
          begin
            pre_next_value[i] = value_o[i] + add_value_i[i] + digit_overflow[i-1];
          end

        digit_overflow[i] = ( pre_next_value[i] >= 'd10 );
      end
  end

always_comb
  begin
    next_value = value_o;

    for( int i = 0; i < DIGIT_CNT; i++ )
      begin
        if( digit_overflow[i] )
          next_value[i] = pre_next_value[i] - 'd10; 
        else
          next_value[i] = pre_next_value[i];
      end
  end


endmodule
