#create bit file
write_bitstream -force ../bit/top.bit

#create hwdef file
write_hwdef -file ../os/hw/top.hwdef -force

# create the 
write_sysdef -hwdef ../os/hw/top.hwdef -bit ../bit/top.bit -file ../os/hw/top.hdf -force

#create any debugging files
write_debug_probes -force ../bit/top.ltx                                                                
