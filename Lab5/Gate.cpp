#include "Gate.hpp"

Gate::Gate(const std::string& name, GateType type)
    : name(name), type(type), faninGates(), fanoutGates(), nextGate(nullptr) {}

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

void Gate::addFaninGate(Gate* faninGate) {
    faninGates.push_back(faninGate);        //push_back may not be the most efficient for performance, we will see how this handles big tests
}

void Gate::addFanoutGate(Gate* fanoutGate) {
    fanoutGates.push_back(fanoutGate);
}