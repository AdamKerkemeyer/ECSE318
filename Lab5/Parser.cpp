#include "Parser.hpp"
#include <fstream>
#include <sstream>
#include <iostream>
#include <regex>
#include <queue>
#include <algorithm>

//Test
Parser::Parser(const std::string& filename) : filename(filename) {
    initializeGateTypeMap();
}

void Parser::initializeGateTypeMap() {
    gateTypeMap["and"]    = GateType::AND;
    gateTypeMap["or"]     = GateType::OR;
    gateTypeMap["not"]    = GateType::NOT;
    gateTypeMap["nor"]    = GateType::NOR;
    gateTypeMap["nand"]   = GateType::NAND;
    gateTypeMap["dff"]    = GateType::DFF;
    gateTypeMap["input"]  = GateType::INPUT;
    gateTypeMap["output"] = GateType::OUTPUT;
    gateTypeMap["buffer"] = GateType::BUFFER;
}

std::string Parser::gateTypeToString(GateType type) const{
    switch (type) {
        case GateType::AND:     return "AND";
        case GateType::OR:      return "OR";
        case GateType::NOT:     return "NOT";
        case GateType::NOR:     return "NOR";
        case GateType::NAND:    return "NAND";
        case GateType::DFF:     return "DFF";
        case GateType::INPUT:   return "INPUT";
        case GateType::OUTPUT:  return "OUTPUT";
        case GateType::BUFFER:  return "BUFFER";
        default: return "ERROR: GATE TYPE UNKNOWN";
    }
}

//Used by the parser to swap the string with the type
GateType Parser::stringToGateType(const std::string& typeStr) {
    return gateTypeMap[typeStr];
}

void Parser::parse() {
    std::ifstream file(filename);       //Lets us read lines from a file into a string
    inputCount = 0;
    outputCount = 0;
    if (!file.is_open()) {
        std::cerr << "Error opening file: " << filename << std::endl;
        return;                         //Use cerr to output an error message if something goes wrong (not buffered like cout is)
    }

    std::string line;
    bool parsingWires = false;          //Due to only 1 wire declaration, parser must remember it is reading wires until ";" 

    // Get the module line for order of inputs and outputs (all inputs should be declared before all outputs), ignore everything before that
    while (std::getline(file, line)) {
        if(line.find("module") != std::string::npos){
            std::size_t start = line.find('(');
            std::size_t end = line.find(')');
            if (start != std::string::npos && end != std::string::npos) {   //If we found '(' and ')'
                std::string gates = line.substr(start + 1, end - start - 1);//Grab entire string
                std::istringstream gateStream(gates);
                std::string IO;
                while (std::getline(gateStream, IO, ',')) {
                    IO = std::regex_replace(IO, std::regex("^\\s+|\\s+$"), ""); //Remove first and last whitespace
                    IOnames.push_back(IO);
                }
            }
            break;
        }
    }

    while (std::getline(file, line)) {
        if(line.find("wire") == 0){
            line = std::regex_replace(line, std::regex("^\\s+|\\s+$"), "");
            parsingWires = true;           //Replace leading and/or trailing whitespace with nothing
            line = line.substr(6);          //remove keyword "wire  " the first time we see it
        }
        if (parsingWires) {
            std::istringstream wireStream(line);
            std::string wire;
            while (std::getline(wireStream, wire, ',')) {
                wire = std::regex_replace(wire, std::regex("^\\s|\\s+$"), "");
                if(!wire.empty() && wire.back() == ';'){
                    wire.pop_back();        //Remove semicolon
                    parsingWires = false;  //Exit wire loop
                }
                if(!wire.empty()){
                    auto wireGate = std::make_shared<Gate>(wire, GateType::BUFFER);
                    gates.push_back(wireGate);
                    gateMap[wire] = wireGate;
                }
            }
        }
        else {
            parseLine(line);
        }
    }

    file.close();

    addBuffersToInputs();
}

