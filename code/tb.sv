`include "uvm_macros.svh"
import uvm_pkg::*;

class library_txn extends uvm_sequence_item;

  rand bit scan_book;
  rand bit issue_req;
  rand bit return_req;
  rand bit [6:0] book_id;
  rand bit [7:0] curr_date;
  bit [3:0] curr_state;   // add this

  `uvm_object_utils(library_txn)

  function new(string name = "library_txn");
    super.new(name);
  endfunction

endclass


class issue_seq extends uvm_sequence #(library_txn);

  `uvm_object_utils(issue_seq)

  function new(string name = "issue_seq");
    super.new(name);
  endfunction

  task body();
    library_txn tx;

    tx = library_txn::type_id::create("tx");

    start_item(tx);
    tx.scan_book  = 1;
    tx.issue_req  = 1;
    tx.return_req = 0;
    tx.book_id    = 7'd5;
    tx.curr_date  = 8'd10;
    finish_item(tx);
  endtask

endclass

class return_seq extends uvm_sequence #(library_txn);

  `uvm_object_utils(return_seq)

  function new(string name = "return_seq");
    super.new(name);
  endfunction

  task body();
    library_txn tx;

    tx = library_txn::type_id::create("tx");

    start_item(tx);
    tx.scan_book  = 1;
    tx.issue_req  = 0;
    tx.return_req = 1;
    tx.book_id    = 7'd5;
    tx.curr_date  = 8'd12;
    finish_item(tx);
  endtask

endclass

class late_return_seq extends uvm_sequence #(library_txn);

  `uvm_object_utils(late_return_seq)

  function new(string name = "late_return_seq");
    super.new(name);
  endfunction

  task body();
    library_txn tx;

    tx = library_txn::type_id::create("tx");

    start_item(tx);
    tx.scan_book  = 1;
    tx.issue_req  = 0;
    tx.return_req = 1;
    tx.book_id    = 7'd5;
    tx.curr_date  = 8'd50;
    finish_item(tx);
  endtask

endclass


class random_seq extends uvm_sequence #(library_txn);

  `uvm_object_utils(random_seq)

  function new(string name = "random_seq");
    super.new(name);
  endfunction

  task body();
    library_txn tx;

    repeat (10) begin
      tx = library_txn::type_id::create("tx");

      start_item(tx);
      assert(tx.randomize() with {
  !(issue_req && return_req);
});
      finish_item(tx);
    end

  endtask

endclass

class idle_seq extends uvm_sequence #(library_txn);

  `uvm_object_utils(idle_seq)

  function new(string name = "idle_seq");
    super.new(name);
  endfunction

  task body();
    library_txn tx;

    tx = library_txn::type_id::create("tx");

    start_item(tx);
    tx.scan_book  = 1;
    tx.issue_req  = 0;
    tx.return_req = 0;   // no operation
    tx.book_id    = 7'd2;
    tx.curr_date  = 8'd15;
    finish_item(tx);

  endtask

endclass


class invalid_seq extends uvm_sequence #(library_txn);

  `uvm_object_utils(invalid_seq)

  function new(string name = "invalid_seq");
    super.new(name);
  endfunction

  task body();
    library_txn tx;

    // First issue the book (make it unavailable)
    tx = library_txn::type_id::create("tx1");
    start_item(tx);
    tx.scan_book  = 1;
    tx.issue_req  = 1;
    tx.return_req = 0;
    tx.book_id    = 7'd3;
    tx.curr_date  = 8'd10;
    finish_item(tx);

    // Now try issuing again (INVALID)
    tx = library_txn::type_id::create("tx2");
    start_item(tx);
    tx.scan_book  = 1;
    tx.issue_req  = 1;   // invalid now
    tx.return_req = 0;
    tx.book_id    = 7'd3;
    tx.curr_date  = 8'd12;
    finish_item(tx);

  endtask

endclass


