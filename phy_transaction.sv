

class phy_transaction extends uvm_sequence_item;

  // Common USB speed
  rand speed_t speed;

  // TX input / RX output byte
  rand bit [7:0] data;

  // TX handshake / RX valid
  rand bit valid;
  bit ready;

  // Packet boundaries
  rand bit sop;
  rand bit eop;

  // SOF indication
  rand bit sof_packet;

  // Driver timing controls
  rand int unsigned delay_cycles;
  rand int unsigned valid_gap_cycles;

  // Transaction ID
  int unsigned transaction_id;

  // RX status fields
  bit rx_error;
  bit rx_stuff_err;
  bit rx_align_err;
  bit rx_line_err;
  bit rx_sync_err;
  bit rx_bus_reset;

  constraint c_delay_cycles {
    delay_cycles inside {[0:20]};
  }

  constraint c_valid_gap_cycles {
    valid_gap_cycles inside {[0:10]};
  }

  constraint c_packet_boundary {
    if (sop) valid == 1'b1;
    if (eop) valid == 1'b1;
  }

  constraint c_speed {
    speed inside {LS, FS, HS};
  }

  `uvm_object_utils_begin(phy_transaction)
    `uvm_field_enum(speed_t, speed, UVM_ALL_ON)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_int(valid, UVM_ALL_ON)
    `uvm_field_int(ready, UVM_ALL_ON)
    `uvm_field_int(sop, UVM_ALL_ON)
    `uvm_field_int(eop, UVM_ALL_ON)
    `uvm_field_int(sof_packet, UVM_ALL_ON)
    `uvm_field_int(delay_cycles, UVM_ALL_ON)
    `uvm_field_int(valid_gap_cycles, UVM_ALL_ON)
    `uvm_field_int(transaction_id, UVM_ALL_ON)
    `uvm_field_int(rx_error, UVM_ALL_ON)
    `uvm_field_int(rx_stuff_err, UVM_ALL_ON)
    `uvm_field_int(rx_align_err, UVM_ALL_ON)
    `uvm_field_int(rx_line_err, UVM_ALL_ON)
    `uvm_field_int(rx_sync_err, UVM_ALL_ON)
    `uvm_field_int(rx_bus_reset, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "phy_transaction");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf(
      "PHY_TXN ID=%0d SPEED=%0d DATA=0x%02h VALID=%0b READY=%0b SOP=%0b EOP=%0b SOF=%0b RXERR=%0b STUFF=%0b ALIGN=%0b LINE=%0b SYNC=%0b RESET=%0b",
      transaction_id,
      speed,
      data,
      valid,
      ready,
      sop,
      eop,
      sof_packet,
      rx_error,
      rx_stuff_err,
      rx_align_err,
      rx_line_err,
      rx_sync_err,
      rx_bus_reset
    );
  endfunction

endclass

