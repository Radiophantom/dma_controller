module dma_controller_engine #(
  parameter int CHANNELS_AMOUNT = 1,
  parameter int DATA_W          = 64
)(
  input rst_i,
  input clk_i,

  input   request_i     [CHANNELS_AMOUNT-1:0],
  output  acknowledge_o [CHANNELS_AMOUNT-1:0],

  avalon_mm_if periph_channel [CHANNELS_AMOUNT-1:0],
  avalon_mm_if mem_channel    [CHANNELS_AMOUNT-1:0],

  dma_csr_if csr_if
);

dma_controller_arb #(
)    (

);


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
          if( arb_request_valid )
            next_state = READ_S;
        end
      READ_S:
        begin
          if( readdatavalid )
            next_state = WRITE_S;
        end
      WRITE_S:
        begin
          if( ~waitrequest )
            if( data_cnt != 0 )
              next_state = READ_S;
            else
              next_state = FINISH_S;
        end
      FINISH_S:
        begin
          next_state = IDLE_S;
        end
      default: next_state = IDLE_S;
    endcase
  end

always_ff @( posedge clk_i )
  if( state == IDLE_S && arb_request_valid )
    active_channel <= arb_request_channel;

always_ff @( posedge clk_i )
  dma_ready <= next_state == IDLE_S;

always_ff @( posedge clk_i )
  if( state == IDLE_S && arb_request_valid )
    data_cnt <= dma_cfg_if.cntd[arb_request_channel];
  else
    if( state == READ_S && readdatavalid )
      if( csr[DMA_CCR_CR][DMA_CCR_CR_DIR] )
        case( csr[DMA_CCR_CR][DMA_CCR_CR_MSIZE1:DMA_CCR_CR_MSIZE0] )
          2'b00: data_cnt[act_channel] <= data_cnt[act_channel] - 1'd1;
          2'b01: data_cnt[act_channel] <= data_cnt[act_channel] - 2'd2;
          2'b10: data_cnt[act_channel] <= data_cnt[act_channel] - 3'd4;
          2'b11: data_cnt[act_channel] <= data_cnt[act_channel] - 4'd8;
      else
        case( csr[DMA_CCR_CR][DMA_CCR_CR_PSIZE1:DMA_CCR_CR_PSIZE0] )
          2'b00: data_cnt[act_channel] <= data_cnt[act_channel] - 1'd1;
          2'b01: data_cnt[act_channel] <= data_cnt[act_channel] - 2'd2;
          2'b10: data_cnt[act_channel] <= data_cnt[act_channel] - 3'd4;
          2'b11: data_cnt[act_channel] <= data_cnt[act_channel] - 4'd8;

assign 
      if( data_cnt != 0 )
        if( data_cnt <= [DMA_CCR_CR_MSIZE1:DMA_CCR_CR_MSIZE0] )
          data_cnt <= '0;

always_ff @( posedge clk_i )
  if( state == START_S )
    data_cnt[act_channel] <= csr_if.channel_data_cnt[arb_channel_o];
  else
    if( amm_if.readdatavalid )
      case( csr_if.item_addr_mode )
        2'b00: data_cnt[act_channel] <= data_cnt[act_channel] - 1'd1;
        2'b01: data_cnt[act_channel] <= data_cnt[act_channel] - 2'd2;
        2'b10: data_cnt[act_channel] <= data_cnt[act_channel] - 3'd4;
        2'b11: data_cnt[act_channel] <= data_cnt[act_channel] - 4'd8;

always_ff @( posedge clk_i )


endmodule : dma_controller_engine

