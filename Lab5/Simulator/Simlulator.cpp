#include "Simlulator.hpp"
#include <vector>
#include <fstream>
#include <string>
#include <iostream>

Simulator::Simulator(const std::string& testfile, const std::string& gatefile){

    //Setup needed references
    initializeGateTypeMap();


    //Setup Gates
    initializeGates(gatefile);

    //Read test file into stimulus datastructure
    //Check if loading in worked, number of input chars should equal num of inputs.
}

void Simulator::initializeGates(const std::string& gatefile){
    std::ifstream file(gatefile);       //Lets us read lines from a file into a string
    if (!file.is_open()) {
        std::cout << "Error opening file: " << gatefile << std::endl;
        return;
    }
    std::string line = "";
 
    std::getline(file, line);

    unsigned int GatesSize;
    try{//intialize gates with the correct size
        GatesSize = std::stoi(line);
    }catch (const std::invalid_argument e){
            std::cout << "first line of file must be integer" << "\n" << std::endl;
    return;
    }

    Gates = std::make_unique<std::vector<Gate>>();
    Gates->reserve(GatesSize);

    std::string typeString = "";
    std::string outputString = "";
    std::string nameString = "";
    std::string levelString = "";
    std::vector<std::string> fanoutStrings;
    std::vector<std::string> faninStrings;
    for (unsigned int indexNum = 0; indexNum < GatesSize; indexNum = indexNum + 1) {

        //get next line
        std::getline(file, line);  
        std::cout << line << "\n";

        //Parse the line into mangable strings
        GateType newGateType = stringToGateType(gateData("GATETYPE", line)[0]);
        outputString = gateData("OUTPUT", line)[0];
        levelString = gateData("GATELEVEL", line)[0];
        faninStrings = gateData("FANIN", line);
        fanoutStrings = gateData("FANOUT", line);
        nameString = gateData("GATENAME", line)[0];
/* Depreitated becuase the unordered map is faster
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
*/

/*Deprietiated for ints as pointers
         //no need to make buffer gates the standard way. They get made durring data structure linkage
        if (newGateType == GateType::BUFFER){
            lineNum = lineNum + 1;
            continue;
        }
*/

        //new gate to start building out
        Gates->push_back(Gate(nameString, newGateType, faninStrings.size(), fanoutStrings.size()));

        //get the level
        try{
            Gates->at(indexNum).setLevel(std::stoi(levelString));
        }catch (const std::invalid_argument e){
            std::cout << "Invalid level entry '" << levelString << "' line " << indexNum + 2 << "\n" << std::endl;
            return;
        }

        //Set the output 
        if (outputString == "FALSE"){
            Gates->at(indexNum).setIsOutput(false);
        }else{
            Gates->at(indexNum).setIsOutput(true);
        }

        //add fanin gates
        for (int i = 0; i < faninStrings.size(); i++){
            try{
                Gates->at(indexNum).getFaninGates().at(i) = std::stoi(faninStrings.at(i));
            }catch (const std::invalid_argument e){
                std::cout << "Invalid fanin entry '" << levelString << "' line " << indexNum + 2 << "\n" << std::endl;
                return;
            }
        }

        //Add fanout gates
        for (int i = 0; i < fanoutStrings.size(); i++){
            try{
                Gates->at(indexNum).getFanoutGates().at(i) = std::stoi(fanoutStrings.at(i));
            }catch (const std::invalid_argument e){
                std::cout << "Invalid fanout entry '" << levelString << "' line " << indexNum + 2 << "\n" << std::endl;
                return;
            }
        }

/*depreitated due to ints as pointers
        //Set the fanout
        for (std::string foString : fanoutStrings){
            //Check newgate's level
            bool bufferFound = false;
            for(std::shared_ptr<Gate> gate : Gates->at(newGate->getLevel())){
                //for each item in that gate's fanout
                for(std::shared_ptr<Gate> buffer : gate->getFanoutGates()){
                    if (buffer->getName() == foString){//matching buffer found, update pointers
                        newGate->addFanoutGate(buffer);//newGate reference to buffer
                        buffer->addFaninGate(newGate);//buffer reference to newGate
                        bufferFound = true;
                    }
                    if (bufferFound){
                        break;
                    }
                }
                if (bufferFound){
                    break;
                }
            }
            if (bufferFound == false){//if we haven't already found the buffer, check the next levels fanin
                for(std::shared_ptr<Gate> gate : Gates->at(newGate->getLevel() + 1)){
                    //for each item in that gate's fanout
                    for(std::shared_ptr<Gate> buffer : gate->getFaninGates()){
                        if (buffer->getName() == foString){//matching buffer found, update pointers
                            newGate->addFanoutGate(buffer);//newGate reference to buffer
                            buffer->addFaninGate(newGate);//buffer reference to newGate
                            bufferFound = true;
                        }
                        if (bufferFound){
                            break;
                        }
                    }
                    if (bufferFound){
                        break;
                    }
                }
            }
            if (bufferFound == false){//If we haven't found the buffer now, it does not exist, so make it
                newGate->addFanoutGate(std::make_shared<Gate>(foString, GateType::BUFFER));//newGate reference to buffer
                newGate->getFanoutGates().back()->addFaninGate(newGate);//buffer reference to newGate
            }
        }

        //Set the fanin
        for (std::string fiString : faninStrings){
            //Check newgate's level
            bool bufferFound = false;
            for(std::shared_ptr<Gate> gate : Gates->at(newGate->getLevel())){
                //for each item in that gate's fanin
                for(std::shared_ptr<Gate> buffer : gate->getFaninGates()){
                    if (buffer->getName() == fiString){//matching buffer found, update pointers
                        newGate->addFaninGate(buffer);//newGate reference to buffer
                        buffer->addFanoutGate(newGate);//buffer reference to newGate
                        bufferFound = true;
                    }
                    if (bufferFound){
                        break;
                    }
                }
                if (bufferFound){
                    break;
                }
            }
            if (bufferFound == false){//if we haven't already found the buffer, check the previous levels fanin
                for(std::shared_ptr<Gate> gate : Gates->at(newGate->getLevel() - 1)){
                    //for each item in that gate's fanout
                    for(std::shared_ptr<Gate> buffer : gate->getFanoutGates()){
                        if (buffer->getName() == fiString){//matching buffer found, update pointers
                            newGate->addFaninGate(buffer);//newGate reference to buffer
                            buffer->addFanoutGate(newGate);//buffer reference to newGate
                            bufferFound = true;
                        }
                        if (bufferFound){
                            break;
                        }
                    }
                    if (bufferFound){
                        break;
                    }
                }
            }
            if (bufferFound == false){//If we haven't found the buffer now, it does not exist, so make it
                newGate->addFaninGate(std::make_shared<Gate>(fiString, GateType::BUFFER));//newGate reference to buffer
                newGate->getFaninGates().back()->addFanoutGate(newGate);//buffer reference to newGate
            }
        }
*/
    }
}