class sequencer extends uvm_sequencer #(library_txn);

  `uvm_component_utils(sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass

class driver extends uvm_driver #(library_txn);

  `uvm_component_utils(driver)

  virtual lib_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual lib_if)::get(this, "", "vif", vif))
      `uvm_fatal("DRIVER", "Virtual interface not set")
  endfunction

task run_phase(uvm_phase phase);

  @(posedge vif.rst_n);
  
  `uvm_info("DRIVER", "Driver running", UVM_LOW)

  forever begin
    library_txn tx;

    seq_item_port.get_next_item(tx);
    `uvm_info("DRIVER", "Got transaction", UVM_LOW)

    // Apply inputs
    vif.scan_book  <= tx.scan_book;
    vif.issue_req  <= tx.issue_req;
    vif.return_req <= tx.return_req;
    vif.book_id    <= tx.book_id;
    vif.curr_date  <= tx.curr_date;

    // HOLD signals for multiple cycles
    repeat (2) @(posedge vif.clk);

    // Clear signals (important for pulse behavior)
    vif.scan_book  <= 0;
    vif.issue_req  <= 0;
    vif.return_req <= 0;

    @(posedge vif.clk);

    seq_item_port.item_done();
  end

endtask

endclass

class monitor extends uvm_monitor;

  `uvm_component_utils(monitor)

  virtual lib_if vif;
  uvm_analysis_port #(library_txn) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual lib_if)::get(this, "", "vif", vif))
      `uvm_fatal("MONITOR", "Virtual interface not set")
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      library_txn tx;

      @(posedge vif.clk);
        
      if (!vif.rst_n) continue;
        
      tx = library_txn::type_id::create("tx");

      tx.scan_book  = vif.scan_book;
      tx.issue_req  = vif.issue_req;
      tx.return_req = vif.return_req;
      tx.book_id    = vif.book_id;
      tx.curr_date  = vif.curr_date;
      tx.curr_state = vif.curr_state;   // added

      ap.write(tx);
    end
  endtask

endclass

class scoreboard extends uvm_component;

  `uvm_component_utils(scoreboard)

  uvm_analysis_imp #(library_txn, scoreboard) imp;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    imp = new("imp", this);
  endfunction

  function void write(library_txn tx);

    if (tx.issue_req && tx.return_req) begin
      `uvm_error("SCOREBOARD", "Invalid: Both issue and return active")
    end
    else if (tx.issue_req) begin
      `uvm_info("SCOREBOARD", "Issue operation detected", UVM_LOW)
    end
    else if (tx.return_req) begin
      `uvm_info("SCOREBOARD", "Return operation detected", UVM_LOW)
    end
    
    `uvm_info("SCOREBOARD",
  $sformatf("State = %0d", tx.curr_state),
  UVM_LOW)

  endfunction

endclass

