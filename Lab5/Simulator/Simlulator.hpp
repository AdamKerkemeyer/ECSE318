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

/*not ready yet, commented out to compile
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

logic inputScanEvaluate();
logic tableEvaluate();


logic checkTable(const GateType& type, const logic& in1, const logic& in2){//evaulates two gates based on table lookup
    switch(type){
        case GateType::AND:
            return andTable[static_cast<int>(in1)][static_cast<int>(in2)];
        case GateType::OR:
            return orTable[static_cast<int>(in1)][static_cast<int>(in2)];
        case GateType::NOT:
            return notTable[static_cast<int>(in1)];
        case GateType::NOR:
            return notTable[static_cast<int>(orTable[static_cast<int>(in1)][static_cast<int>(in2)])];
        case GateType::NAND:
            return notTable[static_cast<int>(andTable[static_cast<int>(in1)][static_cast<int>(in2)])];
    }
}
*/

class Simulator{
    public:
        Simulator();
        //void runSim();//Top level function. Call to begin running the simulation
        //std::vector<logic> runCycle(std::vector<char>*);//Runs a single clock cycle. Returns list of output values, dff vals are stored in the dffs themselves
        void printGates(); //Prints the Gates datastructure to the terminal for debugging
        void printStimulus();//Prints the Stimulus datastruture to the terminal for debugging
    private:
        std::unique_ptr<std::vector<Gate>> Gates; //Each top level is a list of the gates of a given level
        std::unique_ptr<std::vector<std::vector<char>>> stimulus; //Each entry in the top vector is a line. Then each line is just an array of chars
        std::unordered_map<std::string, GateType> gateTypeMap;//reference type for switching between gatetype and string
        std::vector<std::vector<unsigned int>> levels;
        const unsigned int dummyGate = UINT_MAX;//I don't have a full dummy gate, just this constant

        std::vector<std::string> gateData(const std::string& target, std::string& line);//returns a string of the value, modifies the line to take out the value
        void addToList(const std::shared_ptr<Gate>& gate);//Adds the gate to Gates, and initializes top level size of Gates array correctly. DOES NOT LINK BUFFERS
        void initializeGateTypeMap();//Intializes the gatemap refernece for quick gatetype to string conversions
        bool initializeGates();//loads gates from file to Gates array, returns true if successful
        bool initializeStimulus();//Loads stimulus from file into stimulus array
        GateType stringToGateType(const std::string& typeStr);//turns a string into a gatetype
};  

#endif