#include "Simlulator.hpp"
#include <iostream>
#include <memory>

/*
TO COMPILE
g++ -o sim Simlulator.cpp Gate_SIM.cpp Main_SIM.cpp
*/

int main(){
    std::string gatefile;
    std::cout << "Enter the name of the gatefile to parse: ";
    std::cin >> gatefile;
    std::string testfile;
    std::cout << "Enter the name of the testfile file to parse: ";
    std::cin >> testfile;

    //Construct the simluator object
    std::unique_ptr<Simulator> mySim = std::make_unique<Simulator>(testfile, gatefile);
    std::cout << "Loading Gates DONE" << "\n";
    
    mySim->printGates();
}