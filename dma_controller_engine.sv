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

endmodule : dma_controller_engine

