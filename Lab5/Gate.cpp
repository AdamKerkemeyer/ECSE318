#include "Gate.h"

// Constructor
Gate::Gate(const std::string& name, const std::string& type)
    : name(name), type(type), nextGate(nullptr) {}

// Getters
std::string Gate::getName() const {
    return name;
}

std::string Gate::getType() const {
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

void Gate::setType(const std::string& type) {
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
