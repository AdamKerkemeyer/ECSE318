library ieee; use ieee.std_logic_1164.all;

entity cache is
    port (
        Pstrobe, Prw, clk : in std_logic;
        Paddress : in std_logic_vector (15 downto 0);
        Sysaddress : out std_logic_vector (15 downto 0);
        Pready, Systrobe, Sysrw : out std_logic;
        Pdata : inout std_logic_vector (31 downto 0);
        Sysdata : inout std_logic_vector (7 downto 0)
    );
end cache;

entity ram is
    port (
        clk, Sysrw : in std_logic;
        Sysaddress : in std_logic_vector (15 downto 0);
        Sysdata : inout std_logic_vector (7 downto 0)
    );
end ram;

entity fakeProcessor is
end fakeProcessor;

architecture spec of cache is
    type cacheDataArray is array (255 downto 0) of std_logic_vector (31 downto 0);
    type cacheTagsArray is array (255 downto 0) of std_logic_vector (5 downto 0);

    signal cacheData : cacheDataArray; --holds all the data in the cache
    signal cacheTags : cacheTagsArray; --holds all the tags
    signal chit : std_logic; --true if currently getting a cache hit
    signal Pdata_out : std_logic_vector (31 downto 0);
    signal Sysdata_out : std_logic_vector (7 downto 0);
    signal waitCycle : std_logic_vector (1 downto 0);

begin

    --tristate logic hadling:
    Pdata <= Pdata_out when Prw = '1' else 'Z';
    Sysdata <= Sysdata_out when Sysrw = '0' else 'Z';

    cacheCycle : process(clk) is
    begin
        if (clk'event and clk = '1') then
            if (Pstrobe = '1' and Pready) then --New request, Use Pready as a flag for when we are in a memory loop
                chit <= or(Paddress(15 downto 10) xor cacheTags(Paddress(9 downto 2))); --Check for a cache hit (correct data is in cache)
                wait on chit;
                if (chit and Prw) then --read from cache
                    Pdata_out <= cacheData(Paddress(9 downto 2));
                    Pready <= '1';
                else--need to access memory
                    Pready <='0';
                    Systrobe <= '1';
                    Sysrw <= Prw;
                    waitCycle <= '11';
                    wait on waitCycle;
                    Sysaddress <= Paddress(15 downto 2) & 'waitCycle'; --have to assign like this becuase remeber that all vars are intitialized at the end
                    if (not Prw) then
                        cacheData(Paddress(9 downto 2)) <= Pdata; --Write to cache
                        Sysdata_out <= Pdata(31 downto 24); --Write first byte to ram
                    end if;
                end if;
            elsif (not Pready) then --Now we are in a memory cycle
                Ststrobe <= '0';
                if (Sysrw) then --reading from memory
                    case waitCycle is 
                        when '11' => cacheData(Sysaddress(9 downto 2))(31 downto 24) <= Sysdata;
                            waitCycle <= '10';
                        when '10' => cacheData(Sysaddress(9 downto 2))(23 downto 16) <= Sysdata;
                            waitCycle <= '01';
                        when '01' => cacheData(Sysaddress(9 downto 2))(15 downto 8) <= Sysdata;
                            waitCycle <= '00';  
                        when '00' => cacheData(Sysaddress(9 downto 2))(7 downto 0) <= Sysdata;
                            wait on cacheData;
                            Pready <= '1';
                            Pdata_out <= cacheData(Sysaddress(9 downto 2));
                    end case;
                else --writing to memory and cache
                    case waitCycle is
                        when '11' => waitCycle <= '10';
                            wait on waitCycle;
                            Sysaddress <= Sysaddress(15 downto 2) & waitCycle;
                            Sysdata_out <= cacheData(Sysaddress(9 downto 2))(23 downto 16);
                        when '10' => waitCycle <= '01';
                            wait on waitCycle;
                            Sysaddress <= Sysaddress(15 downto 2) & waitCycle;
                            Sysdata_out <= cacheData(Sysaddress(9 downto 2))(15 downto 8);
                        when '01' => waitCycle <= '00';
                            wait on waitCycle;
                            Sysaddress <= Sysaddress(15 downto 2) & waitCycle;
                            Sysdata_out <= cacheData(Sysaddress(9 downto 2))(7 downto 0);
                            Pready <= '1';
                    end case;
                end if;
            end if;
        end if;
    end process cacheCycle;
end spec;

architecture ramspec of ram is
    type ramDataArray is array (16383 downto 0) of std_logic_vector (31 downto 0);

    signal ramData : ramDataArray;  --65mB of ram lol
    signal Sysdata_out : std_logic_vector (7 downto 0);
begin
    Sysdata <= Sysdata_out when Sysrw = '1' else 'Z';--tri state handling

    ramCycle : process (clk) is
    begin
    if (clk'event and clk = '1') then
        if (Sysrw) then --read from ram, (write to bus)
            case Sysaddress(1 downto 0) is 
                when '11' => Sysdata_out <= ramData(Sysaddress(15 downto 2))(31 downto 24);
                when '10' => Sysdata_out <= ramData(Sysaddress(15 downto 2))(23 downto 16);
                when '01' => Sysdata_out <= ramData(Sysaddress(15 downto 2))(15 downto 8);
                when '00' => Sysdata_out <= ramData(Sysaddress(15 downto 2))(7 downto 0);
            end case;
        else --write to ram (read from bus)
            case Sysaddress(1 downto 0) is 
                when '11' => ramData(Sysaddress(15 downto 2))(31 downto 24) <= Sysdata;
                when '10' => ramData(Sysaddress(15 downto 2))(23 downto 16) <= Sysdata;
                when '01' => ramData(Sysaddress(15 downto 2))(15 downto 8) <= Sysdata;
                when '00' => ramData(Sysaddress(15 downto 2))(7 downto 0) <= Sysdata;
            end case;
        end if;
    end if;
    end process ramCycle;
end ramspec;

architecture fakeProcessorSpec of fakeProcessor is --really just a testbench for the cache

    component ram is
        port(
            clk, Sysrw : in std_logic;
            Sysaddress : in std_logic_vector (15 downto 0);
            Sysdata : inout std_logic_vector (7 downto 0);
        );
    end component;

    component cache is
        port (
            Pstrobe, Prw, clk : in std_logic;
            Paddress : in std_logic_vector (15 downto 0);
            Sysaddress : out std_logic_vector (15 downto 0);
            Pready, Systrobe, Sysrw : out std_logic;
            Pdata : inout std_logic_vector (31 downto 0);
            Sysdata : inout std_logic_vector (7 downto 0);
        );
    end component;

    signal Pstrobe, Prw, clk, Pready, Systrobe, Sysrw : std_logic;
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
            Sysaddress => Sysaddress,
            Pready => Pready,
            Systrobe => Systrobe,
            Sysrw => Sysrw,
            Pdata => Pdata,
            Sysdata => Sysdata
        );


    --tristate logic hadling:
    Pdata <= Pdata_out when Prw = '0' else 'Z';

    clkgen : process is
    begin
        clk <= not clk;
        wait for 50 ns;
    end process clkgen;

    stimulus : process is
    begin
        clk <= '0';
        Prw <= '0';
        Pstrobe <= '0';
        Pdata_out <= x"00000000";
        Paddress <= x"0000";
        wait for 50 ns;
        Prw <= '0';
        Pstrobe <= '1';
        Pdata_out <= x"00000001";
        Paddress <= x"0001";
        wait for 100 ns;
        report "all tests finished";
    end process stimulus;
end fakeProcessorSpec;

