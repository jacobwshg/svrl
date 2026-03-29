
add wave -noupdate -group my_uvm_tb/dut
add wave -noupdate -group my_uvm_tb/dut -radix decimal /my_uvm_tb/dut/*

add wave -noupdate -group my_uvm_tb/dut/fifo_in
add wave -noupdate -group my_uvm_tb/dut/fifo_in -radix hexadecimal /my_uvm_tb/dut/fifo_in/*

add wave -noupdate -group my_uvm_tb/dut/fifo_out
add wave -noupdate -group my_uvm_tb/dut/fifo_out -radix hexadecimal /my_uvm_tb/dut/fifo_out/*

add wave -noupdate -group my_uvm_tb/dut/ql
add wave -noupdate -group my_uvm_tb/dut/ql -radix hexadecimal /my_uvm_tb/dut/ql/*

add wave -noupdate -group my_uvm_tb/dut/ql/Qtbl
add wave -noupdate -group my_uvm_tb/dut/ql/Qtbl -radix hexadecimal /my_uvm_tb/dut/ql/Qtbl/*

add wave -noupdate -group my_uvm_tb/dut/ql/Qmax_actions_buf
add wave -noupdate -group my_uvm_tb/dut/ql/Qmax_actions_buf -radix hexadecimal /my_uvm_tb/dut/ql/Qmax_actions_buf/*

