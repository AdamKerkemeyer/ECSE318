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

std::string gateTypeToString(GateType type) {
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
            line = line.substr(4);          //remove keyword "wire" the first time we see it
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
                    Gate* wireGate = new Gate(wire, GateType::BUFFER);
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
        name = std::regex_replace(name, std::regex("^\\s+|\\s+$"), "");
        Gate* inputGate = new Gate(name, GateType::INPUT);  //Remove any other whitespace
        gates.push_back(inputGate);
        gateMap[name] = inputGate;
        return;
    }

    if (line.find("output") == 0) {
        std::string name = line.substr(7);                  //delete "output "
        name = std::regex_replace(name, std::regex("^\\s+|\\s+$"), "");
        Gate* outputGate = new Gate(name, GateType::OUTPUT);
        gates.push_back(outputGate);
        gateMap[name] = outputGate;
        return;
    }
    //Normal Gate Parse:
    std::regex gateRegex(R"((\w+)\s+(\w+)\s+\(([^)]+)\);)");
    std::smatch match;
    if (std::regex_search(line, match, gateRegex)) {
        std::string typeStr = match[1];
        std::string name = match[2];
        std::string connections = match[3];

        GateType type = stringToGateType(typeStr);
        Gate* gate = new Gate(name, type);
        gates.push_back(gate);
        gateMap[name] = gate;

        if (previousGate) {
            previousGate->setNextGate(gate);
        }
        previousGate = gate;

        std::istringstream connStream(connections);
        std::string output;
        std::vector<std::string> inputs;
        connStream >> output;
        std::string input;
        while (connStream >> input) {
            inputs.push_back(input);
        }

        connectGates(output, inputs);
    }
}

//This entire connectGates is wrong and does not add fanin or fanout gates
//Commented out code is also wrong. Will need to redo this function from the ground up
//To run on its own after the entire file has been processed and "find" gates to wire up to
//Using the unordered map and gate names, parsing the file a second time.
void Parser::connectGates(const std::string& output, const std::vector<std::string>& inputs) {
    Gate* outputGate = gateMap[output];
    /*if(!outputGate) {
        outputGate = new Gate(output, GateType::BUFFER);
        gates.push_back(outputGate);
        gateMap[output] = outputGate;
    }*/

    for (const std::string& input : inputs) {
        Gate* inputGate = gateMap[input];
        /*if(!inputGate){
            inputGate = new Gate(input, GateType::BUFFER);
            gates.push_back(inputGate);
            gateMap[input] = inputGate;
        }*/
       if(inputGate){
        outputGate->addFaninGate(inputGate);
        inputGate->addFanoutGate(outputGate);
       }
    }
}

const std::vector<Gate*>& Parser::getGates() const {
    return gates;
}