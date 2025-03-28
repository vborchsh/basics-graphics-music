`ifndef LAB_SPECIFIC_CONFIG_SVH
`define LAB_SPECIFIC_CONFIG_SVH

// This is the default file included
// when there is no lab_specific_config.svh
// in the lab directory

// The following setting is needed for Gowin boards
   `define ENABLE_TM1638

// `define EMULATE_DYNAMIC_7SEG_WITHOUT_STICKY_FLOPS

   `define DUPLICATE_TM_SIGNALS_WITH_REGULAR
// `define CONCAT_REGULAR_SIGNALS_AND_TM
// `define CONCAT_TM_SIGNALS_AND_REGULAR

`endif  // `ifndef LAB_SPECIFIC_CONFIG_SVH
