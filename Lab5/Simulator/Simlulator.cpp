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
    
    std::string gatefile = "../Example_outfile.txt";
    //std::cout << "Enter the name of the gatefile to parse: ";
    //std::cin >> gatefile;

    std::ifstream file(gatefile);       //Lets us read lines from a file into a string
    if (!file.is_open()) {
        std::cout << "Error opening file: " << gatefile << std::endl;
        return false;
    }
    std::string line = "";
 
    std::getline(file, line);
    std::string GatesSizeString = gateData("GATES", line)[0];
    std::string InputsSizeString = gateData("INPUTS", line)[0];
    std::string OutputSizeString = gateData("OUTPUTS", line)[0];
    std::string DffSizeString = gateData("DFFS", line)[0];

    unsigned int GatesSize;
    unsigned int InputsSize;
    unsigned int OutputsSize;
    unsigned int DffsSize;
    try{//intialize gates with the correct size
        GatesSize = std::stoi(GatesSizeString);
        InputsSize = std::stoi(InputsSizeString);
        OutputsSize = std::stoi(OutputSizeString);
        DffsSize = std::stoi(DffSizeString);
    }catch (const std::invalid_argument e){
            std::cout << "first line of file contains invalid size specifications" << "\n" << std::endl;
    return false;
    }

    //reserve space for the arrays, but don't initialize their values yet
    Gates = std::make_unique<std::vector<Gate>>();
    Gates->reserve(GatesSize);
    inputs = std::vector<unsigned int>();
    inputs.reserve(InputsSize);
    outputs = std::vector<unsigned int>();
    outputs.reserve(OutputsSize);
    dffs = std::vector<unsigned int>();
    dffs.reserve(DffsSize);

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

        //Record position if a special gate with a pointer to it
        if (newGateType == GateType::DFF){
            dffs.push_back(indexNum);
        } else if (newGateType == GateType::OUTPUT){
            outputs.push_back(indexNum);
        }else if (newGateType == GateType::INPUT){
            inputs.push_back(indexNum);
        }

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
    nextLevels = std::vector<unsigned int>(std::stoi(levelString)+1, lastGate);

    //Gates, inputs, outputs, dffs, should match the specifed size we speced at the start of the file.
    if (Gates->size() != GatesSize){
        std::cout << "Error: Specified number of gates is: " << GatesSize << ", File contained this many Gates: " << Gates->size() << "\n";
        return false;
    } else if (inputs.size() != InputsSize){
        std::cout << "Error: Specified number of inputs is: " << InputsSize << ", File contained this many Inputs: " << inputs.size() << "\n";
        return false;
    } else if (outputs.size() != OutputsSize){
        std::cout << "Error: Specified number of outputs is: " << OutputsSize << ", File contained this many Outputs: " << outputs.size() << "\n";
        return false;
    } else if (dffs.size() != DffsSize){
        std::cout << "Error: Specified number of dffs is: " << DffsSize << ", File contained this many dffs: " << dffs.size() << "\n";
        return false;
    }

    return true;
}

