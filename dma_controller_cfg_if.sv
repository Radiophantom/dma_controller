interface dma_controller_cfg_if #(

)(
  input clk,
  input rst
);
              
  logic         clear_gif;
  logic         clear_tcif;
  logic         clear_htif;
  logic         clear_teif;

  logic         gif_irq;
  logic         tcif_irq;
  logic         htif_irq;
  logic         teif_irq;

  logic         channel_en;
  logic         tci_irq_en;
  logic         hti_irq_en;
  logic         tei_irq_en;
  logic         direction;
  logic         circular_mode;
  logic         periph_addr_inc_en;
  logic         mem_addr_inc_en;
  logic [1:0]   periph_addr_size;
  logic [1:0]   mem_addr_size;
  logic [1:0]   channel_priority;
  logic         mem2mem_mode_en;

  logic [15:0]  data_byte_cnt;
  logic [31:0]  periph_copy_address;
  logic [31:0]  mem_copy_address;

endinterface : dma_controller_cfg_if

