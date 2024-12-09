#ifndef SIM_H
#define SIM_H

#include "Gate_SIM.hpp"
#include <array>
#include <string>
#include <memory>
#include <unordered_map>
#include <climits>

//   0  1  X
// 0 r  r  r
// 1 r  r  r
// X r  r  r


const logic andTable[3][3] = {
    {logic::zero, logic::zero,logic::zero},
    {logic::zero, logic::one, logic::X},
    {logic::zero, logic::X,   logic::X}
};

const logic orTable[3][3] = {
    {logic::zero,logic::one, logic::X},
    {logic::one, logic::one, logic::one},
    {logic::X,   logic::one, logic::X}
};

const logic xorTable[3][3] = {
    {logic::zero,logic::one,  logic::X},
    {logic::one, logic::zero, logic::X},
    {logic::X,   logic::X,    logic::X}
};

const logic notTable[3] = {logic::one, logic::zero, logic::X};


enum class SimType {
    Table,
    InputScan
};

class Simulator{
    public:
        Simulator();
        //void runSim();//Top level function. Call to begin running the simulation
        //std::vector<logic> runCycle(std::vector<char>*);//Runs a single clock cycle. Returns list of output values, dff vals are stored in the dffs themselves
        void printGates(); //Prints the Gates datastructure to the terminal for debugging
        void printStimulus();//Prints the Stimulus datastruture to the terminal for debugging
        void SimulateTable();//Simulates the circuit with table lookup
        
    private:
        std::unique_ptr<std::vector<Gate>> Gates; //Each top level is a list of the gates of a given level
        std::unique_ptr<std::vector<std::vector<logic>>> stimulus; //Each entry in the top vector is a line. Then each line is just an array of chars
        std::unordered_map<std::string, GateType> gateTypeMap;//reference type for switching between gatetype and string
        std::vector<unsigned int> levels;     //Holds the first (most recently) scheduled gate for each level
        std::vector<unsigned int> nextLevels; //Dffs schedule their fanouts here, then at the end of cycle copy  this to levels
        std::vector<unsigned int> inputs;  //pointers to all the input gates
        std::vector<unsigned int> outputs; //pointers to all the output gates for printing
        std::vector<unsigned int> dffs;    //pointers to all the dff gates for printing
        const unsigned int dummyGate = UINT_MAX;//If the sched points here, this gate isn't scheduled.
        const unsigned int lastGate = UINT_MAX -1;//If the sched point here, This gate will terminate evalution of a level

        std::vector<std::string> gateData(const std::string& target, std::string& line);//returns a string of the value, modifies the line to take out the value
        void addToList(const std::shared_ptr<Gate>& gate);//Adds the gate to Gates, and initializes top level size of Gates array correctly. DOES NOT LINK BUFFERS
        void initializeGateTypeMap();//Intializes the gatemap refernece for quick gatetype to string conversions
        bool initializeGates();//loads gates from file to Gates array, returns true if successful
        bool initializeStimulus();//Loads stimulus from file into stimulus array
        GateType stringToGateType(const std::string& typeStr);//turns a string into a gatetype
        char logicToChar(const logic& val); //Turns a logic into a character for printing.
        void reportStates(const std::vector<unsigned int>& array); //Takes an inputs/outputs/dffs array and prints the states of those gates
        void printLevels();//prints the levels array to the console

        //functions for simulation:
        void scheduleFannout(const unsigned int& gate);//schedules the fanout of gate
        //Table lookup Simulations
        void simCycleTable(const unsigned int& simpos); //simulates a full cycle (all of the levels)
        void simLevelTable(const unsigned int& level);//Simluate a given level
        void evaluteTable(const unsigned int& gate); //Evaluates a gate with a table lookup
        void evaluteScan(const unsigned int& gate);  //Evaluetes a gate with an input scan
        
};  

#endif