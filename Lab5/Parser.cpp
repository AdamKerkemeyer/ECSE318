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
    gateTypeMap["and"] = GateType::AND;
    gateTypeMap["or"] = GateType::OR;
    gateTypeMap["not"] = GateType::NOT;
    gateTypeMap["nor"] = GateType::NOR;
    gateTypeMap["nand"] = GateType::NAND;
    gateTypeMap["input"] = GateType::INPUT;
    gateTypeMap["output"] = GateType::OUTPUT;
    gateTypeMap["buffer"] = GateType::BUFFER;
}

std::string gateTypeToString(GateType type) {
    switch (type) {
        case GateType::AND: return "and";
        case GateType::OR: return "or";
        case GateType::NOT: return "not";
        case GateType::NOR: return "nor";
        case GateType::NAND: return "nand";
        case GateType::INPUT: return "input";
        case GateType::OUTPUT: return "output";
        case GateType::BUFFER: return "buffer";
        default: return "ERROR: GATE TYPE UNKNOWN";
    }
}

//Used by the parser to swap the string with the type
GateType Parser::stringToGateType(const std::string& typeStr) {
    return gateTypeMap[typeStr];
}

void Parser::parse() {
    std::ifstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Error opening file: " << filename << std::endl;
        return;
    }

    std::string line;
    while (std::getline(file, line)) {
        parseLine(line);
    }

    file.close();
}

void Parser::parseLine(const std::string& line) {
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

void Parser::connectGates(const std::string& output, const std::vector<std::string>& inputs) {
    Gate* outputGate = gateMap[output];
    for (const std::string& input : inputs) {
        Gate* inputGate = gateMap[input];
        if (inputGate) {
            outputGate->addFaninGate(inputGate);
            inputGate->addFanoutGate(outputGate);
        }
    }
}

const std::vector<Gate*>& Parser::getGates() const {
    return gates;
}