//======================================================
// 1. File: library_pkg.sv Harsh
// Description: Common package for Library Self-Checkout
//======================================================
package library_pkg;
 // -----------------------------------------------
 // General parameters
 // -----------------------------------------------
 parameter int MAX_BOOKS = 128; // total books supported
 parameter int MAX_TXNS = 64; // transaction log depth
 parameter int BOOK_ID_WIDTH = 7; // log2(128)
 parameter int DATE_WIDTH = 8; // simple day counter
 parameter int FINE_WIDTH = 12; // fine amount width
 parameter int RATE_WIDTH = 8; // fine rate width
 // -----------------------------------------------
 // FSM state encoding
 // -----------------------------------------------
 typedef enum logic [3:0] {
 IDLE = 4'd0,
 SCAN_BOOK = 4'd1,
 CHECK_OP = 4'd2,
 ISSUE_BOOK = 4'd3,
 RETURN_BOOK = 4'd4,
 CALC_FINE = 4'd5,
 PRINT_RECEIPT = 4'd6,
 LOG_TXN = 4'd7,
 MAINTENANCE = 4'd8,
 ERROR = 4'd9
 } state_t;
 // -----------------------------------------------
 // Operation type encoding
 // -----------------------------------------------
 typedef enum logic {
 OP_ISSUE = 1'b0,
 OP_RETURN = 1'b1
 } op_t;
 // -----------------------------------------------
 // Transaction type encoding
 // -----------------------------------------------
 typedef enum logic [1:0] {
 TXN_NONE = 2'd0,
 TXN_ISSUE = 2'd1,
 TXN_RETURN = 2'd2
 } txn_t;
endpackage
//======================================================
// 2.File: library_fsm.sv Harsh
// Description: Mealy FSM Controller for Library System
//======================================================
`timescale 1ns/1ps
import library_pkg::*;
module library_fsm (
 input logic clk,
 input logic rst_n,
 // user inputs
 input logic scan_book,
 input logic issue_req,
 input logic return_req,
 input logic late_return,
 // maintenance & error
 input logic maint_mode,
 input logic exit_maint,
 input logic error_detected,
 // control outputs to datapath
 output logic do_issue,
 output logic do_return,
 output logic calc_fine,
 output logic print_receipt,
 output logic log_txn,
 // state output (for debug / TB)
 output state_t curr_state
);
 // -----------------------------------------------
 // State registers
 // -----------------------------------------------
 state_t state, next_state;
 assign curr_state = state;
 // -----------------------------------------------
 // Sequential state update
 // -----------------------------------------------
 always_ff @(posedge clk) begin
 if (!rst_n)
 state <= IDLE;
 else
 state <= next_state;
 end
 // -----------------------------------------------
 // Next-state logic (combinational)
 // -----------------------------------------------
 always_comb begin
 next_state = state;
 case (state)
 IDLE: begin
 if (maint_mode)
 next_state = MAINTENANCE;
 else if (scan_book)
 next_state = SCAN_BOOK;
 end
 SCAN_BOOK: begin
 next_state = CHECK_OP;
 end
 CHECK_OP: begin
 if (issue_req)
 next_state = ISSUE_BOOK;
 else if (return_req)
 next_state = RETURN_BOOK;
 end
 ISSUE_BOOK: begin
 next_state = PRINT_RECEIPT;
 end
 RETURN_BOOK: begin
 if (late_return)
 next_state = CALC_FINE;
 else
 next_state = PRINT_RECEIPT;
 end
 CALC_FINE: begin
 next_state = PRINT_RECEIPT;
 end
 PRINT_RECEIPT: begin
 next_state = LOG_TXN;
 end
 LOG_TXN: begin
 next_state = IDLE;
 end
 MAINTENANCE: begin
 if (exit_maint)
 next_state = IDLE;
 end
 ERROR: begin
 next_state = ERROR;
 end
 default: next_state = IDLE;
 endcase
 // global error override
 if (error_detected)
 next_state = ERROR;
 end
 // -----------------------------------------------
 // Output logic (Mealy-style)
 // -----------------------------------------------
 always_comb begin
 // defaults
 do_issue = 1'b0;
 do_return = 1'b0;
 calc_fine = 1'b0;
 print_receipt = 1'b0;
 log_txn = 1'b0;
 case (state)
 ISSUE_BOOK: do_issue = 1'b1;
 RETURN_BOOK: do_return = 1'b1;
 CALC_FINE: calc_fine = 1'b1;
 PRINT_RECEIPT: print_receipt = 1'b1;
 LOG_TXN: log_txn = 1'b1;
 default: ;
 endcase
 end
endmodule
//======================================================
// 3. File: book_db.sv Harsh
// Description: Book Database for Library System
//======================================================
`timescale 1ns/1ps
import library_pkg::*;
module book_db (
 input logic clk,
 input logic rst_n,
 // book selection
 input logic [BOOK_ID_WIDTH-1:0] book_id,
 // control from FSM
 input logic do_issue,
 input logic do_return,
 // maintenance interface
 input logic maint_wr_en,
 input logic [BOOK_ID_WIDTH-1:0] maint_book_id,
 input logic maint_available,
 input logic [DATE_WIDTH-1:0] maint_due_date,
 // date inputs
 input logic [DATE_WIDTH-1:0] curr_date,
 // outputs
 output logic book_available,
 output logic late_return,
 output logic [DATE_WIDTH-1:0] due_date_out
);
 // -----------------------------------------------
 // Book storage arrays
 // -----------------------------------------------
 logic book_avail_mem [0:MAX_BOOKS-1];
 logic [DATE_WIDTH-1:0] due_date_mem [0:MAX_BOOKS-1];
 integer i;
 // -----------------------------------------------
 // Sequential logic: update database
 // -----------------------------------------------
 always_ff @(posedge clk) begin
 if (!rst_n) begin
 // On reset, mark all books as available
 for (i = 0; i < MAX_BOOKS; i = i + 1) begin
 book_avail_mem[i] <= 1'b1;
 due_date_mem[i] <= '0;
 end
 end
 else begin
 // Maintenance write has highest priority
 if (maint_wr_en) begin
 book_avail_mem[maint_book_id] <= maint_available;
 due_date_mem[maint_book_id] <= maint_due_date;
 end
 else begin
 // Issue operation
 if (do_issue && book_avail_mem[book_id]) begin
 book_avail_mem[book_id] <= 1'b0;
 due_date_mem[book_id] <= curr_date + 8'd14; // borrow period
 end
 // Return operation
 if (do_return) begin
 book_avail_mem[book_id] <= 1'b1;
 due_date_mem[book_id] <= '0;
 end
 end
 end
 end
 // -----------------------------------------------
 // Read logic (combinational)
 // -----------------------------------------------
 always_comb begin
 book_available = book_avail_mem[book_id];
 due_date_out = due_date_mem[book_id];
 if (curr_date > due_date_mem[book_id])
 late_return = 1'b1;
 else
 late_return = 1'b0;
 end