class agent extends uvm_agent;

  `uvm_component_utils(agent)

  driver d;
  monitor m;
  sequencer s;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    d = driver::type_id::create("d", this);
    m = monitor::type_id::create("m", this);
    s = sequencer::type_id::create("s", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    d.seq_item_port.connect(s.seq_item_export);
  endfunction

endclass

class env extends uvm_env;

  `uvm_component_utils(env)

  agent a;
  scoreboard sb;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    a  = agent::type_id::create("a", this);
    sb = scoreboard::type_id::create("sb", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    a.m.ap.connect(sb.imp);
  endfunction

endclass

class test extends uvm_test;

  `uvm_component_utils(test)

  env e;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e = env::type_id::create("e", this);
  endfunction

task run_phase(uvm_phase phase);

  issue_seq        seq1;
  return_seq       seq2;
  late_return_seq  seq3;
  invalid_seq      seq4;
  idle_seq         seq5;
  random_seq       seq6;

  phase.raise_objection(this);
  
  if (e.a.s == null)
  `uvm_fatal("TEST", "Sequencer is NULL")
  
  `uvm_info("TEST", "Starting sequence", UVM_LOW)

  seq1 = issue_seq::type_id::create("seq1");
  seq2 = return_seq::type_id::create("seq2");
  seq3 = late_return_seq::type_id::create("seq3");
  seq4 = invalid_seq::type_id::create("seq4");
  seq5 = idle_seq::type_id::create("seq5");
  seq6 = random_seq::type_id::create("seq6");

  seq1.start(e.a.s);
  #20;
  seq2.start(e.a.s);
  #20;
  seq3.start(e.a.s);
  #20;
  seq5.start(e.a.s);
  #20;
  seq6.start(e.a.s);

  phase.drop_objection(this);

endtask

endclass

class stress_test extends test;

  `uvm_component_utils(stress_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);

    issue_seq       seq_i;
    return_seq      seq_r;
    late_return_seq seq_l;
    idle_seq        seq_d;
    random_seq      seq_rand;

    phase.raise_objection(this);

    if (e.a.s == null)
      `uvm_fatal("STRESS_TEST", "Sequencer is NULL")

    `uvm_info("STRESS_TEST", "Starting stress test - 5 full cycles", UVM_LOW)

    repeat (5) begin

      seq_i    = issue_seq::type_id::create("seq_i");
      seq_r    = return_seq::type_id::create("seq_r");
      seq_l    = late_return_seq::type_id::create("seq_l");
      seq_d    = idle_seq::type_id::create("seq_d");
      seq_rand = random_seq::type_id::create("seq_rand");

      seq_i.start(e.a.s);    #20;
      seq_r.start(e.a.s);    #20;
      seq_i.start(e.a.s);    #20;
      seq_l.start(e.a.s);    #20;
      seq_d.start(e.a.s);    #20;
      seq_rand.start(e.a.s); #20;

    end

    `uvm_info("STRESS_TEST", "Stress test complete", UVM_LOW)

    phase.drop_objection(this);

  endtask

endclass

class maint_test extends test;

  `uvm_component_utils(maint_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);

    phase.raise_objection(this);

    if (e.a.s == null)
      `uvm_fatal("MAINT_TEST", "Sequencer is NULL")

    // -----------------------------------------------
    // Step 1: Enter maintenance mode
    // -----------------------------------------------
    `uvm_info("MAINT_TEST", "Entering maintenance mode", UVM_LOW)
    e.a.d.vif.maint_mode = 1;
    @(posedge e.a.d.vif.clk);

    if (e.a.d.vif.curr_state !== 4'd8)
      `uvm_error("MAINT_TEST",
        $sformatf("Expected MAINTENANCE (8), got %0d", e.a.d.vif.curr_state))
    else
      `uvm_info("MAINT_TEST", "FSM correctly in MAINTENANCE state", UVM_LOW)

    // -----------------------------------------------
    // Step 2: Write fine_rate = 10 via config regs
    // -----------------------------------------------
    `uvm_info("MAINT_TEST", "Writing fine_rate = 10", UVM_LOW)
    e.a.d.vif.cfg_wr_en   = 1;
    e.a.d.vif.cfg_addr    = 2'd0;    // CFG_FINE_RATE
    e.a.d.vif.cfg_wr_data = 16'd10;
    @(posedge e.a.d.vif.clk);
    e.a.d.vif.cfg_wr_en   = 0;

    // -----------------------------------------------
    // Step 3: Write borrow_days = 7 via config regs
    // -----------------------------------------------
    `uvm_info("MAINT_TEST", "Writing borrow_days = 7", UVM_LOW)
    e.a.d.vif.cfg_wr_en   = 1;
    e.a.d.vif.cfg_addr    = 2'd1;    // CFG_BORROW_DAYS
    e.a.d.vif.cfg_wr_data = 16'd7;
    @(posedge e.a.d.vif.clk);
    e.a.d.vif.cfg_wr_en   = 0;

    // -----------------------------------------------
    // Step 4: Override book ID=7 via maintenance
    //         mark it unavailable with a due date
    // -----------------------------------------------
    `uvm_info("MAINT_TEST", "Overriding book_id=7 via maint write", UVM_LOW)
    e.a.d.vif.maint_book_wr_en  = 1;
    e.a.d.vif.maint_book_id     = 7'd7;
    e.a.d.vif.maint_book_avail  = 0;
    e.a.d.vif.maint_due_date    = 8'd20;
    @(posedge e.a.d.vif.clk);
    e.a.d.vif.maint_book_wr_en  = 0;

    // -----------------------------------------------
    // Step 5: Verify cfg write was blocked outside
    //         maint_mode by trying one now with
    //         maint_mode still high (should succeed)
    //         then exit and try again (should be ignored)
    // -----------------------------------------------
    `uvm_info("MAINT_TEST", "Verifying cfg write blocked outside maint", UVM_LOW)
    e.a.d.vif.maint_mode  = 0;
    e.a.d.vif.exit_maint  = 1;
    @(posedge e.a.d.vif.clk);
    e.a.d.vif.exit_maint  = 0;

    if (e.a.d.vif.curr_state !== 4'd0)
      `uvm_error("MAINT_TEST",
        $sformatf("Expected IDLE (0) after exit, got %0d", e.a.d.vif.curr_state))
    else
      `uvm_info("MAINT_TEST", "FSM back at IDLE after maintenance", UVM_LOW)

    // attempt cfg write outside maintenance - must be ignored
    e.a.d.vif.cfg_wr_en   = 1;
    e.a.d.vif.cfg_addr    = 2'd0;
    e.a.d.vif.cfg_wr_data = 16'd99;  // should NOT take effect
    @(posedge e.a.d.vif.clk);
    e.a.d.vif.cfg_wr_en   = 0;
    `uvm_info("MAINT_TEST",
      "cfg write attempted outside maint_mode - should be ignored by DUT", UVM_LOW)

    #20;

    `uvm_info("MAINT_TEST", "Maintenance test complete", UVM_LOW)

    phase.drop_objection(this);

  endtask

endclass

interface lib_if(input logic clk);

  logic rst_n;
  logic scan_book;
  logic issue_req;
  logic return_req;
  logic [6:0] book_id;
  logic [7:0] curr_date;

  // ADD THESE
  logic maint_mode;
  logic exit_maint;
  logic cfg_wr_en;
  logic [1:0] cfg_addr;
  logic [15:0] cfg_wr_data;
  logic maint_book_wr_en;
  logic [6:0] maint_book_id;
  logic maint_book_avail;
  logic [7:0] maint_due_date;
  logic error_detected;

  // outputs
  logic [15:0] fine_amount;
  logic print_receipt;
  logic [3:0] curr_state;

endinterface


module tb_top;


  logic clk;
  initial clk = 0;
  always #5 clk = ~clk;

  lib_if vif(clk);

top DUT (
  // =========================
  // CLOCK & RESET
  // =========================
  .clk(clk),
  .rst_n(vif.rst_n),

  // =========================
  // USER INTERFACE
  // =========================
  .scan_book(vif.scan_book),
  .issue_req(vif.issue_req),
  .return_req(vif.return_req),
  .book_id(vif.book_id),
  .curr_date(vif.curr_date),

  // =========================
  // MAINTENANCE INTERFACE
  // =========================
  .maint_mode(vif.maint_mode),
  .exit_maint(vif.exit_maint),
  .cfg_wr_en(vif.cfg_wr_en),
  .cfg_addr(vif.cfg_addr),
  .cfg_wr_data(vif.cfg_wr_data),
  .maint_book_wr_en(vif.maint_book_wr_en),
  .maint_book_id(vif.maint_book_id),
  .maint_book_avail(vif.maint_book_avail),
  .maint_due_date(vif.maint_due_date),

  // =========================
  // ERROR INPUT
  // =========================
  .error_detected(vif.error_detected),

  // =========================
  // OUTPUTS
  // =========================
  .fine_amount(vif.fine_amount),
  .print_receipt(vif.print_receipt),
  .curr_state(vif.curr_state)
);

initial begin
  vif.rst_n = 0;

  vif.maint_mode = 0;
  vif.exit_maint = 0;
  vif.cfg_wr_en = 0;
  vif.cfg_addr = 0;
  vif.cfg_wr_data = 0;
  vif.maint_book_wr_en = 0;
  vif.maint_book_id = 0;
  vif.maint_book_avail = 0;
  vif.maint_due_date = 0;
  vif.error_detected = 0;

  #20;
  vif.rst_n = 1;
end
  

  initial begin
    uvm_config_db#(virtual lib_if)::set(null, "*", "vif", vif);
    run_test("stress_test");
  end

endmodule
