
class phy_agent extends uvm_agent;

  `uvm_component_utils(phy_agent)

  // Agent configuration
  phy_agent_config cfg;

  // Agent components
  phy_sequencer sequencer;
  phy_driver    driver;
  phy_monitor   monitor;


  // Constructor
  function new(
    string name = "phy_agent",
    uvm_component parent = null
  );

    super.new(name, parent);

  endfunction


  // --------------------------------------------------
  // Build phase
  // --------------------------------------------------

  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    // Retrieve PHY agent configuration
    if (!uvm_config_db#(phy_agent_config)::get(
          this,
          "",
          "cfg",
          cfg
        )) begin

      `uvm_fatal(
        "PHY_AGENT",
        "Failed to retrieve phy_agent_config"
      )

    end

    if (cfg == null) begin

      `uvm_fatal(
        "PHY_AGENT",
        "PHY agent configuration is NULL"
      )

    end

    // Validate configuration
    cfg.check_config();


    // ------------------------------------------------
    // Create monitor
    // ------------------------------------------------

    if (cfg.enable_monitor) begin

      // Distribute configuration before component creation
      uvm_config_db#(phy_agent_config)::set(
        this,
        "monitor",
        "cfg",
        cfg
      );

      monitor = phy_monitor::type_id::create(
        "monitor",
        this
      );

    end


    // ------------------------------------------------
    // Create driver and sequencer
    // ------------------------------------------------

    if (cfg.is_active == UVM_ACTIVE) begin

      if (cfg.enable_driver) begin

        // Distribute configuration to driver
        uvm_config_db#(phy_agent_config)::set(
          this,
          "driver",
          "cfg",
          cfg
        );

        // Create sequencer
        sequencer = phy_sequencer::type_id::create(
          "sequencer",
          this
        );

        // Create driver
        driver = phy_driver::type_id::create(
          "driver",
          this
        );

      end
      else begin

        `uvm_fatal(
          "PHY_AGENT",
          "Agent is ACTIVE but driver is disabled. Use PASSIVE mode if no driver is required."
        )

      end

    end


    `uvm_info(
      "PHY_AGENT",
      $sformatf(
        "Build completed: MODE=%s DRIVER=%0b MONITOR=%0b SPEED=%0d",
        (cfg.is_active == UVM_ACTIVE) ? "ACTIVE" : "PASSIVE",
        (driver != null),
        (monitor != null),
        cfg.speed
      ),
      UVM_LOW
    )

  endfunction


  // --------------------------------------------------
  // Connect phase
  // --------------------------------------------------

  function void connect_phase(uvm_phase phase);

    super.connect_phase(phase);

    // Connect driver to sequencer
    if (driver != null && sequencer != null) begin

      driver.seq_item_port.connect(
        sequencer.seq_item_export
      );

      `uvm_info(
        "PHY_AGENT",
        "Driver connected to sequencer",
        UVM_LOW
      )

    end


    // Validate active agent connectivity
    if (cfg.is_active == UVM_ACTIVE) begin

      if (driver == null || sequencer == null) begin

        `uvm_fatal(
          "PHY_AGENT",
          "Active agent is missing driver or sequencer"
        )

      end

    end


    // Validate monitor creation
    if (cfg.enable_monitor && monitor == null) begin

      `uvm_fatal(
        "PHY_AGENT",
        "Monitor is enabled but was not created"
      )

    end


    `uvm_info(
      "PHY_AGENT",
      "Connect phase completed",
      UVM_LOW
    )

  endfunction


  // --------------------------------------------------
  // End of elaboration phase
  // --------------------------------------------------

  function void end_of_elaboration_phase(
    uvm_phase phase
  );

    super.end_of_elaboration_phase(phase);

    `uvm_info(
      "PHY_AGENT",
      "PHY agent hierarchy",
      UVM_LOW
    )

    this.print();

  endfunction


  // --------------------------------------------------
  // Report phase
  // --------------------------------------------------

  function void report_phase(uvm_phase phase);

    super.report_phase(phase);

    `uvm_info(
      "PHY_AGENT",
      "PHY agent report phase completed",
      UVM_LOW
    )

  endfunction

endclass

