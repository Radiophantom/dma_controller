module dma_controller_arb #(
  parameter CHANNELS_AMOUNT = 4,
  parameter CHANNEL_CNT_W   = $clog2( CHANNELS_AMOUNT ),
  parameter PIPELINE_EN     = 0
)(
  input                       rst_i,
  input                       clk_i,

  input                       request_i     [CHANNELS_AMOUNT-1:0],
  output                      acknowledge_o [CHANNELS_AMOUNT-1:0],

  output                      req_valid_o,
  output  [CHANNEL_CNT_W-1:0] req_num_o,
  
  input                       ready_i
);

import dma_controller_pkg::*;

logic [3:0] highest_priority [CHANNELS_AMOUNT-1:0];
logic [3:0] high_priority [CHANNELS_AMOUNT-1:0];
logic [3:0] low_priority [CHANNELS_AMOUNT-1:0];
logic [3:0] lowest_priority [CHANNELS_AMOUNT-1:0];

for( int i = 0; i < 3; i++ )
  if( i == 0 )
    for( int j = 0; j < CHANNELS_AMOUNT; j++ )
      begin
        highest_priority[j] = mem[DMA_CCR_CR][DMA_CCR_CR_PL1:DMA_CCR_CR_PL0] == 2'b11;
        high_priority[j]    = mem[DMA_CCR_CR][DMA_CCR_CR_PL1:DMA_CCR_CR_PL0] == 2'b10;
        low_priority[j]     = mem[DMA_CCR_CR][DMA_CCR_CR_PL1:DMA_CCR_CR_PL0] == 2'b01;
        lowest_priority[j]  = mem[DMA_CCR_CR][DMA_CCR_CR_PL1:DMA_CCR_CR_PL0] == 2'b00;
      end

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    state <= IDLE_S;
  else
    state <= next_state;

always_comb
  begin
    next_state = state;
    case( state )
      IDLE_S:
        begin
          if( |request_vec )
            next_state = ARB_CALC_S;
        end
      ARBITRATION_S:
        begin
          if( valid )
            next_state = ACK_S;
        end
      WAIT_S:
        begin
          if( ready_i )
            next_state = ACK_S;
        end
      ACK_S:
        begin
          if( ~request_vec[cur_channel] )
            next_state = IDLE_S;
        end
      default: next_state = IDLE_S;
    endcase
  end

generate
  if( PIPELINE_EN )
    begin
      always_ff @( posedge clk_i )
        request_vec <= request_i;
    end
  else
    begin
      assign request_vec = request_i;
    end
endgenerate

assign request_valid = |request_vec;

always_ff @( posedge clk_i )
  if( state == ARB_CALC_S && valid )
    cur_channel <= arb_channel;

// pack channel enable flags
always_comb
  for( int channel_num = 0; channel_num < CHANNELS_AMOUNT; channel_num++ )
    channel_en_vec[channel_num] = dma_cfg_if.channel_en[channel_num]; 
    channel_prior_vec[channel_num] = dma_cfg_if.channel_priority[channel_num];

generate
  if( PIPELINE_EN )
    begin

      always_ff @( posedge clk_i )
        valid_vec <= { valid_vec[2:0], state == IDLE_S && request_valid };

      always_ff @( posedge clk_i )
        for( logic [1:0] prior_level = 2'b00; prior_level <= 2'b11; prior_level++ )
          channel_winner[prior_level] <= prior_func( prior_level, channel_en );

      always_ff @( posedge clk_i )
        for( logic [1:0] prior_level = 2'b00; prior_level <= 2'b11; prior_level++ )
          channel_en[prior_level] <= channel_en[prior_level];

      always_ff @( posedge clk_i )
        for( logic [1:0] prior_level = 2'b00; prior_level <= 2'b11; prior_level++ )
          if( channel_en[prior_level] )
            channel_arb <= channel_winner[prior_level];

      always_ff @( posedge clk_i )
        channel_valid <= { channel_valid[0], state == IDLE_S && request_valid };

      always_ff @( posedge clk_i )
        if( channel_valid )
          channel_arb_valid <= 1'b1;
        else
          if( ready_i )
            channel_arb_valid <= 1'b0;

    end
  else
    begin

      always_ff @( posedge clk_i )
        valid_vec <= { valid_vec[2:0], state == IDLE_S && request_valid };

      always_ff @( posedge clk_i )
        for( logic [1:0] prior_level = 2'b00; prior_level <= 2'b11; prior_level++ )
          channel_winner[prior_level] <= prior_func( prior_level, channel_en );

      always_ff @( posedge clk_i )
        for( logic [1:0] prior_level = 2'b00; prior_level <= 2'b11; prior_level++ )
          channel_en[prior_level] <= channel_en[prior_level];

      always_ff @( posedge clk_i )
        for( logic [1:0] prior_level = 2'b00; prior_level <= 2'b11; prior_level++ )
          if( channel_en[prior_level] )
            channel_arb <= channel_winner[prior_level];

      always_ff @( posedge clk_i )
        channel_valid <= { channel_valid[0], state == IDLE_S && request_valid };

      always_ff @( posedge clk_i )
        if( channel_valid )
          channel_arb_valid <= 1'b1;
        else
          if( ready_i )
            channel_arb_valid <= 1'b0;
    end
endgenerate

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    acknowledge_o <= '0;
  else
    for( int channel_num = 0; channel_num < CHANNELS_AMOUNT; channel_num++ )
      acknowledge_o[channel_num] <= state == ACK_S && channel_num == cur_channel;

endmodule : dma_controller_arb

function automatic logic [CHANNEL_CNT_W-1:0] priority_channel_num_func(
  input logic [1:0] channel_prior [CHANNELS_AMOUNT-1:0]
);
  for( logic [1:0] prior_level = 2'b11; prior_level >= 2'b00; prior_level-- )
    for( int channel_num = 0; channel_num < CHANNELS_AMOUNT; channel_num++ )
      if( ( channel_prior[i] == prior_level ) && request_i[i] && channel_en[i] )
        return i;
  return 0;
endfunction : priority_channel_num_func

