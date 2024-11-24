#ifndef GATE_H
#define GATE_H

#include <string>
#include <vector>

class Gate {
private:
    std::string name;
    std::string type;
    std::vector<Gate*> faninGates;
    std::vector<Gate*> fanoutGates;
    Gate* nextGate;

public:
    // Constructor
    Gate(const std::string& name, const std::string& type);

    // Getters
    std::string getName() const;
    std::string getType() const;
    std::vector<Gate*> getFaninGates() const;
    std::vector<Gate*> getFanoutGates() const;
    Gate* getNextGate() const;

    // Setters
    void setName(const std::string& name);
    void setType(const std::string& type);
    void setFaninGates(const std::vector<Gate*>& faninGates);
    void setFanoutGates(const std::vector<Gate*>& fanoutGates);
    void setNextGate(Gate* nextGate);
};

#endif // GATE_H
