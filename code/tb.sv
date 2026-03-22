//======================================================
// 8.File: tb_top.sv
// Description: Testbench for Library System (top)
//======================================================
`timescale 1ns/1ps
import library_pkg::*;
module tb_top;
 // -----------------------------------------------
 // Clock & Reset
 // -----------------------------------------------
 logic clk;
 logic rst_n;
 // -----------------------------------------------
 // DUT inputs
 // -----------------------------------------------
 logic scan_book;
 logic issue_req;
 logic return_req;
 logic [BOOK_ID_WIDTH-1:0] book_id;
 logic [DATE_WIDTH-1:0] curr_date;
 logic maint_mode;
 logic exit_maint;
 logic cfg_wr_en;
 logic [1:0] cfg_addr;
 logic [15:0] cfg_wr_data;
 logic maint_book_wr_en;
 logic [BOOK_ID_WIDTH-1:0] maint_book_id;
 logic maint_book_avail;
 logic [DATE_WIDTH-1:0] maint_due_date;
 logic error_detected;
 // -----------------------------------------------
 // DUT outputs
 // -----------------------------------------------
 logic [FINE_WIDTH-1:0] fine_amount;
 logic print_receipt;
 state_t curr_state;
 // -----------------------------------------------
 // Instantiate DUT
 // -----------------------------------------------
 top dut (
 .clk(clk),
 .rst_n(rst_n),
 .scan_book(scan_book),
 .issue_req(issue_req),
 .return_req(return_req),
 .book_id(book_id),
 .curr_date(curr_date),
 .maint_mode(maint_mode),
 .exit_maint(exit_maint),
 .cfg_wr_en(cfg_wr_en),
 .cfg_addr(cfg_addr),
 .cfg_wr_data(cfg_wr_data),
 .maint_book_wr_en(maint_book_wr_en),
 .maint_book_id(maint_book_id),
 .maint_book_avail(maint_book_avail),
 .maint_due_date(maint_due_date),
 .error_detected(error_detected),
 .fine_amount(fine_amount),
 .print_receipt(print_receipt),
 .curr_state(curr_state)
 );

 // Clock generation (10 ns period)
 initial clk = 0;
 always #5 clk = ~clk;

 // Reset task

 task do_reset;
 begin
 rst_n = 0;
 #20;
 rst_n = 1;
 end
 endtask
 // -----------------------------------------------
 // Test sequence
 // -----------------------------------------------
 initial begin
 // defaults
 scan_book = 0;
 issue_req = 0;
 return_req = 0;
 book_id = '0;
 curr_date = '0;
 maint_mode = 0;
 exit_maint = 0;
 cfg_wr_en = 0;
 cfg_addr = '0;
 cfg_wr_data = '0;
 maint_book_wr_en = 0;
 maint_book_id = '0;
 maint_book_avail = 1'b1;
 maint_due_date = '0;
 error_detected = 0;
 // reset
 do_reset();
 // -------------------------------------------
 // Maintenance: set fine rate = 5
 // -------------------------------------------
 maint_mode = 1;
 cfg_wr_en = 1;
 cfg_addr = 2'd0; // fine rate
 cfg_wr_data = 16'd5;
 #10;
 cfg_wr_en = 0;
 maint_mode = 0;
 exit_maint = 1;
 #10;
 exit_maint = 0;
 // -------------------------------------------
 // Issue book ID = 3
 // -------------------------------------------
 book_id = 7'd3;
 scan_book = 1;
 issue_req = 1;
 #10;
 scan_book = 0;
 issue_req = 0;
 #50;
 // -------------------------------------------
 // Return book on time
 // -------------------------------------------
 curr_date = 8'd10;
 scan_book = 1;
 return_req= 1;
 #10;
 scan_book = 0;
 return_req= 0;
 #50;
 // -------------------------------------------
 // Late return (expect fine)
 // -------------------------------------------
 curr_date = 8'd30;
 scan_book = 1;
 return_req= 1;
 #10;
 scan_book = 0;
 return_req= 0;
 #50;
 // -------------------------------------------
 // Error injection
 // -------------------------------------------
 error_detected = 1;
 #20;
 error_detected = 0;
 #50;
 $display("Simulation completed.");
 $finish;
 end
endmodule