void Parser::parseLine(const std::string& line) {
    //Check if line is input/output, if not, handle as a gate (wires are processed in parse)
    if (line.find("input") == 0) {
        std::string name = line.substr(6);                  //delete "input "
        name = std::regex_replace(name, std::regex(";"), "");        
        name = std::regex_replace(name, std::regex("^\\s+|\\s+$"), "");
        auto inputGate = std::make_shared<Gate>(name, GateType::INPUT);
        inputGate->setLevel(0);                              //All inputs always level 0
        //To make simulator work all initial gates must be on level 2 so add a buffer (because dff outputs are on level 1)
        gates.push_back(inputGate);
        gateMap[name] = inputGate;
        inputCount++;
        return;
    }

    else if (line.find("output") == 0) {
        std::string name = line.substr(7);                  //delete "output "
        name = std::regex_replace(name, std::regex(";"), "");        
        name = std::regex_replace(name, std::regex("^\\s+|\\s+$"), "");
        auto outputGate = std::make_shared<Gate>(name, GateType::OUTPUT);
        gates.push_back(outputGate);
        gateMap[name] = outputGate;
        outputCount++;
        return;
    }

    else {
        //Normal Gate Parse:
        std::regex gateRegex(R"((\w+)\s+(\w+)\s+\(([^)]+)\);)");
        std::smatch match;
        if (std::regex_search(line, match, gateRegex)) {
            std::string typeStr = match[1];
            std::string name = match[2];
            std::string connections = match[3];

            GateType type = stringToGateType(typeStr);
            auto gate = std::make_shared<Gate>(name, type);
            gates.push_back(gate);
            gateMap[name] = gate;
            if(gate->getType() == GateType::DFF) {
                dffArray.push_back(gate->getName());
            }
            if (previousGate) {
                previousGate->setNextGate(gate);
            }
            previousGate = gate;                        //Can traverse via pointers if you want

            std::istringstream connStream(connections);
            std::string output;
            std::vector<std::string> inputs;            //Vector of inputs because we can have more than 1
            std::getline(connStream, output, ',');      //Grab output gate using delimiter
            std::string input;
            while (std::getline(connStream, input, ',')) {
                input = std::regex_replace(input, std::regex("^\\s+|\\s+$"), "");
                inputs.push_back(input);
            }
            connectGates(output, inputs, gate);
        }
    }
}

void Parser::connectGates(const std::string& output, const std::vector<std::string>& inputs, std::shared_ptr<Gate> gate) {
    //Skip if the gate type is an input or output
    if (gate->getType() == GateType::INPUT || gate->getType() == GateType::OUTPUT) {
        return;
    }
    
    auto outputGate = gateMap[output];          //Find the output wire/buffer in the unordered map
    if(!outputGate) {                           //Throw error if we can't find the gate
        std::cerr << "Error: Output gate " << output << " not found in gateMap/not declared in file." << std::endl;
        return;
    }
    gate -> addFanoutGate(outputGate);          //Add the pointer we found to that gate's fanout
    outputGate -> addFaninGate(gate);           //Then go to the outputGate and add this gate as the fanin

    for (const std::string& input : inputs) {
        auto inputGate = gateMap[input];
        if(!inputGate) {
            std::cerr << "Error: Input gate " << input << " not found in gateMap/not declared in file." << std::endl;
            return;
        }
        gate -> addFaninGate(inputGate);
        inputGate -> addFanoutGate(gate);
    }
}

void Parser::addBuffersToInputs() {
    size_t initialSize = gates.size(); 
    std::vector<std::shared_ptr<Gate>> newBufferGates;
    //Need to add new buffers independently first because otherwise the program will loop forever
    for (size_t i = 0; i < initialSize; ++i) {
        const auto& gate = gates[i];
        if (gate->getType() == GateType::INPUT) {
            std::vector<std::shared_ptr<Gate>> originalFanouts = gate->getFanoutGates();
            for (const auto& fanoutGate : originalFanouts) {
                // Create a buffer gate
                std::string bufferName = gate->getName() + "_buffer";
                auto bufferGate = std::make_shared<Gate>(bufferName, GateType::BUFFER);
                newBufferGates.push_back(bufferGate);
                gateMap[bufferName] = bufferGate;

                gate->addFanoutGate(bufferGate);
                bufferGate->addFaninGate(gate);

                bufferGate->addFanoutGate(fanoutGate);
                fanoutGate->addFaninGate(bufferGate);

                gate->removeFanoutGate(fanoutGate);
                fanoutGate->removeFaninGate(gate);
            }
        }
    }
    gates.insert(gates.end(), newBufferGates.begin(), newBufferGates.end());
}

const std::vector<std::shared_ptr<Gate>>& Parser::getGates() const {
    return gates;
}
std::vector<std::shared_ptr<Gate>>& Parser::getGates() {
    return gates;
}

void Parser::assignGateLevels() {
    std::queue<std::shared_ptr<Gate>> q;
    //Input gates already set to 0, all else are -1, add all inputs to queue
    for (const auto& gate : gates) {
        if (gate->getType() == GateType::INPUT) {
            q.push(gate);
        } 
    }
    //We are doing knockoff BFS because we will revisit nodes we already visited if the gate level is lower than the current gate
    while (!q.empty()) {
        int currentLevel = q.front()->getLevel();
        std::vector<std::shared_ptr<Gate>> nextLevelGates;
        //One entire level at a time, repeat as many times as necessary
        while (!q.empty() && q.front()->getLevel() == currentLevel) {
            auto currentGate = q.front();
            q.pop();
            for (const auto& fanoutGate : currentGate->getFanoutGates()) {
                //if (fanoutGate->getLevel() == -1) { // We want to revisit gates if we already saw them to give them a higher (correct) level
                    if (currentGate->getType() == GateType::DFF) {
                        fanoutGate->setLevel(1);
                    } else {
                        fanoutGate->setLevel(currentLevel + 1);
                        nextLevelGates.push_back(fanoutGate);
                    }
                //}
            }
        }

        for (const auto& gate : nextLevelGates) {
            q.push(gate);
        }
    }
}

