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

for( int i = 0; i < 3; i++ )
  if( i == 0 )
    for( int j = 0; j < CHANNELS_AMOUNT; j++ )
      begin
        highest_priority[j] = mem[DMA_CCR_CR][DMA_CCR_CR_PL1:DMA_CCR_CR_PL0] == 2'b11;
        high_priority[j]    = mem[DMA_CCR_CR][DMA_CCR_CR_PL1:DMA_CCR_CR_PL0] == 2'b10;
        low_priority[j]     = mem[DMA_CCR_CR][DMA_CCR_CR_PL1:DMA_CCR_CR_PL0] == 2'b01;
        lowest_priority[j]  = mem[DMA_CCR_CR][DMA_CCR_CR_PL1:DMA_CCR_CR_PL0] == 2'b00;
      end

always_ff @( posedge clk_i )
  if( |request_i )
    req_valid_o <= 1'b1;
  else
    if( ready_i )
      req_valid_o <= 1'b0;

function automatic logic [CHANNEL_CNT_W-1:0] priority_channel_num_func(
  input logic [1:0] channel_prior [CHANNELS_AMOUNT-1:0]
);
  for( logic [1:0] prior_level = 2'b11; prior_level >= 2'b00; prior_level-- )
    for( int channel_num = 0; channel_num < CHANNELS_AMOUNT; channel_num++ )
      if( ( channel_prior[i] == prior_level ) && request_i[i] && channel_en[i] )
        return i;
  return 0;
endfunction : priority_channel_num_func

