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
    dffCount = 0;                       //Reset private counters
    inputCount = 0;
    outputCount = 0;
    if (!file.is_open()) {
        std::cerr << "Error opening file: " << filename << std::endl;
        return;                         //Use cerr to output an error message if something goes wrong (not buffered like cout is)
    }

    std::string line;
    bool parsingWires = false;          //Due to only 1 wire declaration, parser must remember it is reading wires until ";"
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
                dffCount++;
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

void Parser::assignGateLevels(std::vector<std::shared_ptr<Gate>>& gates) const {
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

void Parser::makeTXT(const std::string& filename, const std::vector<std::shared_ptr<Gate>>& gates) const{
    // Replace the ".v" extension from the filename to ".txt"
    std::string txtFilename = filename.substr(0, filename.find_last_of('.')) + ".txt";
    
    std::ofstream outFile(txtFilename);
    if (!outFile) {
        std::cerr << "Error creating file: " << txtFilename << std::endl;
        return;
    }
    // Write a header
    outFile << "GATES{" << gates.size() << "} ";
    outFile << "INPUTS{" << inputCount <<  "} ";
    outFile << "OUTPUTS{" << outputCount <<  "} ";
    outFile << "DFFS{" << dffCount <<  "}\n";

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

void Parser::sortGates(std::vector<std::shared_ptr<Gate>>& gates) const {
    std::sort(gates.begin(), gates.end(), compareGateLevels);
    int i = 0;
    for(const auto& gate : gates){
        gate->setArrayLocation(i);
        i++;
    }
}