bool Parser::compareGateLevels(const std::shared_ptr<Gate>& a, const std::shared_ptr<Gate>& b) {
    return a->getLevel() < b->getLevel();
}
bool Parser::compareGateName(const std::shared_ptr<Gate>& gate, const std::string& name) {
    return gate->getName() == name;
}

void Parser::makeTXT(const std::string& filename) {
    // Replace the ".v" extension from the filename to ".txt"
    std::string txtFilename = filename.substr(0, filename.find_last_of('.')) + ".txt";
    
    std::ofstream outFile(txtFilename);
    if (!outFile) {
        std::cerr << "Error creating file: " << txtFilename << std::endl;
        return;
    }
    
    if (IOnames.size() != (inputCount + outputCount)) {
        std::cerr << "Number of input and output gates does not match module declaration" << std::endl;
        return;                         //Use cerr to output an error message if something goes wrong (not buffered like cout is)
    }
    // Write a header
    //std::cout << "Counted this many IO: " << IOnames.size() << std::endl;

    outFile << "GATES{" << gates.size() << "} ";
    outFile << "INPUTS{" << inputCount <<  "} ";
    outFile << "OUTPUTS{" << outputCount <<  "} ";
    outFile << "DFFS{" << dffArray.size() <<  "}\n";
    // Write the array location of each input, output, and dff in the order they are presented in the header.
    // To do this I am taking the string vector of inputs and outputs we made earlier and matching them to the array locations
    // Of the corresponding input and output, we know outputs always come last so we can just put the first X number
    // of inputs into the inputs brackets, and then put everything else in the output bracket. 
    
    std::vector<int> arrayLocations;
    for (const auto& name : IOnames) {
        auto it = gateMap.find(name);       //Use gate map to find each gate's array location in time O(1)
        if (it != gateMap.end()){
            arrayLocations.push_back(it->second->getArrayLocation());
        }
        else {
            arrayLocations.push_back(-1);   //The gate name was not found, throw an error
            std::cerr << "IO declaration is missing: " << name << std::endl;
        }
    }
    outFile << "INPUTS{";
    for (int i = 0; i < inputCount; ++i) {
        outFile << arrayLocations[i];
        if (i < inputCount - 1) {
            outFile << ", "; 
        }
    }
    outFile << "}\n";
    outFile << "OUTPUTS{";
    for (int i = inputCount; i < inputCount + outputCount; ++i) {
        outFile << arrayLocations[i];
        if (i < inputCount + outputCount - 1) {
            outFile << ", ";
        }
    }
    outFile << "}\n";
    
    //We have to do the same thing with the DFFs but they are stored seperately because they are not declared in the module header
    std::vector<int> dffLocations;
    for (const auto& name : dffArray) {
        auto it = gateMap.find(name);       //Use gate map to find each gate's array location in time O(1)
        if (it != gateMap.end()){
            dffLocations.push_back(it->second->getArrayLocation());
        }
        else {
            dffLocations.push_back(-1);   //The gate name was not found, throw an error
            std::cerr << "IO declaration is missing: " << name << std::endl;
        }
    }
    outFile << "DFFS{";
    for (int i = 0; i < dffArray.size(); i++){
        outFile << dffLocations[i];
        if (i < dffArray.size() - 1) {
            outFile << ", ";
        }
    }
    outFile << "}\n";

    // Write gate details to the file
    for (const auto& gate : gates) {
        outFile << "GATETYPE{" << gateTypeToString(gate->getType()) << "} ";
        outFile << "OUTPUT{" << (gate->getType() == GateType::OUTPUT ? "TRUE" : "FALSE") << "} ";        
        outFile << "GATELEVEL{" << gate->getLevel() << "} ";
        outFile << "FANIN{";
        if (gate->getType() != GateType::INPUT) {
            for (size_t i = 0; i < gate->getFaninGates().size(); ++i) {
                outFile << gate->getFaninGates()[i]->getArrayLocation();
                if (i < gate->getFaninGates().size() - 1) {
                    outFile << ",";         //Make sure we don't add a last unecessary comma
                }
            }
        }
        outFile << "} ";
        
        outFile << "FANOUT{";
        if (gate->getType() != GateType::OUTPUT) {
            for (size_t i = 0; i < gate->getFanoutGates().size(); ++i) {
                outFile << gate->getFanoutGates()[i]->getArrayLocation();
                if (i < gate->getFanoutGates().size() - 1) {
                    outFile << ",";         //Make sure we don't add a last unecessary comma
                }
            }
        }
        outFile << "} ";
        outFile << "GATENAME{" << gate->getName() << "}\n";
    }

    outFile.close();
    std::cout << "File " << txtFilename << " created successfully." << std::endl;
}

