#include "Simlulator.hpp"
#include <iostream>
#include <memory>

/*
TO COMPILE
g++ -o sim Simlulator.cpp Gate_SIM.cpp Main_SIM.cpp
*/

int main(){
    

    //Construct the simluator object
    std::unique_ptr<Simulator> mySim = std::make_unique<Simulator>();

    
    //mySim->printGates();
    mySim->printStimulus();
}