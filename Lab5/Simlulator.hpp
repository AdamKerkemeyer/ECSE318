#ifndef SIM_H
#define SIM_H

#include "Gate.hpp"
#include <vector>

using namespace std;

namespace Sim
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

class Simulator{
    public:
        Simulator(const vector<Gate*> Gates);
        

    private:
        vector<Gate*> Gates;


};
}
#endif