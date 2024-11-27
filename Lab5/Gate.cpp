#include "Gate.h"

// Constructor
Gate::Gate(const std::string& name, GateType type)
    : name(name), type(type), nextGate(nullptr) {}

// Getters
std::string Gate::getName() const {
    return name;
}

GateType Gate::getType() const {
    return type;
}

std::vector<Gate*> Gate::getFaninGates() const {
    return faninGates;
}

std::vector<Gate*> Gate::getFanoutGates() const {
    return fanoutGates;
}

Gate* Gate::getNextGate() const {
    return nextGate;
}

// Setters
void Gate::setName(const std::string& name) {
    this->name = name;
}

void Gate::setType(GateType type) {
    this->type = type;
}

void Gate::setFaninGates(const std::vector<Gate*>& faninGates) {
    this->faninGates = faninGates;
}

void Gate::setFanoutGates(const std::vector<Gate*>& fanoutGates) {
    this->fanoutGates = fanoutGates;
}

void Gate::setNextGate(Gate* nextGate) {
    this->nextGate = nextGate;
}
