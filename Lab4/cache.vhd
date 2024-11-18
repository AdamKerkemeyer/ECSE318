library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;

entity cache is
    port (
        Pstrobe, Prw, clk : in std_logic;
        Paddress : in std_logic_vector (15 downto 0);
        Sysaddress_o : out std_logic_vector (15 downto 0);
        Pready_o, Systrobe_o, Sysrw_o : out std_logic;
        Pdata : inout std_logic_vector (31 downto 0);
        Sysdata : inout std_logic_vector (7 downto 0)
    );
end cache;

library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;

entity ram is
    port (
        clk, Sysrw : in std_logic;
        Sysaddress : in std_logic_vector (15 downto 0);
        Sysdata : inout std_logic_vector (7 downto 0)
    );
end ram;

library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;

entity fakeProcessor is
end fakeProcessor;

architecture spec of cache is
    type cacheDataArray is array (255 downto 0) of std_logic_vector (31 downto 0);
    type cacheTagsArray is array (255 downto 0) of std_logic_vector (5 downto 0);

    signal cacheData : cacheDataArray := (others => x"00000000"); --holds all the data in the cache
    signal cacheTags : cacheTagsArray := (others => B"000000"); --holds all the tags
    signal chit, Sysrw, Systrobe  : std_logic; --true if currently getting a cache hit
    signal Pready : std_logic := '1';
    signal Pdata_out : std_logic_vector (31 downto 0);
    signal Sysdata_out : std_logic_vector (7 downto 0);
    signal waitCycle : std_logic_vector (1 downto 0);
    signal Sysaddress : std_logic_vector (15 downto 0) := x"0000";

