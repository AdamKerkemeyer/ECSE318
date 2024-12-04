#include "Simlulator.hpp"

Simulator::Simulator(const std::vector<Gate*> Gates, const std::string& testfile, const std::string& gatefile){
    //Read test file into stimulus datastructure
    //Create a bunch of gates and put them into the gate data sturcture
    //Check if loading in worked, number of input chars should equal num of inputs.
}
Simulator::~Simulator(){
    //Learn to use smart pointers not a destructor
}

void Simulator::runSim(){
    //ask for output file name
    //Gates should be intitialized to X as state
    //Calls a for loop to iterate through each line of the stimulus file
    //take the output of runCycle and stick it in the output file
}

std::vector<logic>[] Simulator::runCycle(std::vector<char>*){
    //Assign new input stimulus to input gates
    //Go level by level evaluating each gate
}