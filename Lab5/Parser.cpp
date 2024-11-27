#include "Parser.hpp"
#include <fstream>
#include <sstream>
#include <iostream>
#include <regex>

class Parser {
public:
    Parser(const std::string& filename);
    void parse();
    const std::vector<Gate*>& getGates() const;

private:
    std::string filename;
    std::vector<Gate*> gates;
    std::unordered_map<std::string, GateType> gateTypeMap;
    std::unordered_map<std::string, Gate*> gateMap;

    void initializeGateTypeMap();
    GateType stringToGateType(const std::string& typeStr);
    void parseLine(const std::string& line);
    void connectGates(const std::string& output, const std::vector<std::string>& inputs);
};

Parser::Parser(const std::string& filename) : filename(filename) {
    initializeGateTypeMap();
}

void Parser::initializeGateTypeMap() {
    gateTypeMap["and"] = GateType::and;
    gateTypeMap["or"] = GateType::or;
    gateTypeMap["not"] = GateType::not;
    gateTypeMap["nor"] = GateType::nor;
    gateTypeMap["nand"] = GateType::nand;
    gateTypeMap["input"] = GateType::input;
    gateTypeMap["output"] = GateType::output;
    gateTypeMap["buffer"] = GateType::buffer;

}

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