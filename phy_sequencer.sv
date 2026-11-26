
class phy_sequencer extends uvm_sequencer #(phy_transaction);

    `uvm_component_utils(phy_sequencer)

    function new(
        string name = "phy_sequencer",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        `uvm_info(
            "PHY_SEQUENCER",
            "PHY sequencer build phase completed",
            UVM_LOW
        )
    endfunction

endclass 