endmodule
//======================================================
//4. File: fine_calc.sv. Shiv
// Description: Fine Calculation Datapath
//======================================================
`timescale 1ns/1ps
import library_pkg::*;
module fine_calc (
 input logic [DATE_WIDTH-1:0] curr_date,
 input logic [DATE_WIDTH-1:0] due_date,
 input logic [RATE_WIDTH-1:0] fine_rate,
 output logic [FINE_WIDTH-1:0] fine_amount
);
 logic [DATE_WIDTH-1:0] late_days;
 // -----------------------------------------------
 // Calculate late days
 // -----------------------------------------------
 always_comb begin
 if (curr_date > due_date)
 late_days = curr_date - due_date;
 else
 late_days = '0;
 end
 // -----------------------------------------------
 // Calculate fine
 // -----------------------------------------------
 always_comb begin
 fine_amount = late_days * fine_rate;
 end
endmodule
//======================================================
// 5. File: txn_logger.sv Shiv
// Description: Transaction Logger (Circular Buffer)
//======================================================
`timescale 1ns/1ps
import library_pkg::*;
module txn_logger (
 input logic clk,
 input logic rst_n,
 // control
 input logic log_txn,
 // transaction info inputs
 input logic [BOOK_ID_WIDTH-1:0] book_id,
 input txn_t txn_type,
 input logic [FINE_WIDTH-1:0] fine_amount,
 // maintenance read interface
 input logic [$clog2(MAX_TXNS)-1:0] rd_addr,
 output logic [BOOK_ID_WIDTH-1:0] rd_book_id,
 output txn_t rd_txn_type,
 output logic [FINE_WIDTH-1:0] rd_fine_amount
);
 // -----------------------------------------------
 // Log memory arrays
 // -----------------------------------------------
 logic [BOOK_ID_WIDTH-1:0] log_book_id [0:MAX_TXNS-1];
 txn_t log_txn_type [0:MAX_TXNS-1];
 logic [FINE_WIDTH-1:0] log_fine_amt [0:MAX_TXNS-1];
 logic [$clog2(MAX_TXNS)-1:0] wr_ptr;
 integer i;
 // -----------------------------------------------
 // Sequential write logic
 // -----------------------------------------------
 always_ff @(posedge clk) begin
 if (!rst_n) begin
 wr_ptr <= '0;
 for (i = 0; i < MAX_TXNS; i = i + 1) begin
 log_book_id[i] <= '0;
 log_txn_type[i] <= TXN_NONE;
 log_fine_amt[i] <= '0;
 end
 end
 else begin
 if (log_txn) begin
 log_book_id[wr_ptr] <= book_id;
 log_txn_type[wr_ptr] <= txn_type;
 log_fine_amt[wr_ptr] <= fine_amount;
 wr_ptr <= wr_ptr + 1'b1; // wraps automatically
 end
 end
 end
 // -----------------------------------------------
 // Read logic (combinational)
 // -----------------------------------------------
 always_comb begin
 rd_book_id = log_book_id[rd_addr];
 rd_txn_type = log_txn_type[rd_addr];
 rd_fine_amount= log_fine_amt[rd_addr];
 end
