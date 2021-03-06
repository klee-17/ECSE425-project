LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE STD.textio.all;
USE ieee.std_logic_textio.all;

entity DataMem is
    GENERIC(
		ram_size : INTEGER := 32768
	);
    port(
         	clock: in std_logic;
         	opcode: in std_logic_vector(5 downto 0):=(others => '0');
         	dest_addr_in: in std_logic_vector(4 downto 0):=(others => '0');
         	ALU_result: in std_logic_vector(31 downto 0):=(others => '0');
         	rt_data: in std_logic_vector(31 downto 0):=(others => '0');
	     	bran_taken: in std_logic;  -- from mem
	     	bran_addr_in: in std_logic_vector(31 downto 0):=(others => '0');  -- new added 
	     	MEM_control_buffer: in std_logic_vector(5 downto 0):=(others => '0');
	     	WB_control_buffer : in std_logic_vector(5 downto 0):=(others => '0');
	    
	     	MEM_control_buffer_out: out std_logic_vector(5 downto 0):=(others => '0'); --for ex forward 
	     	WB_control_buffer_out : out std_logic_vector(5 downto 0):=(others => '0'); -- for wb stage 
         
	     	mem_data: out std_logic_vector(31 downto 0):=(others => '0');
         	ALU_data: out std_logic_vector(31 downto 0):=(others => '0');
         	dest_addr_out: out std_logic_vector(4 downto 0):=(others => '0');
        	bran_addr: out std_logic_vector(31 downto 0):=(others => '0'); -- for if 
	     	bran_taken_out: out std_logic:= '0';                -- for if 
	     	write_reg_txt: in std_logic := '0'; -- indicate program ends-- from testbench
	    

                 mem_data_stall_in: in std_logic;
                 mem_data_stall: out std_logic:='0';

		--cachestartworkting: out std_logic := '0'; -- inform data cache start to work
		s_addr_data:out integer:= 0; -- send address to cache
		s_read_data: out std_logic:='0'; -- send read signal to cache
		s_readdata_data: in std_logic_vector(31 downto 0); -- get data from cache
		s_write_data: out std_logic:='0'; -- send write signal to cache
		s_writedata_data: out std_logic_vector(31 downto 0):=(others => '0');-- send the writedata to cache
		s_waitrequest_data: in std_logic := '0' --get waitrequest signal from cache
                 
			
         );
end DataMem;

architecture behavior of DataMem is
    	signal cachework: std_logic := '0';
	signal writing: std_logic := '0';
	signal reading: std_logic := '0';
begin
 MEM_control_buffer_out<= MEM_control_buffer;
 	 bran_addr <= bran_addr_in;
 
      extra:process(ALU_result)
      begin
        if(mem_data_stall_in  = '0')then 
        s_addr_data <= to_integer(unsigned( ALU_result));
         end if;
      end process;
     process(clock,s_waitrequest_data)
     begin
	
       if(rising_edge(clock))then
		dest_addr_out <= dest_addr_in;
          
          	bran_taken_out<= bran_taken;
		
        
        		-- the opcode is for branch
        		--if(opcode = "000101" or opcode = "000100")then
        
        	------ the opcode is sw -----
        	if(opcode = "101011")then                  		
   -- bran_addr <= std_logic_vector(to_unsigned(0, 32));
			if(cachework = '0') then
				
				s_writedata_data <= rt_data;
				s_write_data <= '1';
         			cachework <= '1';
				writing <= '1';
			end if;
			
       		------ the opcode is lw -----
        	elsif(opcode = "100011")then     
			if(cachework = '0') then
       			--  bran_addr <= std_logic_vector(to_unsigned(0, 32));
				s_read_data <= '1';
				cachework <= '1';
				reading <= '1';
			end if;
        	------ the opcode is other -----
        	else
       		-- bran_addr <= std_logic_vector(to_unsigned(0, 32));
        	ALU_data <= ALU_result;
        	end if;
			
	elsif(falling_edge(clock))then
		WB_control_buffer_out<= WB_control_buffer;
		s_write_data <= '0';
                s_read_data <= '0';
                if((opcode = "101011" or opcode = "100011") and  s_waitrequest_data = '1')  then
                        mem_data_stall <= '1';       
                 end if;

	end if;
	 				
       
        if(falling_edge(s_waitrequest_data))then 

              if( writing = '1') then
                                mem_data_stall <= '0';         
				writing <= '0';
				cachework <= '0';
	      elsif(reading = '1') then
                                mem_data_stall <= '0';     
				mem_data <= s_readdata_data;
				cachework <= '0';
				reading <= '0';
		end if;
         end if;
     


    end process;
	  	
end behavior;
