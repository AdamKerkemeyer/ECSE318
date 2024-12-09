#include "Simlulator.hpp"
#include <vector>
#include <fstream>
#include <string>
#include <iostream>

Simulator::Simulator(){

    //Setup needed references
    initializeGateTypeMap();


    //Setup Gates
    while(!initializeGates());

    //Read test file into stimulus datastructure
    while(!initializeStimulus());


    //Check if loading in worked, number of input chars should equal num of inputs.
}

bool Simulator::initializeGates(){
    std::string gatefile;
    std::cout << "Enter the name of the gatefile to parse: ";
    std::cin >> gatefile;

    std::ifstream file(gatefile);       //Lets us read lines from a file into a string
    if (!file.is_open()) {
        std::cout << "Error opening file: " << gatefile << std::endl;
        return false;
    }
    std::string line = "";
 
    std::getline(file, line);

    unsigned int GatesSize;
    try{//intialize gates with the correct size
        GatesSize = std::stoi(line);
    }catch (const std::invalid_argument e){
            std::cout << "first line of file must be integer" << "\n" << std::endl;
    return false;
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
            return false;
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
                return false;
            }
        }

        //Add fanout gates
        for (int i = 0; i < fanoutStrings.size(); i++){
            try{
                Gates->at(indexNum).getFanoutGates().at(i) = std::stoi(fanoutStrings.at(i));
            }catch (const std::invalid_argument e){
                std::cout << "Invalid fanout entry '" << levelString << "' line " << indexNum + 2 << "\n" << std::endl;
                return false;
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

    levels = std::vector<unsigned int>(std::stoi(levelString)+1, lastGate);


    return true;
}

bool Simulator::initializeStimulus(){
    std::string testfile;
    std::cout << "Enter the name of the testfile file to parse: ";
    std::cin >> testfile;
    
    std::ifstream file(testfile);       //Lets us read lines from a file into a string
    if (!file.is_open()) {
        std::cout << "Error opening file: " << testfile << std::endl;
        return false;
    }
    std::string line = "";
 
    //get size of stimulus array
    std::getline(file, line);
    size_t inner_vec_size = line.length();

    size_t outer_vec_size = 1;
    while(std::getline(file, line)){
        outer_vec_size++;
    }
    file.close();

    std::cout << "(" << outer_vec_size << " ," << inner_vec_size <<")\n";

    //initailize stimulus
    stimulus = std::make_unique<std::vector<std::vector<char>>>(outer_vec_size, std::vector<char>(inner_vec_size));

    //now actually read in the data of stimulus
    //We parse through the array twice to ensure a contiguous memeory vector on initialization
    file.open(testfile);
    try{
        for (int i = 0; i < outer_vec_size; i++){
            std::getline(file, line);
            int j = 0;
            for (char signal : line){
                stimulus->at(i).at(j) = signal;
                j++;
            }
        }
    }catch (std::out_of_range e){
        std::cout << "Stimulus file has invalide format\n";
        return false;
    }
    return true;
}

void Simulator::printGates(){
    for (int i = 0; i < Gates->size(); i++){
        Gates->at(i).printGate();
        std::cout << "---------------------------------------------------------------\n";
    }
    std::cout << std::endl;
}

void Simulator::printStimulus(){

    for(int i = 0; i < stimulus->size(); i++){
        std::cout << "'";
        for (char signal : stimulus->at(i)){
            std::cout << signal;
        }
        std::cout <<"'\n";
    }
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

void Simulator::scheduleFannout(const unsigned int& gate){
    for (unsigned int fangate: Gates->at(gate).getFanoutGates()){
        if (Gates->at(fangate).getSched() == dummyGate){//Check that the gate hasn't already been scheduled
            Gates->at(fangate).setSched(levels.at(Gates->at(fangate).getLevel()));//Set the schedule pointer of the fanout
            levels.at(Gates->at(fangate).getLevel()) = fangate; //put fangate into levels
        }
    }
}

void Simulator::simLevel(const unsigned int& level, const SimType& simtype){
    unsigned int currentGate = levels.at(level);
    bool levelDone = false;
    while (!levelDone){
        logic oldState = Gates->at(currentGate).getState();
        if (simtype == SimType::Table){//Move this logic to higher level function calls to increase speed
            evaluteTable(currentGate);
        } else{
            evaluteScan(currentGate);
        }

        if (Gates->at(currentGate).getState() != oldState){
            scheduleFannout(currentGate);
        }

        if (Gates->at(currentGate).getSched() == lastGate){
            levelDone = true;
        } else{
            unsigned int tempGate = currentGate;
            currentGate = Gates->at(currentGate).getSched();
            Gates->at(tempGate).setSched(dummyGate);
        }
    }

    levels.at(level) = lastGate;
}

logic Simulator::evaluteTable(const unsigned int& gate){
    if (Gates->at(gate).getType() == GateType::BUFFER || Gates->at(gate).getType() == GateType::OUTPUT) Gates->at(gate).setState(Gates->at(Gates->at(gate).getFaninGates().at(0)).getState());
    else if (Gates->at(gate).getType() == GateType::NOT) Gates->at(gate).setState(notTable[static_cast<int>(Gates->at(Gates->at(gate).getFaninGates().at(0)).getState())]);
    for 
}