void Simulator::initializeStimulus(const std::string& testfile){
    std::ifstream file(testfile);       //Lets us read lines from a file into a string
    if (!file.is_open()) {
        std::cout << "Error opening file: " << testfile << std::endl;
        return;
    }
    std::string line = "";
 
    std::getline(file, line);

    
}

void Simulator::printGates(){
    for (int i = 0; i < Gates->size(); i++){
        Gates->at(i).printGate();
        std::cout << "---------------------------------------------------------------\n";
    }
    std::cout << std::endl;
}
/* depreiated because of pointers as ints implemntation
void Simulator::addToList(const std::shared_ptr<Gate>& gate){
    int gateLevel = gate->getLevel();
    int GatesSize = Gates->size();
    if (gateLevel + 1 > GatesSize){//resize the array larger if needbe
        Gates->resize(gateLevel + 1, std::vector<std::shared_ptr<Gate>>(0));
    }
    Gates->at(gateLevel).push_back(gate);//I really hope this increments the reference count for the gate pointer but IDK enough C++ to say for sure
}
*/

std::vector<std::string> Simulator::gateData(const std::string& target, std::string& line){
    size_t startPos = line.find(target + "{");
    size_t endPos = line.find("}", startPos);
    size_t inputLength = target.length();
    if (startPos + inputLength + 1 == endPos){//zero length string
        line.erase(startPos, endPos + 1 - startPos);
        return std::vector<std::string>(0);
    }
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

/*not ready for compile
void Simulator::runSim(){
    //ask for output file name
    //Gates should be intitialized to X as state
    //Calls a for loop to iterate through each line of the stimulus file
    //take the output of runCycle and stick it in the output file
}
*/

/*not ready for compile
std::vector<logic> Simulator::runCycle(std::vector<char>*){
    //Assign new input stimulus to input gates
    //Go level by level evaluating each gate
}
*/
void Simulator::initializeGateTypeMap() {
    gateTypeMap["AND"]    = GateType::AND;
    gateTypeMap["OR"]     = GateType::OR;
    gateTypeMap["NOT"]    = GateType::NOT;
    gateTypeMap["NOR"]    = GateType::NOR;
    gateTypeMap["NAND"]   = GateType::NAND;
    gateTypeMap["DFF"]    = GateType::DFF;
    gateTypeMap["INPUT"]  = GateType::INPUT;
    gateTypeMap["OUTPUT"] = GateType::OUTPUT;
    gateTypeMap["BUFFER"] = GateType::BUFFER;
}

GateType Simulator::stringToGateType(const std::string& typeStr) {
    return gateTypeMap[typeStr];
}
