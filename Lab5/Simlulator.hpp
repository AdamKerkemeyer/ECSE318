#ifndef SIM_H
#define SIM_H

#include "Gate.hpp"
#include <vector>
#include <string>

namespace ECSE381Sim
{

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

logic inputScan();
logic tableLookup();

class Simulator{
    public:
        Simulator(const std::vector<Gate*> Gates, const std::string& testfile, const std::string& gatefile);
        void runSim();//Top level function. Call to begin running the simulation
        std::vector<logic> runCycle();//Runs a single clock cycle. Returns list of next dff values
    private:
        std::vector<Gate*> Gates;
        std::vector<std::vector<logic>> stimulus;
};
}
#endif