endmodule
//======================================================
// 6.File: config_regs.sv. Shiv
// Description: Configuration Registers
//======================================================
`timescale 1ns/1ps
import library_pkg::*;
module config_regs (
 input logic clk,
 input logic rst_n,
 // maintenance write interface
 input logic cfg_wr_en,
 input logic [1:0] cfg_addr,
 input logic [15:0] cfg_wr_data,
 // configuration outputs
 output logic [RATE_WIDTH-1:0] fine_rate,
 output logic [DATE_WIDTH-1:0] borrow_days
);
 // -----------------------------------------------
 // Register addresses
 // -----------------------------------------------
 localparam CFG_FINE_RATE = 2'd0;
 localparam CFG_BORROW_DAYS = 2'd1;
 // -----------------------------------------------
 // Sequential register writes
 // -----------------------------------------------
 always_ff @(posedge clk) begin
 if (!rst_n) begin
 // default values after reset
 fine_rate <= 8'd5; // fine per day
 borrow_days <= 8'd14; // borrow period
 end
 else begin
 if (cfg_wr_en) begin
 case (cfg_addr)
 CFG_FINE_RATE: fine_rate <= cfg_wr_data[RATE_WIDTH-1:0];
 CFG_BORROW_DAYS: borrow_days <= cfg_wr_data[DATE_WIDTH-1:0];
 default: ;
 endcase
 end
 end
 end
endmodule
//7. top module Harsh
 top.sv
//
`timescale 1ns/1ps
import library_pkg::*;
module top (
 input logic clk,
 input logic rst_n,
 // user interface
 input logic scan_book,
 input logic issue_req,
 input logic return_req,
 input logic [BOOK_ID_WIDTH-1:0] book_id,
 input logic [DATE_WIDTH-1:0] curr_date,
 // maintenance interface
 input logic maint_mode,
 input logic exit_maint,
 input logic cfg_wr_en,
 input logic [1:0] cfg_addr,
 input logic [15:0] cfg_wr_data,
 input logic maint_book_wr_en,
 input logic [BOOK_ID_WIDTH-1:0] maint_book_id,
 input logic maint_book_avail,
 input logic [DATE_WIDTH-1:0] maint_due_date,
 // error input
 input logic error_detected,
 // outputs
 output logic [FINE_WIDTH-1:0] fine_amount,
 output logic print_receipt,
 output state_t curr_state
);
 // Internal signals
 logic do_issue, do_return, calc_fine, log_txn;
 logic book_available, late_return;
 logic [DATE_WIDTH-1:0] due_date;
 logic [RATE_WIDTH-1:0] fine_rate;
 logic [DATE_WIDTH-1:0] borrow_days;
 // FSM Controller
 library_fsm u_fsm (
 .clk(clk),
 .rst_n(rst_n),
 .scan_book(scan_book),
 .issue_req(issue_req),
 .return_req(return_req),
 .late_return(late_return),
 .maint_mode(maint_mode),
 .exit_maint(exit_maint),
 .error_detected(error_detected),
 .do_issue(do_issue),
 .do_return(do_return),
 .calc_fine(calc_fine),
 .print_receipt(print_receipt),
 .log_txn(log_txn),
 .curr_state(curr_state)
 );

 // Configuration Registers
 config_regs u_cfg (
 .clk(clk),
 .rst_n(rst_n),
 .cfg_wr_en(cfg_wr_en),
 .cfg_addr(cfg_addr),
 .cfg_wr_data(cfg_wr_data),
 .fine_rate(fine_rate),
 .borrow_days(borrow_days)
 );
 // Book Database
 book_db u_book_db (
 .clk(clk),
 .rst_n(rst_n),
 .book_id(book_id),
 .do_issue(do_issue),
 .do_return(do_return),
 .maint_wr_en(maint_book_wr_en),
 .maint_book_id(maint_book_id),
 .maint_available(maint_book_avail),
 .maint_due_date(maint_due_date),
 .curr_date(curr_date),
 .book_available(book_available),
 .late_return(late_return),
 .due_date_out(due_date)
 );
 fine_calc u_fine (
 .curr_date(curr_date),
 .due_date(due_date),
 .fine_rate(fine_rate),
 .fine_amount(fine_amount)
 );

 txn_logger u_logger (
 .clk(clk),
 .rst_n(rst_n),
 .log_txn(log_txn),
 .book_id(book_id),
 .txn_type(return_req ? TXN_RETURN : TXN_ISSUE),
 .fine_amount(fine_amount),
 .rd_addr('0),
 .rd_book_id(),
 .rd_txn_type(),
 .rd_fine_amount()
 );
endmodule
