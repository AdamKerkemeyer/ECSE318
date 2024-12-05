#include "Simlulator.hpp"
#include <vector>
#include <fstream>
#include <string>
#include <iostream>

Simulator::Simulator(const std::string& testfile, const std::string& gatefile){
    std::ifstream file(gatefile);       //Lets us read lines from a file into a string
    if (!file.is_open()) {
        std::cout << "Error opening file: " << gatefile << std::endl;
        return;                         //Use cerr to output an error message if something goes wrong (not buffered like cout is)
    }
    std::string line = "";
    std::string type = "";
    std::string name = "";
    while (std::getline(file, line)) {

    }

    //Read test file into stimulus datastructure
    //Create a bunch of gates and put them into the gate data sturcture
    //Check if loading in worked, number of input chars should equal num of inputs.
}

std::vector<std::string> Simulator::gateData(const std::string& target, std::string& line){
    size_t startPos = line.find(target + "{");
    size_t endPos = line.find("}");
    size_t inputLength = target.length();
    std::string valString = line.substr(startPos + inputLength + 1, endPos - (startPos + inputLength + 1));
    if (valString.find(",") == std::string::npos){
        return std::vector(1, valString);
    }
    else{
        std::vector<std::string> result(1);
        size_t newpos = 0;
        size_t oldpos = 0;
        while (newpos != std::string::npos){
            newpos = valString.find(",",oldpos);
            result.push_back(valString.substr(oldpos, newpos-oldpos));
            oldpos = newpos;
        }
        return result;
    }

}

void Simulator::runSim(){
    //ask for output file name
    //Gates should be intitialized to X as state
    //Calls a for loop to iterate through each line of the stimulus file
    //take the output of runCycle and stick it in the output file
}

std::vector<logic> Simulator::runCycle(std::vector<char>*){
    //Assign new input stimulus to input gates
    //Go level by level evaluating each gate
}