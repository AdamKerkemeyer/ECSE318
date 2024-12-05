#include "Simlulator.hpp"
#include <vector>
#include <fstream>
#include <string>
#include <iostream>

Simulator::Simulator(const std::string& testfile, const std::string& gatefile){
    std::ifstream file(gatefile);       //Lets us read lines from a file into a string
    if (!file.is_open()) {
        std::cout << "Error opening file: " << gatefile << std::endl;
        return;
    }
    std::string line = "";
    std::string typeString = "";
    std::string outputString = "";
    std::string nameString = "";
    std::string levelString = "";
    std::vector<std::string> fanoutStrings;
    std::vector<std::string> faninStrings;
    unsigned int lineNum = 0;
    while (std::getline(file, line)) {
        //Parse the line into mangable strings
        typeString = gateData("GATETYPE", line)[0];
        outputString = gateData("OUTPUT", line)[0];
        levelString = gateData("OUTPUT", line)[0];
        faninStrings = gateData("FANIN", line);
        fanoutStrings = gateData("FANOUT", line);
        nameString = gateData("GATENAME", line)[0];

        //Determine the gatetype
        GateType newGateType = GateType::BUFFER;
        if (typeString == "AND")GateType newGateType = GateType::AND;
        else if (typeString == "OR") GateType newGateType = GateType::OR;
        else if (typeString == "NOT") GateType newGateType = GateType::NOT;
        else if (typeString == "NOR") GateType newGateType = GateType::NOR;
        else if (typeString == "NAND") GateType newGateType = GateType::NAND;
        else if (typeString == "DFF") GateType newGateType = GateType::DFF;
        else if (typeString == "INPUT") GateType newGateType = GateType::INPUT;
        else if (typeString == "OUTPUT") GateType newGateType = GateType::OUTPUT;
        else if (typeString == "BUFFER") GateType newGateType = GateType::BUFFER;
        else {
            std::cout << "Invalid Gate type '" << typeString << "' line " << lineNum << "\n" << std::endl;
            return;
        }

         //no need to make buffer gates the standard way. They get made durring data structure linkage
        if (newGateType == GateType::BUFFER){
            lineNum = lineNum + 1;
            continue;
        }

        //new gate to start building out
        std::shared_ptr<Gate> newGate = std::make_shared<Gate>(nameString, newGateType);

        //get the level
        try{
            newGate->setLevel(std::stoi(levelString));
        }catch (const std::invalid_argument e){
            std::cout << "Invalid level entry '" << levelString << "' line " << lineNum << "\n" << std::endl;
            return;
        }

        //Set the output 

        //Add to Gates
        this->addToList(newGate);

        //Set the fanout
        for (std::string foString : fanoutStrings){
            //Check gate's level
            for(std::shared_ptr<Gate> gate : Gates->at(newGate->getLevel())){
                //for each item in that gate's fanout
                for
            }
        }

        //Set the fanin
        lineNum = lineNum + 1;
    }

    //Read test file into stimulus datastructure
    //Create a bunch of gates and put them into the gate data sturcture
    //Check if loading in worked, number of input chars should equal num of inputs.
}

void Simulator::addToList(const std::shared_ptr<Gate>& gate){
    int gateLevel = gate->getLevel();
    int GatesSize = Gates->size();
    if (gateLevel + 1 > GatesSize){//resize the array larger if needbe
        Gates->resize(gateLevel + 1, std::vector<std::shared_ptr<Gate>>(0));
    }
    Gates->at(gateLevel).push_back(gate);//I really hope this increments the reference count for the gate pointer but IDK enough C++ to say for sure
}

std::vector<std::string> Simulator::gateData(const std::string& target, std::string& line){
    size_t startPos = line.find(target + "{");
    size_t endPos = line.find("}");
    size_t inputLength = target.length();
    std::string valString = line.substr(startPos + inputLength + 1, endPos - (startPos + inputLength + 1));
    line.erase(startPos, endPos + 1 - startPos);
    if (valString.find(",") == std::string::npos){
        return std::vector(1, valString);
    }
    else{
        std::vector<std::string> result;
        size_t newpos = 0;
        size_t oldpos = 0;
        while (newpos != std::string::npos){
            newpos = valString.find(",",oldpos);
            result.push_back(valString.substr(oldpos, newpos-oldpos));
            oldpos = newpos + 1;
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