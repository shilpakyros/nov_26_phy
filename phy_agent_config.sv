
class phy_agent_config extends uvm_object;

  `uvm_object_utils(phy_agent_config)

  // PHY virtual interface
  virtual usb_phy_if #(8) vif;

  // Agent operation mode
  uvm_active_passive_enum is_active = UVM_ACTIVE;

  // Component controls
  bit enable_driver  = 1'b1;
  bit enable_monitor = 1'b1;

  // Selected USB speed
  speed_t speed = FS;

  // Agent identification
  string agent_name = "PHY_AGENT";


  // Constructor
  function new(string name = "phy_agent_config");
    super.new(name);
  endfunction


  // Set USB speed
  function void set_speed(speed_t new_speed);

    if (!(new_speed inside {LS, FS, HS})) begin

      `uvm_fatal(
        "PHY_AGENT_CFG",
        $sformatf(
          "Invalid USB speed: %0d",
          new_speed
        )
      )

    end

    speed = new_speed;

  endfunction


  // Validate configuration
  function void check_config();

    if (vif == null) begin

      `uvm_fatal(
        "PHY_AGENT_CFG",
        "PHY virtual interface is NULL"
      )

    end

    if (!(speed inside {LS, FS, HS})) begin

      `uvm_fatal(
        "PHY_AGENT_CFG",
        "Invalid USB speed configuration"
      )

    end

    if (is_active == UVM_ACTIVE && !enable_driver) begin

      `uvm_fatal(
        "PHY_AGENT_CFG",
        "Active PHY agent requires driver enabled"
      )

    end

    if (!enable_driver && !enable_monitor) begin

      `uvm_warning(
        "PHY_AGENT_CFG",
        "Both PHY driver and monitor are disabled"
      )

    end

  endfunction


  // Print configuration
  function void print_config();

    `uvm_info(
      "PHY_AGENT_CFG",
      $sformatf(
        "Agent=%s SPEED=%0d MODE=%s DRIVER=%0b MONITOR=%0b",
        agent_name,
        speed,
        (is_active == UVM_ACTIVE) ? "ACTIVE" : "PASSIVE",
        enable_driver,
        enable_monitor
      ),
      UVM_LOW
    )

  endfunction

endclass

