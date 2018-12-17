  //|<tag bits = 24>|<set index bits = 2>|<offset = 6>| //total bits: 32
  parameter CACHE_OFFSET_BITS = $clog2(CACHE_LINE_SIZE); //should be 6 as cache line is 64B
  parameter CACHE_LINE_SIZE = 64;
  parameter CACHE_SIZE = 512;  
  parameter CACHE_SET_BITS = 2; //4 set indexes
  parameter CACHE_LINE_BITS = 3; //8 cache index lines
  parameter CACHE_NUM_SETS = 1 << CACHE_SET_BITS; //2**CACHE_SET_BITS;  
  parameter CACHE_TAG_BITS = 32-CACHE_SET_BITS-CACHE_OFFSET_BITS;
  parameter CACHE_NUM_LINES = CACHE_SIZE/CACHE_LINE_SIZE;

// This is the class that we will randomize.
class my_item;
  
  parameter NUM_BITS = 8;
  parameter MEM_SIZE = 500;
  parameter l = 80;

  rand int unsigned m_arr[NUM_BITS];
  rand int unsigned m_arr2[NUM_BITS];

  rand bit [999:0] m_arr3;

  rand int m_mem[10];

  rand reg [CACHE_LINE_SIZE-1:0] m_cache[CACHE_NUM_SETS-1:0];
  rand bit [CACHE_TAG_BITS-1:0] m_cache_tag_ram[CACHE_NUM_LINES-1:0];
  rand bit m_cache_valid_bit_ram[CACHE_NUM_LINES-1:0];
  rand bit [31:0] addr;

  int test_me;  
  
  // Randomization constraints.
  constraint c_desc 
  {
    foreach(m_arr[i])
      if(i > 0)
        m_arr[i] < m_arr[i-1];
  }

  constraint c_asc 
  {    
    foreach(m_arr[i])
      if(i > 0)
        m_arr[i] > m_arr[i-1];
      //or
      //m_arr[i] < m_arr[i+1];    
  }  
  
  constraint c_ind_elements 
  {
    foreach(m_arr[i])
      (m_arr[i] % 15) == 0;//$urandom();//$random;//> m_arr[i+1];
  }  

  constraint c_a_less_than_b_sb 
  {    
    solve m_arr2 before m_arr;
  }  
  
  constraint c_a_less_than_b 
  {    
    foreach(m_arr[i])
      m_arr[i] < m_arr2[i];      
  }
  
  constraint c_a_less_than_b_plus_one 
  {    
    foreach(m_arr[i])
      if (i > 0)
        m_arr[i-1] < m_arr2[i];      
  }      
  
  constraint c_dist 
  {    
    foreach(m_arr[i])
      m_arr[i] dist {[10:2000] :/ 90, [0:9] :/ 5, [2000:$] :/ 5};      
  };

  constraint c_bit_dist 
  {    
    foreach(m_arr3[i])
      m_arr3[i] dist {1 := 10, 0 := 990};
  };  

  constraint c_sizes
  {    
    foreach(m_mem[i])
      m_mem[i] <= l && m_mem[i] >= 0;
  };
  
  constraint c_size_sum
  {    
    m_mem.sum() == MEM_SIZE;
  }

  // Print out the items.
  function void print();
    foreach(m_arr[i])
      $display("m_arr[%0d]:%0d\tm_arr2[%0d]:%0d", i, m_arr[i], i, m_arr2[i]);
  endfunction

  function void print_arr3();
    $display("m_arr3:%b", m_arr3);    
  endfunction

  function void print_mem();
    foreach(m_mem[i])
      $display("m_mem:%d", m_mem[i]);    
  endfunction  
  
  function void pre_randomize();
    $display("Beginning Randomization...");
  endfunction    
  
  function void post_randomize();
    $display("Randomization done!");
  endfunction  
  
endclass

module tb;
  
  bit [999:0] x;
  
  function void gen_ones();
    x |= ((10'b1111111111) << $urandom_range(0,990));
  endfunction
  
  function void run;
    my_item item = new();
    //$display("INITIAL");
    //item.print();
    item.c_ind_elements.constraint_mode(0); //test
    item.c_desc.constraint_mode(0); //disable descending order sort
    item.c_asc.constraint_mode(0); //disable ascending order sort
    item.c_a_less_than_b_sb.constraint_mode(0);
    item.c_a_less_than_b.constraint_mode(0);
    item.c_a_less_than_b_plus_one.constraint_mode(0);
    item.c_dist.constraint_mode(0);
    
    item.c_bit_dist.constraint_mode(1);    
    
    //for (int i = 0; i < 5; i++) begin
      //$display("NORMAL RANDOMIZE %0d", i);
      $display("NORMAL RANDOMIZE");
      item.randomize();
      item.print();
    $display("Printing Array with 10 1s with Uniform Distribution...");
    $display("Dimensions of Array 3 are: %d", $dimensions(item.m_arr3));
      item.print_arr3();
      $display("End of Printing Array 3...");
    //end
    
    $display("Printing Array with 10 bits of 1s next to each other...");    
    gen_ones();
    $display("%b", x);

    $display("Printing Split-Memory Sizes...");    
    item.constraint_mode(0);
    item.c_sizes.constraint_mode(1);    
    item.c_size_sum.constraint_mode(1);    
    item.print_mem();

    $display("Generating a Randomized Cache Location and Printing Data @ that Location...");    
    if(item.m_cache_valid_bit_ram[item.addr[(CACHE_OFFSET_BITS+CACHE_LINE_BITS-1):CACHE_OFFSET_BITS]] == 1'b1) //valid bit set?
      if(item.addr[31:(CACHE_OFFSET_BITS+CACHE_LINE_BITS)] == item.m_cache_tag_ram[item.addr[(CACHE_OFFSET_BITS+CACHE_LINE_BITS-1):CACHE_OFFSET_BITS]]) //tag match?
        $display("Data found: %b", item.m_cache[item.addr[(CACHE_OFFSET_BITS+CACHE_SET_BITS-1):CACHE_OFFSET_BITS]]);

    /*
    $display("RANDOMIZE WITH");
    item.randomize() with {
      m_int == 1000;
    };
    item.print();
    */
  endfunction
  
  initial run();
  
endmodule
