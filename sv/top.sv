package pkg_lib;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  typedef class port_cfg;
  typedef class chip_cfg;
  typedef class visitor;

  interface class reg_cfg;
    pure virtual function void accept (visitor v);
  endclass

  class port_cfg extends uvm_reg implements reg_cfg;

    rand uvm_reg_field adc_cfg;
    rand uvm_reg_field dac_cfg;

    `uvm_object_utils(port_cfg)

    function new (string name = "port_cfg");
      super.new(.name(name),.n_bits(8),.has_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
      adc_cfg=uvm_reg_field::type_id::create("adc_cfg");
      adc_cfg.configure (
        .parent(this),
        .size(4),
        .lsb_pos(0),
        .access("RW"),
        .volatile(0),
        .reset(0),
        .has_reset(1),
        .is_rand(1),
        .individually_accessible(0)
      );
      dac_cfg=uvm_reg_field::type_id::create("dac_cfg");
      dac_cfg.configure (
        .parent(this),
        .size(4),
        .lsb_pos(4),
        .access("RW"),
        .volatile(0),
        .reset(0),
        .has_reset(1),
        .is_rand(1),
        .individually_accessible(0)
      );
    endfunction

    virtual function void accept (visitor v);
      v.visit_port_cfg(this);
    endfunction

    virtual function string convert2string();
      string s=super.convert2string();
      return s;
    endfunction

  endclass

  class chip_cfg extends uvm_reg implements reg_cfg;

    rand uvm_reg_field pwr_cfg;
    rand uvm_reg_field prio_cfg;

    `uvm_object_utils(chip_cfg)

    function new (string name = "chip_cfg");
      super.new(.name(name),.n_bits(8),.has_coverage(UVM_NO_COVERAGE));
    endfunction

    virtual function void build();
      pwr_cfg=uvm_reg_field::type_id::create("pwr_cfg");
      pwr_cfg.configure(.parent(this),.size(4),.lsb_pos(0),.access("RW"),.volatile(0),.reset(0),.has_reset(1),.is_rand(1),.individually_accessible(0));
      prio_cfg=uvm_reg_field::type_id::create("prio_cfg");
      prio_cfg.configure(.parent(this),.size(4),.lsb_pos(4),.access("RW"),.volatile(0),.reset(0),.has_reset(1),.is_rand(1),.individually_accessible(0));
    endfunction

    virtual function void accept (visitor v);
      v.visit_chip_cfg(this);
    endfunction

    virtual function string convert2string();
      string s=super.convert2string();
      return s;
    endfunction

  endclass

  class chip_reg_block extends uvm_reg_block;

    rand port_cfg m_port_control;
    rand chip_cfg m_chip_control;
    uvm_reg_map       reg_map;

    `uvm_object_utils(chip_reg_block)

    function new(string name = "chip_reg_block");
      super.new(.name(name),.has_coverage(UVM_NO_COVERAGE)) ;
    endfunction: new

    virtual function void build();

      m_port_control = port_cfg::type_id::create("m_port_control") ;
      m_port_control.configure(.blk_parent(this));
      m_port_control.build();

      m_chip_control = chip_cfg::type_id::create("m_chip_control");
      m_chip_control.configure(.blk_parent(this));
      m_chip_control.build();

      reg_map = create_map(.name("reg_map"),.base_addr(8'h00),.n_bytes(1),.endian(UVM_LITTLE_ENDIAN));
      reg_map.add_reg(.rg(m_port_control),.offset(8'h00),.rights("RW"));
      reg_map.add_reg(.rg(m_chip_control), .offset( 8'h01 ), .rights("RW"));
      lock_model();

    endfunction: build

  endclass

  class chip_env extends uvm_env;

    chip_reg_block m_chip_reg_block;

    `uvm_component_utils(chip_env)

    function new (string name, uvm_component parent);
      super.new(name,parent);
    endfunction

    function void build_phase (uvm_phase phase);
      super.build_phase(phase);
      m_chip_reg_block=chip_reg_block::type_id::create("m_chip_reg_block", this);
      m_chip_reg_block.build();
    endfunction

  endclass

  virtual class visitor;
    pure virtual function void visit_port_cfg (port_cfg pc);
    pure virtual function void visit_chip_cfg (chip_cfg cc);
  endclass

  class reg_cfg_scenario_a extends visitor;
    virtual function void visit_port_cfg (port_cfg pc);
      pc.adc_cfg.set(64'hA);
      pc.dac_cfg.set(64'hF);
    endfunction

    virtual function void visit_chip_cfg (chip_cfg cc);
      cc.pwr_cfg.set(64'hB);
      cc.prio_cfg.set(64'hC);
    endfunction
  endclass

  class visitor_test extends uvm_test;

    chip_env m_chip_env;

    `uvm_component_utils(visitor_test)

    function new (string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase (uvm_phase phase);
      super.build_phase(phase);
      m_chip_env=chip_env::type_id::create("m_chip_env", this);
    endfunction

    task run_phase (uvm_phase phase);
      uvm_reg regs[$];
      reg_cfg_scenario_a visit=new;
      m_chip_env.m_chip_reg_block.get_registers(regs);

      // Print desired value before visit
      $display("**************************************");
      $display(" Registers desired value before visit\n");
      foreach (regs[idx]) begin
        $display("%s\n",regs[idx].convert2string());
      end
      $display("**************************************\n\n");


      // Apply visitor on all registers
      foreach (regs[idx]) begin
        reg_cfg r;
        $cast(r, regs[idx]);
        r.accept(visit);
      end

      // Print desired value after visit
      $display("**************************************");
      $display(" Registers desired value after visit\n");
      foreach (regs[idx]) begin
        $display("%s\n",regs[idx].convert2string());
      end
      $display("**************************************\n\n");

    endtask

  endclass

endpackage
module top;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import pkg_lib::*;

  initial run_test("visitor_test");
endmodule

