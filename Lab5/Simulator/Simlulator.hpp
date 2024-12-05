#ifndef SIM_H
#define SIM_H

#include "../Gate.hpp"
#include <vector>
#include <string>
#include <memory>



enum class logic{//Three valued logic has... three values
    zero = 0,
    one = 1,
    X = 2
};

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

class Simulator{
    public:
        Simulator(const std::string& testfile, const std::string& gatefile);
        void runSim();//Top level function. Call to begin running the simulation
        std::vector<logic> runCycle(std::vector<char>*);//Runs a single clock cycle. Returns list of output values, dff vals are stored in the dffs themselves
    private:
        std::unique_ptr<std::vector<std::vector<std::shared_ptr<Gate>>>> Gates = std::make_unique<std::vector<std::vector<std::shared_ptr<Gate>>>>(0); //Each top level is a list of the gates of a given level
        std::unique_ptr<std::vector<std::vector<char>>> stimulus = nullptr; //Each entry in the top vector is a line. Then each line is just an array of chars

        std::vector<std::string> gateData(const std::string& target, std::string& line);//returns a string of the value, modifies the line to take out the value
        void addToList(const std::shared_ptr<Gate>& gate);//Adds the gate to Gates, and initializes top level size of Gates array correctly. DOES NOT LINK BUFFERS
};

#endif