bool Simulator::initializeStimulus(){
    std::string testfile = "../exStim.vec";
    //std::cout << "Enter the name of the testfile file to parse: ";
    //std::cin >> testfile;
    
    std::ifstream file(testfile);       //Lets us read lines from a file into a string
    if (!file.is_open()) {
        std::cout << "Error opening file: " << testfile << std::endl;
        return false;
    }
    std::string line = "";
 
    //get size of stimulus array
    std::getline(file, line);
    size_t inner_vec_size = line.length();

    //the stimulus array size needs to equal the number of inputs
    if (inner_vec_size != inputs.size()){
        std::cout << "Error: Detected " << inputs.size() << " inputs, but stimulus for " << inner_vec_size << " inputs\n";
        return false;
    }

    size_t outer_vec_size = 1;
    while(std::getline(file, line)){
        outer_vec_size++;
    }
    file.close();

    std::cout << "(" << outer_vec_size << " ," << inner_vec_size <<")\n";

    //initailize stimulus
    stimulus = std::make_unique<std::vector<std::vector<logic>>>(outer_vec_size, std::vector<logic>(inner_vec_size));

    //now actually read in the data of stimulus
    //We parse through the array twice to ensure a contiguous memeory vector on initialization
    file.open(testfile);
    try{
        for (int i = 0; i < outer_vec_size; i++){
            std::getline(file, line);
            int j = 0;
            for (char signal : line){
                if (signal == '0'){
                    stimulus->at(i).at(j) = logic::zero;
                }else if (signal == '1'){
                    stimulus->at(i).at(j) = logic::one;
                }else if (signal =='X' || signal == 'x'){
                    stimulus->at(i).at(j) = logic::X;
                }else{
                    std::cout << "Non logic value '" << signal << "' detected in stimulus line " << i << "\n";
                    return false;
                }
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
        for (logic signal : stimulus->at(i)){
            std::cout << logicToChar(signal);
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

char Simulator::logicToChar(const logic& val){
    if (val == logic::one) return '1';
    else if (val == logic::zero) return '0';
    else return 'X';
}

void Simulator::reportStates(const std::vector<unsigned int>& array){
    for (unsigned int gate : array){
        std::cout << logicToChar(Gates->at(gate).getState());
    }
}

void Simulator::printLevels(){
    std::cout << "levels: ";
    for (unsigned int gate : levels){
        std::cout << gate << ", ";
    }
    std::cout << "\n";
}

void Simulator::scheduleFannout(const unsigned int& gate){
    //std::cout << "doing fanout on " << gate << "\n";
    if (Gates->at(gate).getType() == GateType::DFF){ //DFF fanouts need to be scheduled into nextLevels, not normal levels
        for (unsigned int fangate : Gates->at(gate).getFanoutGates()){
            if (Gates->at(fangate).getSched() == dummyGate){//Check that the gate hasn't already been scheduled
                Gates->at(fangate).setSched(nextLevels.at(Gates->at(fangate).getLevel()));//Set the schedule pointer of the fanout
                nextLevels.at(Gates->at(fangate).getLevel()) = fangate; //put fangate into levels
            }
        }
    }else{
        for (unsigned int fangate : Gates->at(gate).getFanoutGates()){
            //std::cout << "scheduling gate: " << fangate << "\n";
            //std::cout << "gate " << fangate << "sched is " << Gates->at(fangate).getSched() << "\n";
            if (Gates->at(fangate).getSched() == dummyGate){//Check that the gate hasn't already been scheduled
                Gates->at(fangate).setSched(levels.at(Gates->at(fangate).getLevel()));//Set the schedule pointer of the fanout
                levels.at(Gates->at(fangate).getLevel()) = fangate; //put fangate into levels
            }
        }
    }
}

void Simulator::SimulateTable(){
    //std::cout << "Program wide\n";
    for (unsigned int simpos = 0; simpos < stimulus->size(); simpos++){
        simCycleTable(simpos);
    }
    //std::cout << "Dummy is " << dummyGate << "\nLast is " << lastGate << "\n";
}

void Simulator::simCycleTable(const unsigned int& simpos){
    //std::cout << "Cycle Wide\n";
    //Sched Dff fannouts
    levels = nextLevels;
    nextLevels.assign(nextLevels.size(), lastGate);

    //Read inputs
    for (unsigned int i = 0; i < inputs.size(); i++){
        if (Gates->at(inputs.at(i)).getState() != stimulus->at(simpos).at(i)){ //input state changed
            Gates->at(inputs.at(i)).setState(stimulus->at(simpos).at(i));//set new state
            scheduleFannout(inputs.at(i));//Schedule that inputs fanouts
        }
    }

    //run all level sims
    for (unsigned int lvl = 1; lvl < levels.size(); lvl ++){
        simLevelTable(lvl);
    }

    //print inputs, outputs, and Dffs
    std::cout << "INPUTS   :";
    reportStates(inputs);
    std::cout << "\nSTATE   :";
    reportStates(dffs);
    std::cout << "\nOUTPUT  :";
    reportStates(outputs);
    std::cout << "\n\n";
}

void Simulator::simLevelTable(const unsigned int& level){
    //std::cout << "Level Wide, level = " << level << "\n";
    unsigned int currentGate = levels.at(level);
    if (currentGate != lastGate){
        bool levelDone = false;
        while (!levelDone){
            //std::cout << currentGate << "\n";
            logic oldState = Gates->at(currentGate).getState();
            evaluteTable(currentGate);

           // printLevels();
            if (Gates->at(currentGate).getState() != oldState){
                scheduleFannout(currentGate);
            }
            //printLevels();

            if (Gates->at(currentGate).getSched() == lastGate){
                //std::cout << "level done\n";
                Gates->at(currentGate).setSched(dummyGate);
                levelDone = true;
            } else{
                //std::cout << "to next gate\n";
                unsigned int tempGate = currentGate;
                currentGate = Gates->at(currentGate).getSched();
                Gates->at(tempGate).setSched(dummyGate);
            }
        }
    }
}

void Simulator::evaluteTable(const unsigned int& gate){
    //std::cout << "Eval Wide\n";
    if (Gates->at(gate).getType() == GateType::BUFFER || Gates->at(gate).getType() == GateType::OUTPUT || Gates->at(gate).getType() == GateType::DFF) Gates->at(gate).setState(Gates->at(Gates->at(gate).getFaninGates().at(0)).getState());
    else if (Gates->at(gate).getType() == GateType::NOT) Gates->at(gate).setState(notTable[static_cast<int>(Gates->at(Gates->at(gate).getFaninGates().at(0)).getState())]);
    else if (Gates->at(gate).getType() == GateType::AND){
        Gates->at(gate).setState(Gates->at(Gates->at(gate).getFaninGates().at(0)).getState());
        for (int i = 1; i < Gates->at(gate).getFaninGates().size(); i++){
            Gates->at(gate).setState(andTable[static_cast<int>(Gates->at(Gates->at(gate).getFaninGates().at(i)).getState())][static_cast<int>(Gates->at(gate).getState())]);
        }
    }
    else if (Gates->at(gate).getType() == GateType::OR){
        Gates->at(gate).setState(Gates->at(Gates->at(gate).getFaninGates().at(0)).getState());
        for (int i = 1; i < Gates->at(gate).getFaninGates().size(); i++){
            Gates->at(gate).setState(orTable[static_cast<int>(Gates->at(Gates->at(gate).getFaninGates().at(i)).getState())][static_cast<int>(Gates->at(gate).getState())]);
        }
    }
    else if (Gates->at(gate).getType() == GateType::NOR){
        Gates->at(gate).setState(Gates->at(Gates->at(gate).getFaninGates().at(0)).getState());
        for (int i = 1; i < Gates->at(gate).getFaninGates().size(); i++){
            Gates->at(gate).setState(orTable[static_cast<int>(Gates->at(Gates->at(gate).getFaninGates().at(i)).getState())][static_cast<int>(Gates->at(gate).getState())]);
        }
        Gates->at(gate).setState(notTable[static_cast<int>(Gates->at(gate).getState())]);
    }
    else if (Gates->at(gate).getType() == GateType::NAND){
        Gates->at(gate).setState(Gates->at(Gates->at(gate).getFaninGates().at(0)).getState());
        for (int i = 1; i < Gates->at(gate).getFaninGates().size(); i++){
            Gates->at(gate).setState(andTable[static_cast<int>(Gates->at(Gates->at(gate).getFaninGates().at(i)).getState())][static_cast<int>(Gates->at(gate).getState())]);
        }
        Gates->at(gate).setState(notTable[static_cast<int>(Gates->at(gate).getState())]);
    }
}

