defmodule TM.Mercury.SearchFlag do
  use TM.Mercury.Utils.Enum,
    configured_antenna: 0,
    antenna_1_then_2: 1,
    antenna_2_then_1: 2,
    configured_list: 3,
    antenna_mask: 3,
    embedded_command: 4,
    tag_streaming: 8,
    large_tag_population_support: 16,
    status_report_streaming: 32,
    return_on_n_tags: 64,
    read_multiple_fast_search: 128,
    stats_report_streaming: 256,
    gpi_trigger_read: 512
end
