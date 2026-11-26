
class phy_simple_tx_seq extends uvm_sequence #(phy_transaction);

  `uvm_object_utils(phy_simple_tx_seq)

  speed_t packet_speed = FS;

  rand int unsigned packet_length;
  rand bit is_sof;

  int unsigned transaction_id;

  constraint c_packet_length {
    packet_length inside {[1:64]};
  }

  constraint c_sof_speed {
    if (packet_speed != HS)
      is_sof == 1'b0;
  }

  function new(string name = "phy_simple_tx_seq");
    super.new(name);

    packet_speed   = FS;
    packet_length  = 8;
    is_sof         = 1'b0;
    transaction_id = 0;
  endfunction


  virtual task body();

    phy_transaction req;

    if (!(packet_speed inside {LS, FS, HS})) begin
      `uvm_fatal(
        "PHY_TX_SEQ",
        $sformatf("Invalid packet_speed=%0d", packet_speed)
      )
    end

    if (!this.randomize(packet_length, is_sof)) begin
      `uvm_fatal(
        "PHY_TX_SEQ",
        "Failed to randomize packet_length/is_sof"
      )
    end

    `uvm_info(
      "PHY_TX_SEQ",
      $sformatf(
        "Starting TX packet: speed=%0d length=%0d SOF=%0b",
        packet_speed,
        packet_length,
        is_sof
      ),
      UVM_MEDIUM
    )

    for (int unsigned i = 0; i < packet_length; i++) begin

      req = phy_transaction::type_id::create(
        $sformatf("req_%0d", i)
      );

      start_item(req);

      // Initialize every transaction field.
      req.speed            = packet_speed;
      req.valid            = 1'b1;
      req.ready            = 1'b0;
      req.sop              = (i == 0);
      req.eop              = (i == packet_length - 1);
      req.sof_packet       = (is_sof && (i == 0));
      req.delay_cycles     = 0;
      req.valid_gap_cycles = 0;
      req.transaction_id   = transaction_id++;

      req.rx_error         = 1'b0;
      req.rx_stuff_err     = 1'b0;
      req.rx_align_err     = 1'b0;
      req.rx_line_err      = 1'b0;
      req.rx_sync_err      = 1'b0;
      req.rx_bus_reset     = 1'b0;

      // Randomize payload only.
      if (!req.randomize(data)) begin
        `uvm_fatal(
          "PHY_TX_SEQ",
          $sformatf("Failed to randomize data for byte %0d", i)
        )
      end

      `uvm_info(
        "PHY_TX_SEQ",
        req.convert2string(),
        UVM_HIGH
      )

      finish_item(req);

    end

    `uvm_info(
      "PHY_TX_SEQ",
      "TX packet sequence completed",
      UVM_MEDIUM
    )

  endtask

endclass

