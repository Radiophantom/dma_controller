module dma_controller_csr_to_if #(
  parameter DATA_W = 32,
  parameter A_W = 3
)(
  avalon_mm_if amm_if,
  dma_conf_if dma_if
);

logic [DATA_W-1:0] mem [A_W-1:0];

always_ff @( posedge amm_if.clk )
  if( amm_if.write )
    for( int i = 0; i < DATA_B_W; i++ )
      mem[amm_if.address + i] <= amm_if.wdata[7+i*8 :- 0];



endmodule : dma_controller_csr_to_if

