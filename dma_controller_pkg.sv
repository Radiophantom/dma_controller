package dma_controller_pkg;

parameter DMA_ISR_SR    = 0;
        parameter DMA_ISR_SR_GIF  = 0;
        parameter DMA_ISR_SR_TCIF = 1;
        parameter DMA_ISR_SR_HTIF = 2;
        parameter DMA_ISR_SR_TEIF = 3;

parameter DMA_IFCR_CR   = 1;
        parameter DMA_IFCR_CR_CGIF  = 0;
        parameter DMA_IFCR_CR_CTCIF = 1;
        parameter DMA_IFCR_CR_CHTIF = 2;
        parameter DMA_IFCR_CR_CTEIF = 3;

parameter DMA_CCR_CR    = 2;
        parameter DMA_CCR_CR_EN       = 0;
        parameter DMA_CCR_CR_TCIE     = 1;
        parameter DMA_CCR_CR_HTIE     = 2;
        parameter DMA_CCR_CR_TEIE     = 3;
        parameter DMA_CCR_CR_DIR      = 4;
        parameter DMA_CCR_CR_CIRC     = 5;
        parameter DMA_CCR_CR_PINC     = 6;
        parameter DMA_CCR_CR_MINC     = 7;
        parameter DMA_CCR_CR_PSIZE0   = 8;
        parameter DMA_CCR_CR_MSIZE0   = 10;
        parameter DMA_CCR_CR_PL0      = 12;
        parameter DMA_CCR_CR_MEM2MEM  = 14;

parameter DMA_CNDTR_CR  = 3;
        parameter DMA_CNDTR_NDT0  = 0;
        parameter DMA_CNDTR_NDT15 = 15;

parameter DMA_CPAR_CR   = 4;
        parameter DMA_CPAR_CR_PA0   = 0;
        parameter DMA_CPAR_CR_PA31  = 31;

parameter DMA_CMAR_CR   = 5;
        parameter DMA_CMAR_CR_PA0   = 0;
        parameter DMA_CMAR_CR_PA31  = 31;

endpackage : dma_controller_pkg

