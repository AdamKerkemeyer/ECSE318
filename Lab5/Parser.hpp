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
    void makeTXT(const std::string& filename);
    void makeReadableTXT(const std::string& filename);
    void assignGateLevels();
    void sortGates();

private:
    std::string filename;
    std::vector<std::shared_ptr<Gate>> gates;
    std::unordered_map<std::string, GateType> gateTypeMap;
    std::unordered_map<std::string, std::shared_ptr<Gate>> gateMap;
    std::shared_ptr<Gate> previousGate;             //Remember previousGate to set a pointer
    std::vector<std::string> gateLines;             //Store gate lines (GX, GX, GX) to process in a second wave
    int inputCount;
    int outputCount;
    std::vector<std::string> dffArray;              //Used to store the names of every DFF we parse for lookup later
    std::vector<std::string> IOnames;               //Store the order in which the inputs and outputs are declared in the file.

    void initializeGateTypeMap();
    void parseLine(const std::string& line);
    void connectGates(const std::string& output, const std::vector<std::string>& inputs, std::shared_ptr<Gate> gate);
    static bool compareGateLevels(const std::shared_ptr<Gate>& a, const std::shared_ptr<Gate>& b);
    static bool compareGateName(const std::shared_ptr<Gate>& gate, const std::string& name);
    void addBuffersToInputs();
};

#endif
