
class phy_monitor extends uvm_monitor;

  `uvm_component_utils(phy_monitor)

  // Virtual interface
  virtual usb_phy_if #(8) vif;

  // Agent configuration
  phy_agent_config cfg;

  // TX byte transactions
  uvm_analysis_port #(phy_transaction) analysis_port;

  // RX byte transactions
  uvm_analysis_port #(phy_transaction) rx_analysis_port;

  // RX status/error events
  uvm_analysis_port #(phy_transaction) rx_status_analysis_port;

  // Statistics
  int unsigned tx_handshake_count;
  int unsigned rx_valid_count;
  int unsigned tx_active_cycles;
  int unsigned rx_status_event_count;

  // Transaction IDs
  int unsigned tx_transaction_id;
  int unsigned rx_transaction_id;
  int unsigned status_transaction_id;

  // Previous status values for edge detection
  bit prev_rx_error;
  bit prev_rx_stuff_err;
  bit prev_rx_align_err;
  bit prev_rx_line_err;
  bit prev_rx_sync_err;
  bit prev_rx_bus_reset;


  // Constructor
  function new(
    string name = "phy_monitor",
    uvm_component parent = null
  );

    super.new(name, parent);

    analysis_port = new("analysis_port", this);

    rx_analysis_port = new("rx_analysis_port", this);

    rx_status_analysis_port =
      new("rx_status_analysis_port", this);

    tx_handshake_count = 0;
    rx_valid_count = 0;
    tx_active_cycles = 0;
    rx_status_event_count = 0;

    tx_transaction_id = 0;
    rx_transaction_id = 0;
    status_transaction_id = 0;

    prev_rx_error = 0;
    prev_rx_stuff_err = 0;
    prev_rx_align_err = 0;
    prev_rx_line_err = 0;
    prev_rx_sync_err = 0;
    prev_rx_bus_reset = 0;

  endfunction


  // Build phase
  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    if (!uvm_config_db#(phy_agent_config)::get(
          this,
          "",
          "cfg",
          cfg
        )) begin

      `uvm_fatal(
        "PHY_MON",
        "phy_agent_config not found"
      )

    end

    if (cfg == null) begin

      `uvm_fatal(
        "PHY_MON",
        "PHY agent configuration is NULL"
      )

    end

    if (cfg.vif == null) begin

      `uvm_fatal(
        "PHY_MON",
        "PHY virtual interface is NULL"
      )

    end

    vif = cfg.vif;

  endfunction


  // Run phase
  task run_phase(uvm_phase phase);

    `uvm_info(
      "PHY_MON",
      "PHY monitor started",
      UVM_LOW
    )

    fork
      monitor_tx();
      monitor_rx();
      monitor_rx_status();
    join

  endtask


  // --------------------------------------------------
  // TX monitor
  // --------------------------------------------------

  task monitor_tx();

    phy_transaction tr;

    forever begin

      @(vif.cb_mon);

      if (vif.cb_mon.rst_n !== 1'b1)
        continue;

      // Count active TX cycles
      if (vif.cb_mon.tx_valid === 1'b1)
        tx_active_cycles++;

      // Capture only accepted SIE bytes
      if ((vif.cb_mon.sie_valid === 1'b1) &&
          (vif.cb_mon.sie_ready === 1'b1)) begin

        tr = phy_transaction::type_id::create(
          "tx_handshake_tr"
        );

        tr.speed = (vif.cb_mon.usb_speed == speed_t'(2'b11)) ?
                   FS : vif.cb_mon.usb_speed;

        tr.data = vif.cb_mon.sie_data;

        tr.valid = 1'b1;

        tr.ready = 1'b1;

        tr.sop = vif.cb_mon.sie_sop;

        tr.eop = vif.cb_mon.sie_eop;

        tr.sof_packet = vif.cb_mon.sof_packet;

        tr.delay_cycles = 0;

        tr.valid_gap_cycles = 0;

        tr.transaction_id = tx_transaction_id++;

        tx_handshake_count++;

        `uvm_info(
          "PHY_MON_TX",
          tr.convert2string(),
          UVM_HIGH
        )

        analysis_port.write(tr);

      end

    end

  endtask


  // --------------------------------------------------
  // RX monitor
  // --------------------------------------------------

  task monitor_rx();

    phy_transaction tr;

    forever begin

      @(vif.cb_mon);

      if (vif.cb_mon.rst_n !== 1'b1)
        continue;

      // RX byte is valid only when RxValid is asserted
      if (vif.cb_mon.RxValid === 1'b1) begin

        tr = phy_transaction::type_id::create(
          "rx_data_tr"
        );

        tr.speed = vif.cb_mon.usb_speed;

        tr.data = vif.cb_mon.DataOut;

        tr.valid = 1'b1;

        tr.ready = 1'b0;

        tr.sop = vif.cb_mon.rx_sop;

        tr.eop = vif.cb_mon.rx_eop;

        tr.sof_packet = 1'b0;

        tr.delay_cycles = 0;

        tr.valid_gap_cycles = 0;

        tr.transaction_id = rx_transaction_id++;

        // Capture current RX status with the byte
        tr.rx_error = vif.cb_mon.RxError;

        tr.rx_stuff_err = vif.cb_mon.rx_stuff_err;

        tr.rx_align_err = vif.cb_mon.rx_align_err;

        tr.rx_line_err = vif.cb_mon.rx_line_err;

        tr.rx_sync_err = vif.cb_mon.rx_sync_err;

        tr.rx_bus_reset = vif.cb_mon.rx_bus_reset;

        rx_valid_count++;

        `uvm_info(
          "PHY_MON_RX",
          tr.convert2string(),
          UVM_HIGH
        )

        rx_analysis_port.write(tr);

      end

    end

  endtask


  // --------------------------------------------------
  // RX status monitor
  // --------------------------------------------------

  task monitor_rx_status();

    phy_transaction tr;

    bit current_rx_error;
    bit current_stuff_err;
    bit current_align_err;
    bit current_line_err;
    bit current_sync_err;
    bit current_bus_reset;

    bit status_changed;

    forever begin

      @(vif.cb_mon);

      if (vif.cb_mon.rst_n !== 1'b1) begin

        prev_rx_error = 0;
        prev_rx_stuff_err = 0;
        prev_rx_align_err = 0;
        prev_rx_line_err = 0;
        prev_rx_sync_err = 0;
        prev_rx_bus_reset = 0;

        continue;

      end

      current_rx_error = vif.cb_mon.RxError;

      current_stuff_err = vif.cb_mon.rx_stuff_err;

      current_align_err = vif.cb_mon.rx_align_err;

      current_line_err = vif.cb_mon.rx_line_err;

      current_sync_err = vif.cb_mon.rx_sync_err;

      current_bus_reset = vif.cb_mon.rx_bus_reset;


      // Publish both assertions and clears. The scoreboard counts only rises.
      status_changed = (current_rx_error != prev_rx_error) ||
                       (current_stuff_err != prev_rx_stuff_err) ||
                       (current_align_err != prev_rx_align_err) ||
                       (current_line_err != prev_rx_line_err) ||
                       (current_sync_err != prev_rx_sync_err) ||
                       (current_bus_reset != prev_rx_bus_reset);


      if (status_changed) begin

        tr = phy_transaction::type_id::create(
          "rx_status_tr"
        );

        tr.speed = vif.cb_mon.usb_speed;

        tr.data = '0;

        // This is a status event, not a received byte
        tr.valid = 1'b0;

        tr.ready = 1'b0;

        tr.sop = 1'b0;

        tr.eop = 1'b0;

        tr.sof_packet = 1'b0;

        tr.delay_cycles = 0;

        tr.valid_gap_cycles = 0;

        tr.transaction_id = status_transaction_id++;

        tr.rx_error = current_rx_error;

        tr.rx_stuff_err = current_stuff_err;

        tr.rx_align_err = current_align_err;

        tr.rx_line_err = current_line_err;

        tr.rx_sync_err = current_sync_err;

        tr.rx_bus_reset = current_bus_reset;

        rx_status_event_count++;

        `uvm_info(
          "PHY_MON_STATUS",
          tr.convert2string(),
          UVM_MEDIUM
        )

        rx_status_analysis_port.write(tr);

      end


      // Update previous values
      prev_rx_error = current_rx_error;

      prev_rx_stuff_err = current_stuff_err;

      prev_rx_align_err = current_align_err;

      prev_rx_line_err = current_line_err;

      prev_rx_sync_err = current_sync_err;

      prev_rx_bus_reset = current_bus_reset;

    end

  endtask


  // Report phase
  function void report_phase(uvm_phase phase);

    super.report_phase(phase);

    `uvm_info(
      "PHY_MON_REPORT",
      "==========================================",
      UVM_LOW
    )

    `uvm_info(
      "PHY_MON_REPORT",
      $sformatf(
        "TX accepted bytes       = %0d",
        tx_handshake_count
      ),
      UVM_LOW
    )

    `uvm_info(
      "PHY_MON_REPORT",
      $sformatf(
        "TX active cycles        = %0d",
        tx_active_cycles
      ),
      UVM_LOW
    )

    `uvm_info(
      "PHY_MON_REPORT",
      $sformatf(
        "RX valid bytes          = %0d",
        rx_valid_count
      ),
      UVM_LOW
    )

    `uvm_info(
      "PHY_MON_REPORT",
      $sformatf(
        "RX status events        = %0d",
        rx_status_event_count
      ),
      UVM_LOW
    )

    `uvm_info(
      "PHY_MON_REPORT",
      "==========================================",
      UVM_LOW
    )

  endfunction

endclass

