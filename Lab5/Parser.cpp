#include "Parser.hpp"
#include <fstream>
#include <sstream>
#include <iostream>
#include <regex>
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
        case GateType::AND:     return "and";
        case GateType::OR:      return "or";
        case GateType::NOT:     return "not";
        case GateType::NOR:     return "nor";
        case GateType::NAND:    return "nand";
        case GateType::DFF:     return "dff";
        case GateType::INPUT:   return "input";
        case GateType::OUTPUT:  return "output";
        case GateType::BUFFER:  return "buffer";
        default: return "ERROR: GATE TYPE UNKNOWN";
    }
}

//Used by the parser to swap the string with the type
GateType Parser::stringToGateType(const std::string& typeStr) {
    return gateTypeMap[typeStr];
}

void Parser::parse() {
    std::ifstream file(filename);       //Lets us read lines from a file into a string
    if (!file.is_open()) {
        std::cerr << "Error opening file: " << filename << std::endl;
        return;                         //Use cerr to output an error message if something goes wrong (not buffered like cout is)
    }

    std::string line;
    bool parsingWires = false;            //Due to only 1 wire declaration, parser must remember it is reading wires until ";"
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
}

void Parser::parseLine(const std::string& line) {
    //Check if line is input/output, if not, handle as a gate (wires are processed in parse)
    if (line.find("input") == 0) {
        std::string name = line.substr(6);                  //delete "input "
        name = std::regex_replace(name, std::regex(";"), "");        
        name = std::regex_replace(name, std::regex("^\\s+|\\s+$"), "");
        auto inputGate = std::make_shared<Gate>(name, GateType::INPUT);
        gates.push_back(inputGate);
        gateMap[name] = inputGate;
        return;
    }

    else if (line.find("output") == 0) {
        std::string name = line.substr(7);                  //delete "output "
        name = std::regex_replace(name, std::regex(";"), "");        
        name = std::regex_replace(name, std::regex("^\\s+|\\s+$"), "");
        auto outputGate = std::make_shared<Gate>(name, GateType::OUTPUT);
        gates.push_back(outputGate);
        gateMap[name] = outputGate;
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

            if (previousGate) {
                previousGate->setNextGate(gate);
            }
            previousGate = gate;

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

const std::vector<std::shared_ptr<Gate>>& Parser::getGates() const {
    return gates;
}

void Parser::makeTXT(const std::string& filename, const std::vector<std::shared_ptr<Gate>>& gates) const{
    // Replace the ".v" extension from the filename to ".txt"
    std::string txtFilename = filename.substr(0, filename.find_last_of('.')) + ".txt";
    
    std::ofstream outFile(txtFilename);
    if (!outFile) {
        std::cerr << "Error creating file: " << txtFilename << std::endl;
        return;
    }
    //First Write A File Header:


    // Write gate details to the file
    for (const auto& gate : gates) {
        outFile << "GATETYPE{" << gateTypeToString(gate->getType()) << "} ";
        outFile << "OUTPUT{" << (gate->getType() == GateType::OUTPUT ? "TRUE" : "FALSE") << "} ";        
        outFile << "GATELEVEL{" << gate->getLevel() << "} ";
        outFile << "FANIN{";
        if (gate->getType() != GateType::BUFFER && gate->getType() != GateType::INPUT && gate->getType() != GateType::OUTPUT) {
            for (size_t i = 0; i < gate->getFaninGates().size(); ++i) {
                outFile << gate->getFaninGates()[i]->getName();
                if (i < gate->getFaninGates().size() - 1) {
                    outFile << ",";         //Make sure we don't add a last unecessary comma
                }
            }
        }
        outFile << "} ";
        
        outFile << "FANOUT{";
        if (gate->getType() != GateType::BUFFER && gate->getType() != GateType::INPUT && gate->getType() != GateType::OUTPUT) {
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