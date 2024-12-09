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
    //mySim->printStimulus();

    std::string SimType = "";
    std::cout << "Run an Input Scan simulation or a Table lookup Simulation? (I/T): ";
    while (SimType != "I" || SimType != "T"){
        std::cin >> SimType;
        if (SimType == "I"){
            mySim->SimulateScan();
        }else if (SimType == "T"){
            mySim->SimulateTable();
        }else{
            std::cout << "Enter 'I' for Input Scan, or 'T' for Table Lookup: ";
        }
    }
}