void Parser::sortGates() {
    std::sort(gates.begin(), gates.end(), compareGateLevels);
    int i = 0;
    for(const auto& gate : gates){
        gate->setArrayLocation(i);
        i++;
    }
}

void Parser::makeReadableTXT(const std::string& filename) {
    // Replace the ".v" extension from the filename to ".txt"
    std::string txtFilename =filename.substr(0, filename.find_last_of('.')) + "READABLE.txt";
    
    std::ofstream outFile(txtFilename);
    if (!outFile) {
        std::cerr << "Error creating file: " << txtFilename << std::endl;
        return;
    }

    // Write a header
    outFile << "GATES{" << gates.size() << "} ";
    outFile << "INPUTS{" << inputCount <<  "} ";
    outFile << "OUTPUTS{" << outputCount <<  "} ";
    outFile << "DFFS{" << dffArray.size() <<  "}\n";

    // Write the array location of each input, output, and dff in the order they are presented in the header.
    // To do this I am taking the string vector of inputs and outputs we made earlier and matching them to the array locations
    // Of the corresponding input and output, we know outputs always come last so we can just put the first X number
    // of inputs into the inputs brackets, and then put everything else in the output bracket. 
    std::vector<std::string> arrayLocations;
    for (const auto& name : IOnames) {
        auto it = gateMap.find(name);       //Use gate map to find each gate's array location in time O(1)
        if (it != gateMap.end()){
            arrayLocations.push_back(it->second->getName());
        }
        else {
            arrayLocations.push_back("ERROR");   //The gate name was not found, throw an error
            std::cerr << "IO declaration is missing: " << name << std::endl;
        }
    }
    outFile << "INPUTS{";
    for (int i = 0; i < inputCount; ++i) {
        outFile << arrayLocations[i];
        if (i < inputCount - 1) {
            outFile << ", "; 
        }
    }
    outFile << "}\n";
    outFile << "OUTPUTS{";
    for (int i = inputCount; i < inputCount + outputCount; ++i) {
        outFile << arrayLocations[i];
        if (i < inputCount + outputCount - 1) {
            outFile << ", ";
        }
    }
    outFile << "}\n";
    //We have to do the same thing with the DFFs but they are stored seperately because they are not declared in the module header
    std::vector<std::string> dffLocations;
    for (const auto& name : dffArray) {
        auto it = gateMap.find(name);       //Use gate map to find each gate's array location in time O(1)
        if (it != gateMap.end()){
            dffLocations.push_back(it->second->getName());
        }
        else {
            dffLocations.push_back("ERROR");   //The gate name was not found, throw an error
            std::cerr << "IO declaration is missing: " << name << std::endl;
        }
    }
    outFile << "DFFS{";
    for (int i = 0; i < dffArray.size(); i++){
        outFile << dffLocations[i];
        if (i < dffArray.size() - 1) {
            outFile << ", ";
        }
    }
    outFile << "}\n";

    // Write gate details to the file
    for (const auto& gate : gates) {
        outFile << "GATETYPE{" << gateTypeToString(gate->getType()) << "} ";
        outFile << "OUTPUT{" << (gate->getType() == GateType::OUTPUT ? "TRUE" : "FALSE") << "} ";        
        outFile << "GATELEVEL{" << gate->getLevel() << "} ";
        outFile << "FANIN{";
        if (gate->getType() != GateType::INPUT) {
            for (size_t i = 0; i < gate->getFaninGates().size(); ++i) {
                outFile << gate->getFaninGates()[i]->getName();
                if (i < gate->getFaninGates().size() - 1) {
                    outFile << ",";         //Make sure we don't add a last unecessary comma
                }
            }
        }
        outFile << "} ";
        
        outFile << "FANOUT{";
        if (gate->getType() != GateType::OUTPUT) {
            for (size_t i = 0; i < gate->getFanoutGates().size(); ++i) {
                outFile << gate->getFanoutGates()[i]->getName();
                if (i < gate->getFanoutGates().size() - 1) {
                    outFile << ",";         //Make sure we don't add a last unecessary comma
                }
            }
        }
        outFile << "} ";
        outFile << "GATENAME{" << gate->getName() << "}\n";
    }
    outFile.close();
    std::cout << "File " << txtFilename << " created successfully." << std::endl;
}