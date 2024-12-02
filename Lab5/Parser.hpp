#ifndef PARSER_H
#define PARSER_H

#include "Gate.hpp"
#include <string>
#include <vector>
#include <unordered_map>

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
    Gate* previousGate;                             //Remember previousGate to set a pointer

    void initializeGateTypeMap();
    GateType stringToGateType(const std::string& typeStr);
    void parseLine(const std::string& line);
    void connectGates(const std::string& output, const std::vector<std::string>& inputs);
};

std::string gateTypeToString(GateType type);

#endif
