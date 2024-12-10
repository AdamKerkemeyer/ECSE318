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
    const std::vector<std::shared_ptr<Gate>>& getGates() const;
    std::vector<std::shared_ptr<Gate>>& getGates(); //non constant version for assignGateLevels
    std::string gateTypeToString(GateType type) const;
    GateType stringToGateType(const std::string& typeStr);
    void makeTXT(const std::string& filename, const std::vector<std::shared_ptr<Gate>>& gates) const;
    void assignGateLevels(std::vector<std::shared_ptr<Gate>>& gates) const;
    void sortGates(std::vector<std::shared_ptr<Gate>>& gates) const;

private:
    std::string filename;
    std::vector<std::shared_ptr<Gate>> gates;
    std::unordered_map<std::string, GateType> gateTypeMap;
    std::unordered_map<std::string, std::shared_ptr<Gate>> gateMap;
    std::shared_ptr<Gate> previousGate;             //Remember previousGate to set a pointer
    std::vector<std::string> gateLines;             //Store gate lines (GX, GX, GX) to process in a second wave
    int inputCount;
    int outputCount;
    int dffCount;

    void initializeGateTypeMap();
    void parseLine(const std::string& line);
    void connectGates(const std::string& output, const std::vector<std::string>& inputs, std::shared_ptr<Gate> gate);
    static bool compareGateLevels(const std::shared_ptr<Gate>& a, const std::shared_ptr<Gate>& b);
    void addBuffersToInputs();
};

#endif
