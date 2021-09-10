module dma_controller_engine #(
  parameter int CHANNELS_AMOUNT = 1,
  parameter int DATA_W          = 64
)(
  input         rst_i,
  input         clk_i,

  input         channel_req_i [CHANNELS_AMOUNT-1:0],
  output        channel_ack_o [CHANNELS_AMOUNT-1:0],

  avalon_mm_if  periph_amm_if [CHANNELS_AMOUNT-1:0],
  avalon_mm_if  memory_amm_if [CHANNELS_AMOUNT-1:0],

  dma_cfg_if    dma_cfg_if    [CHANNELS_AMOUNT-1:0],
  dma_stat_if   dma_stat_if   [CHANNELS_AMOUNT-1:0]
);

//***************************************
// Local parameters
//***************************************

localparam PERIPH_IND = 1;
localparam MEMORY_IND = 0;
localparam DATA_B_W   = DATA_W/8;

//***************************************
// Functions
//***************************************

function automatic logic [3:0] inc_step(
  input logic [1:0] code
);
  case( code )
    2'b00: code = 4'b0001;
    2'b01: code = 4'b0010;
    2'b10: code = 4'b0100;
    2'b11: code = 4'b1000;
    default: code = 4'b0000;
  endcase
endfunction : inc_step

//***************************************
// Variable declaration
//***************************************

avalon_mm_if dma_periph_amm_if;
avalon_mm_if dma_memory_amm_if;

//***********
// Latch current channel number from arbiter
//**********

always_ff @( posedge clk_i )
  if( arb_req_valid && dma_ready )
    act_channel <= arb_req_channel;

//***********
// Multiplexing and demultiplexing DMA interface
//**********

always_comb
  for( int channel_num = 0; channel_num < CHANNELS_AMOUNT; channel_num++ )
    if( channel_num == act_channel )
      periph_amm_if[channel_num] = dma_periph_amm_if;
    else
      periph_amm_if[channel_num] = '0;

always_comb
  for( int channel_num = 0; channel_num < CHANNELS_AMOUNT; channel_num++ )
    if( channel_num == active_channel )
      memory_amm_if[channel_num] = dma_memory_amm_if;
    else
      memory_amm_if[channel_num] = '0;

//**********
// Channel request arbiter instance
//*********

dma_controller_arb #(
)    (

);

//**********
// State machine
//**********

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
          if( arb_req_valid )
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
      default: next_state = IDLE_S;
    endcase
  end

/*
//******************
// Internal registers
//******************

logic [1:0][31:0] allowed_addr_range [5:0];

allowed_addr_range[0][1] = 32'h10_00_00_00;
allowed_addr_range[0][0] = 32'h00_00_00_00;

allowed_addr_range[1][1] = 32'h20_00_00_00;
allowed_addr_range[1][0] = 32'h10_00_00_00;

allowed_addr_range[2][1] = 32'h30_00_00_00;
allowed_addr_range[2][0] = 32'h20_00_00_00;

allowed_addr_range[3][1] = 32'h40_00_00_00;
allowed_addr_range[3][0] = 32'h30_00_00_00;

allowed_addr_range[4][1] = 32'h50_00_00_00;
allowed_addr_range[4][0] = 32'h40_00_00_00;

logic [ADDR_RANGE_AMOUNT-1:0] dma_address_allowed_bit;
logic                         dma_address_allowed;

always_ff @( posedge clk_i )
  for( int range_num = 0; range_num < ADDR_RANGE_AMOUNT; range_num++ )
    dma_address_allowed_bit[range_num] <= ( dma_address < allowed_addr_range[range_num][1] ) && ( dma_address > allowed_addr_range[range_num][0] );

always_ff @( posedge clk_i )
  dma_address_allowed <= &dma_address_allowed_bit;
*/

