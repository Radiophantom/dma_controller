module dma_controller_csr_to_if #(
  parameter DATA_W = 32,
  parameter A_W = 3
)(
  avalon_mm_if amm_if,
  dma_conf_if dma_cfg_if [CHANNELS_AMOUNT-1:0]
);

logic [DATA_W-1:0] mem [A_W-1:0];

always_ff @( posedge amm_if.clk )
  if( amm_if.write )
    for( int i = 0; i < DATA_B_W; i++ )
      mem[amm_if.address + i] <= amm_if.wdata[7+i*8 :- 0];


assign dma_cfg_if.channel_en          = mem[DMA_CCR_CR][DMA_CCR_CR_EN];
assign dma_cfg_if.full_trans_irq_en   = mem[DMA_CCR_CR][DMA_CCR_CR_TCIE];
assign dma_cfg_if.half_trans_irq_en   = mem[DMA_CCR_CR][DMA_CCR_CR_HTIE];
assign dma_cfg_if.trans_error_irq_en  = mem[DMA_CCR_CR][DMA_CCR_CR_TEIE];
assign dma_cfg_if.trans_direction     = mem[DMA_CCR_CR][DMA_CCR_CR_DIR ];
assign dma_cfg_if.circular_mode_en    = mem[DMA_CCR_CR][DMA_CCR_CR_CIRC];
assign dma_cfg_if.periph_addr_inc_en  = mem[DMA_CCR_CR][DMA_CCR_CR_PINC];
assign dma_cfg_if.mem_addr_inc_en     = mem[DMA_CCR_CR][DMA_CCR_CR_MINC];
assign dma_cfg_if.periph_size         = mem[DMA_CCR_CR][DMA_CCR_CR_PSIZE1:DMA_CCR_CR_PSIZE0];
assign dma_cfg_if.mem_size            = mem[DMA_CCR_CR][DMA_CCR_CR_MSIZE1:DMA_CCR_CR_MSIZE0];
assign dma_cfg_if.channel_priority    = mem[DMA_CCR_CR][DMA_CCR_CR_PL1:DMA_CCR_CR_PL0];
assign dma_cfg_if.mem2mem_mode_en     = mem[DMA_CCR_CR][DMA_CCR_CR_MEM2MEM];

assign dma_cfg_if.periph_addr = mem[DMA_CPAR_CR][DMA_CPAR_CR_PA31:DMA_CPAR_CR_PA0];
assign dma_cfg_if.mem_addr    = mem[DMA_CMAR_CR][DMA_CMAR_CR_PA31:DMA_CPAR_CR_PA0];

assign dma_cfg_if.trans_byte_amount = mem[DMA_CNDTR_CR][DMA_CNDTR_NDT15:DMA_CNDTR_NDT0];

assign dma_cfg_if.clear_tci_flag  = mem[DMA_IFCR_CR][DMA_IFCR_CR_CTCIF];
assign dma_cfg_if.clear_hci_flag  = mem[DMA_IFCR_CR][DMA_IFCR_CR_CHTIF];
assign dma_cfg_if.clear_tce_flag  = mem[DMA_IFCR_CR][DMA_IFCR_CR_CTCEF];
assign dma_cfg_if.clear_gi_flag   = mem[DMA_IFCR_CR][DMA_IFCR_CR_CGIF];

assign mem[DMA_ISR_SR][DMA_ISR_SR_GIF]  = dma_stat_if.set_gi_flag;
assign mem[DMA_ISR_SR][DMA_ISR_SR_TCIF] = dma_stat_if.set_tci_flag;
assign mem[DMA_ISR_SR][DMA_ISR_SR_HTIF] = dma_stat_if.set_hti_flag;
assign mem[DMA_ISR_SR][DMA_ISR_SR_TEIF] = dma_stat_if.set_tei_flag;

endmodule : dma_controller_csr_to_if