begin

    --tristate logic hadling:
    Pdata <= Pdata_out when Prw = '1' else "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
    Sysdata <= Sysdata_out when Sysrw = '0' else "ZZZZZZZZ";

    Sysrw_o <= Sysrw;
    Pready_o <= Pready;
    Systrobe_o <= Systrobe;
    Sysaddress_o <= Sysaddress;

    chit <= '0' when ((Paddress(15 downto 10) xor cacheTags(to_integer(unsigned(Paddress(9 downto 2))))) = x"00" )else '1'; --Check for a cache hit (correct data is in cache)
    
    cacheCycle : process is
    begin
    if (clk'event and clk = '1') then
        if ((Pstrobe AND Pready) = '1') then --New request, Use Pready as a flag for when we are in a memory loop
            if ((chit and Prw) = '1') then --read from cache
                report "reading cache";
                Pdata_out <= cacheData(to_integer(unsigned(Paddress(9 downto 2))));
                Pready <= '1';
            else--need to access memory
                Pready <='0';
                Systrobe <= '1';
                Sysrw <= Prw;
                waitCycle <= B"11";
                Sysaddress <= Paddress(15 downto 2) & B"11"; --have to assign like this becuase remeber that all vars are intitialized at the end
                cacheTags(to_integer(unsigned(Paddress(9 downto 2)))) <= Paddress(15 downto 10); --update cache tags
                if ((not Prw) = '1') then
                    cacheData(to_integer(unsigned(Paddress(9 downto 2)))) <= Pdata; --Write to cache
                    Sysdata_out <= Pdata(31 downto 24); --Write first byte to ram
                end if;
            end if;
        elsif ((not Pready) = '1') then --Now we are in a memory cycle
            Systrobe <= '0';
            if (Sysrw = '1') then --reading from memory
                report "reading memory";
                case waitCycle is 
                    when B"11" => cacheData(to_integer(unsigned(Sysaddress(9 downto 2))))(31 downto 24) <= Sysdata;
                        waitCycle <= B"10";
                    when B"10" => cacheData(to_integer(unsigned(Sysaddress(9 downto 2))))(23 downto 16) <= Sysdata;
                        waitCycle <= B"01";
                    when B"01" => cacheData(to_integer(unsigned(Sysaddress(9 downto 2))))(15 downto 8) <= Sysdata;
                        waitCycle <= B"00";  
                    when B"00" => cacheData(to_integer(unsigned(Sysaddress(9 downto 2))))(7 downto 0) <= Sysdata;
                        wait on cacheData;
                        Pready <= '1';
                        Pdata_out <= cacheData(to_integer(unsigned(Sysaddress(9 downto 2))));
                    when others => report "error in reading from memory";
                end case;
            else --writing to memory and cache
                report "writing to memory";
                case waitCycle is
                    when B"11" => waitCycle <= B"10";
                        Sysaddress <= Sysaddress(15 downto 2) & B"10";
                        Sysdata_out <= cacheData(to_integer(unsigned(Sysaddress(9 downto 2))))(23 downto 16);
                    when B"10" => waitCycle <= B"01";
                        Sysaddress <= Sysaddress(15 downto 2) & B"01";
                        Sysdata_out <= cacheData(to_integer(unsigned(Sysaddress(9 downto 2))))(15 downto 8);
                    when B"01" => waitCycle <= B"00";
                        Sysaddress <= Sysaddress(15 downto 2) & B"00";
                        Sysdata_out <= cacheData(to_integer(unsigned(Sysaddress(9 downto 2))))(7 downto 0);
                    when B"00" => Pready <= '1';
                    when others => report "error in witing to memory";
                end case;
            end if;
        end if;
    end if;
    wait on clk;
    end process cacheCycle;
end spec;

architecture ramspec of ram is
    type ramDataArray is array (16383 downto 0) of std_logic_vector (31 downto 0);

    signal ramData : ramDataArray;  --65mB of ram nice
    signal Sysdata_out : std_logic_vector (7 downto 0);
begin
    Sysdata <= Sysdata_out when Sysrw = '1' else "ZZZZZZZZ";--tri state handling

    ramCycle : process is
    begin
    if (clk'event and clk = '1') then
        if (Sysrw = '1') then --read from ram, (write to bus)
            case Sysaddress(1 downto 0) is 
                when B"11" => Sysdata_out <= ramData(to_integer(unsigned(Sysaddress(15 downto 2))))(31 downto 24);
                when B"10" => Sysdata_out <= ramData(to_integer(unsigned(Sysaddress(15 downto 2))))(23 downto 16);
                when B"01" => Sysdata_out <= ramData(to_integer(unsigned(Sysaddress(15 downto 2))))(15 downto 8);
                when B"00" => Sysdata_out <= ramData(to_integer(unsigned(Sysaddress(15 downto 2))))(7 downto 0);
                when others => report "Error in ram read";
            end case;
        else --write to ram (read from bus)
            case Sysaddress(1 downto 0) is 
                when B"11" => ramData(to_integer(unsigned(Sysaddress(15 downto 2))))(31 downto 24) <= Sysdata;
                when B"10" => ramData(to_integer(unsigned(Sysaddress(15 downto 2))))(23 downto 16) <= Sysdata;
                when B"01" => ramData(to_integer(unsigned(Sysaddress(15 downto 2))))(15 downto 8) <= Sysdata;
                when B"00" => ramData(to_integer(unsigned(Sysaddress(15 downto 2))))(7 downto 0) <= Sysdata;
                when others => report "Error in ram write";
            end case;
        end if;
    end if;
    wait on clk;
    end process ramCycle;
end ramspec;

architecture fakeProcessorSpec of fakeProcessor is --really just a testbench for the cache

    component ram is
        port(
            clk, Sysrw : in std_logic;
            Sysaddress : in std_logic_vector (15 downto 0);
            Sysdata : inout std_logic_vector (7 downto 0)
        );
    end component;

    component cache is
        port (
            Pstrobe, Prw, clk : in std_logic;
            Paddress : in std_logic_vector (15 downto 0);
            Sysaddress_o : out std_logic_vector (15 downto 0);
            Pready_o, Systrobe_o, Sysrw_o : out std_logic;
            Pdata : inout std_logic_vector (31 downto 0);
            Sysdata : inout std_logic_vector (7 downto 0)
        );
    end component;

    signal Pstrobe, Prw, Pready, Systrobe, Sysrw : std_logic;
    signal clk : std_logic := '0';
    signal Paddress, Sysaddress : std_logic_vector (15 downto 0);
    signal Sysdata : std_logic_vector (7 downto 0);
    signal Pdata, Pdata_out : std_logic_vector (31 downto 0);

begin

    uRam : ram
        port map (
            clk, Sysrw, Sysaddress, Sysdata
        );

    uut : cache
        port map(
            Pstrobe => Pstrobe,
            Prw => Prw,
            clk => clk,
            Paddress => Paddress,
            Sysaddress_o => Sysaddress,
            Pready_o => Pready,
            Systrobe_o => Systrobe,
            Sysrw_o => Sysrw,
            Pdata => Pdata,
            Sysdata => Sysdata
        );


    --tristate logic hadling:
    Pdata <= Pdata_out when Prw = '0' else "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";

    clkgen : process is
    begin
        clk <= not clk;
        wait for 50 ns;
    end process clkgen;

    stimulus : process is
    begin
        Prw <= '0';
        Pstrobe <= '0';
        Pdata_out <= x"00000000";
        Paddress <= x"0000";
        wait for 50 ns;
        Prw <= '0';
        Pstrobe <= '1';
        Pdata_out <= x"00000001";
        Paddress <= x"0000";
        wait for 100 ns;
        Pstrobe <= '0';
        wait on Pready;
        Pstrobe <= '1';
        Prw <= '1';
        wait for 500 ns;
        assert false report "test finished" severity failure;
    end process stimulus;
end fakeProcessorSpec;