always_ff @( posedge clk_i )
  if( ~dma_cfg_if.channel_en[channel] )
    periph_addr[channel] <= dma_cfg_if.periph_addr[channel];
  else
    if( channel == act_channel && dma_cfg_if.periph_addr_inc_en[channel] && inc_periph_addr_en )
      periph_addr[channel] <= periph_addr[channel] + inc_step( dma_cfg_if.periph_size[channel];

assign inc_periph_addr_en = ( dma_cfg_if.trans_direction  && state == READ_S  && dma_periph_amm_if.ready && dma_periph_amm_if.read  ) ||
                            ( ~dma_cfg_if.trans_direction && state == WRITE_S && dma_periph_amm_if.ready && dma_periph_amm_if.write );

always_ff @( posedge clk_i )
  if( ~dma_cfg_if.channel_en[channel] )
    half_trans_level <= dma_cfg_if.data_cnt >> 1;

always_ff @( posedge clk_i )
  half_trans_flag <= ( dma_cfg_if.data_cnt <= half_trans_level );

always_ff @( posedge clk_i )
  half_trans_flag_d <=  half_trans_flag;

assign half_trans_flag_set_stb = half_trans_flag && ~half_trans_flag_d;

always_ff @( posedge clk_i )
  if( half_trans_flag_clear_stb )
    half_trans_flag_bit <= 1'b0;
  else
    if( half_trans_flag_set_stb )
      half_trans_flag_bit <= 1'b1;

assign dma_cfg_if.half_trans_flag[channel] = half_trans_flag_bit;

//****************
// Periphery side DMA interface 
//****************

always_ff @( posedge clk_i )
  if( ~dma_cfg_if.channel_en[act_channel] )
    first_transaction_was <= 1'b0;
  else
    if( dma_cfg_if.trans_direction && state == READ_S && dma_periph_amm_if.ready && dma_periph_amm_if.read )
      first_transaction_was <= 1'b1;
    else
      if( ~dma_cfg_if.trans_direction && state == WRITE_S && dma_periph_amm_if.ready && dma_periph_amm_if.write )
        first_transaction_was <= 1'b1;

always_ff @( posedge clk_i )
  if( dma_cfg_if.trans_direction )
    begin
      if( state == READ_S && ~first_transaction_was[channel] )
        dma_periph_amm_if.address <= dma_cfg_if.periph_addr[act_channel];
      else
        if( dma_periph_amm_if.read && dma_periph_amm_if.ready && dma_cfg_if.periph_addr_inc_en[act_channel] )
          dma_periph_amm_if.address <= dma_periph_amm_if.address + inc_step( dma_cfg_if.periph_size );
    end
  else
    begin
      if( state == WRITE_S )
        begin
          dma_periph_amm_if.address   <= dma_cfg_if.periph_addr[act_channel];
          dma_periph_amm_if.writedata <= temp_data;
        end
      else
        if( dma_periph_amm_if.write && dma_periph_amm_if.ready && dma_cfg_if.periph_addr_inc_en[act_channel] )
          begin
            dma_periph_amm_if.address   <= dma_periph_amm_if.address + inc_step( dma_cfg_if.periph_size );
            dma_periph_amm_if.writedata <= temp_data;
          end
    end

always_ff @( posedge clk_i )
  if( dma_cfg_if.trans_direction )
    if( state == READ_S )
      begin
        dma_periph_amm_if.write <= 1'b0;
        if( dma_periph_amm_if.ready && dma_periph_amm_if.read )
          dma_periph_amm_if.read  <= 1'b0;
        else
          if( dma_periph_amm_if.ready )
            dma_periph_amm_if.read  <= 1'b1;
      end
    end
  else
    if( state == WRITE_S )
      begin
        dma_periph_amm_if.read <= 1'b0;
        if( dma_periph_amm_if.ready && dma_periph_amm_if.read )
          dma_periph_amm_if.write  <= 1'b0;
        else
          if( dma_periph_amm_if.ready )
            dma_periph_amm_if.write  <= 1'b1;
      end

//*****************
// Memory side DMA interface
//****************

//*******************
// Arbiter communicate logic
//*******************

assign dma_ready = next_state == IDLE_S;

//**************************
// Stat DMA interface
//**************************

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

genvar channel_num;
generate
  for( int channel_num = 0; channel_num < CHANNELS_AMOUNT; channel_num++ )
    begin

      assign dec_code_source = ( dma_cfg_if.trans_direction[channel_num] ) ? ( dma_cfg_if.periph_size[channel_num] ):
                                                                             ( dma_cfg_if.mem_size[channel_num]    );
      always_comb
        case( dec_code_source )
          2'b00: data_cnt_dec_code[channel_num] = 1'd1;
          2'b01: data_cnt_dec_code[channel_num] = 2'd2;
          2'b10: data_cnt_dec_code[channel_num] = 3'd4;
          2'b11: data_cnt_dec_code[channel_num] = 4'd8;
        endcase

      always_ff @( posedge clk_i )
        if( ~dma_cfg_if.channel_en[channel_num] && dma_cfg_if.data_cnt_wr_stb[channel_num] )
          data_cnt[channel_num] <= dma_cfg_if.data_cnt[channel_num];
        else
          if( data_cnt_dec[channel_num] )
            if( data_cnt[channel_num] <= data_cnt_dec_code[channel_num] )
              data_cnt[channel_num] <= '0;
            else
              data_cnt[channel_num] <= data_cnt_dec_code[channel_num];
    end
endgenerate

endmodule : dma_controller_engine

