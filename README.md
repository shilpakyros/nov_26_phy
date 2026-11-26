# SIE-facing agent

This folder occupies the same location as `apb_agent` in the UART bench. `phy_top` has no APB port: `phy_driver` sends the SIE byte handshake (`sie_data`, `sie_valid`, `sie_ready`, SOP/EOP) and `phy_monitor` observes TX and RX. Do not interpret these transactions as APB accesses.
