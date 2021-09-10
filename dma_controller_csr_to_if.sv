module dma_controller_csr_to_if #(
  parameter CHANNELS_AMOUNT = 4,
  parameter DATA_W          = 32,
  parameter ADDR_W          = 8
)(
  avalon_mm_if  amm_if,
  dma_conf_if   dma_cfg_if [CHANNELS_AMOUNT-1:0]
);

localparam CHANNEL_REG_AMOUNT = 4*CHANNELS_AMOUNT;
localparam GENERAL_REG_AMOUNT = 2;
localparam DATA_B_W           = DATA_W;

logic [DATA_W-1:0] mem_write  [GENERAL_REG_AMOUNT+CHANNEL_REG_AMOUNT-1:0];
logic [DATA_W-1:0] mem_read   [GENERAL_REG_AMOUNT+CHANNEL_REG_AMOUNT-1:0];

logic              readdatavalid;
logic [DATA_W-1:0] readdata;

genvar channel_num;
generate

  for( channel_num = 0; channel_num < CHANNELS_AMOUNT; channel_num++ )
    begin : gen_dma_channel_cfg

      assign dma_cfg_if.clear_tci_flag    [channel_num] = mem_write[DMA_IFCR_CR][DMA_IFCR_CR_CTCIF+channel_num*4];
      assign dma_cfg_if.clear_hci_flag    [channel_num] = mem_write[DMA_IFCR_CR][DMA_IFCR_CR_CHTIF+channel_num*4];
      assign dma_cfg_if.clear_tce_flag    [channel_num] = mem_write[DMA_IFCR_CR][DMA_IFCR_CR_CTEIF+channel_num*4];
      assign dma_cfg_if.clear_gi_flag     [channel_num] = mem_write[DMA_IFCR_CR][DMA_IFCR_CR_CGIF +channel_num*4];

      assign dma_cfg_if.channel_en        [channel_num] = mem_write[GENERAL_REG_AMOUNT+channel_num*CHANNEL_REG_AMOUNT+DMA_CCR_CR][DMA_CCR_CR_EN];
      assign dma_cfg_if.full_trans_irq_en [channel_num] = mem_write[GENERAL_REG_AMOUNT+channel_num*CHANNEL_REG_AMOUNT+DMA_CCR_CR][DMA_CCR_CR_TCIE];
      assign dma_cfg_if.half_trans_irq_en [channel_num] = mem_write[GENERAL_REG_AMOUNT+channel_num*CHANNEL_REG_AMOUNT+DMA_CCR_CR][DMA_CCR_CR_HTIE];
      assign dma_cfg_if.trans_error_irq_en[channel_num] = mem_write[GENERAL_REG_AMOUNT+channel_num*CHANNEL_REG_AMOUNT+DMA_CCR_CR][DMA_CCR_CR_TEIE];
      assign dma_cfg_if.trans_direction   [channel_num] = mem_write[GENERAL_REG_AMOUNT+channel_num*CHANNEL_REG_AMOUNT+DMA_CCR_CR][DMA_CCR_CR_DIR ];
      assign dma_cfg_if.circular_mode_en  [channel_num] = mem_write[GENERAL_REG_AMOUNT+channel_num*CHANNEL_REG_AMOUNT+DMA_CCR_CR][DMA_CCR_CR_CIRC];
      assign dma_cfg_if.periph_addr_inc_en[channel_num] = mem_write[GENERAL_REG_AMOUNT+channel_num*CHANNEL_REG_AMOUNT+DMA_CCR_CR][DMA_CCR_CR_PINC];
      assign dma_cfg_if.mem_addr_inc_en   [channel_num] = mem_write[GENERAL_REG_AMOUNT+channel_num*CHANNEL_REG_AMOUNT+DMA_CCR_CR][DMA_CCR_CR_MINC];
      assign dma_cfg_if.periph_size       [channel_num] = mem_write[GENERAL_REG_AMOUNT+channel_num*CHANNEL_REG_AMOUNT+DMA_CCR_CR][DMA_CCR_CR_PSIZE1:DMA_CCR_CR_PSIZE0];
      assign dma_cfg_if.mem_size          [channel_num] = mem_write[GENERAL_REG_AMOUNT+channel_num*CHANNEL_REG_AMOUNT+DMA_CCR_CR][DMA_CCR_CR_MSIZE1:DMA_CCR_CR_MSIZE0];
      assign dma_cfg_if.channel_priority  [channel_num] = mem_write[GENERAL_REG_AMOUNT+channel_num*CHANNEL_REG_AMOUNT+DMA_CCR_CR][DMA_CCR_CR_PL1:DMA_CCR_CR_PL0];
      assign dma_cfg_if.mem2mem_mode_en   [channel_num] = mem_write[GENERAL_REG_AMOUNT+channel_num*CHANNEL_REG_AMOUNT+DMA_CCR_CR][DMA_CCR_CR_MEM2MEM];

      assign dma_cfg_if.periph_addr       [channel_num] = mem_write[GENERAL_REG_AMOUNT+channel_num*CHANNEL_REG_AMOUNT+DMA_CPAR_CR][DMA_CPAR_CR_PA31:DMA_CPAR_CR_PA0];

      assign dma_cfg_if.mem_addr          [channel_num] = mem_write[GENERAL_REG_AMOUNT+channel_num*CHANNEL_REG_AMOUNT+DMA_CMAR_CR][DMA_CMAR_CR_PA31:DMA_CPAR_CR_PA0];

      assign dma_cfg_if.data_cnt          [channel_num] = amm_if.writedata;
      assign dma_cfg_if.data_cnt_be       [channel_num] = amm_if.byteenable;
      assign dma_cfg_if.data_cnt_wr_stb   [channel_num] = amm_if.write && amm_if.address == GENERAL_REG_AMOUNT+channel_num*CHANNEL_REG_AMOUNT+DMA_CNDTR_CR;
      
      assign mem_read[DMA_ISR_SR][DMA_ISR_SR_GIF +channel_num*4] = dma_stat_if.set_gi_flag [channel_num];
      assign mem_read[DMA_ISR_SR][DMA_ISR_SR_TCIF+channel_num*4] = dma_stat_if.set_tci_flag[channel_num];
      assign mem_read[DMA_ISR_SR][DMA_ISR_SR_HTIF+channel_num*4] = dma_stat_if.set_hti_flag[channel_num];
      assign mem_read[DMA_ISR_SR][DMA_ISR_SR_TEIF+channel_num*4] = dma_stat_if.set_tei_flag[channel_num];

      assign mem_read[GENERAL_REG_AMOUNT+channel_num*CHANNEL_REG_AMOUNT+DMA_CNDTR_CR]  = dma_stat_if.left_data_cnt[channel_num];

      assign mem_read[GENERAL_REG_AMOUNT+channel_num*CHANNEL_REG_AMOUNT+DMA_CCR_CR]  = mem_read[GENERAL_REG_AMOUNT+channel_num*CHANNEL_REG_AMOUNT+DMA_CCR_CR];
      assign mem_read[GENERAL_REG_AMOUNT+channel_num*CHANNEL_REG_AMOUNT+DMA_CPAR_CR] = mem_read[GENERAL_REG_AMOUNT+channel_num*CHANNEL_REG_AMOUNT+DMA_CPAR_CR];
      assign mem_read[GENERAL_REG_AMOUNT+channel_num*CHANNEL_REG_AMOUNT+DMA_CMAR_CR] = mem_read[GENERAL_REG_AMOUNT+channel_num*CHANNEL_REG_AMOUNT+DMA_CMAR_CR];
    end

endgenerate

always_ff @( posedge amm_if.clk )
  if( amm_if.write )
    for( int byte_num = 0; byte_num < DATA_B_W; byte_num++ )
      mem_write[amm_if.address + 7 + byte_num*8 -: 8] <= amm_if.writedata[7 + byte_num*8 -: 8];

always_ff @( posedge amm_if.clk )
  readdatavalid <= amm_if.read;

always_ff @( posedge amm_if.clk )
  readdata <= mem_read[amm_if.address+DATA_W-1 -: DATA_W];

assign amm_if.readdatavalid = readdatavalid;
assign amm_if.readdata      = readdata;

endmodule : dma_controller_csr_to_if

