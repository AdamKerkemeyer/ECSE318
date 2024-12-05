#include "Gate.hpp"

Gate::Gate(const std::string& name, GateType type)
    : name(name), type(type), faninGates(), fanoutGates(), nextGate(nullptr), level(-1) {}

std::string Gate::getName() const {
    return name;
}

GateType Gate::getType() const {
    return type;
}

const std::vector<Gate*>& Gate::getFaninGates() const {
    return faninGates;
}

const std::vector<Gate*>& Gate::getFanoutGates() const {
    return fanoutGates;
}

Gate* Gate::getNextGate() const {
    return nextGate;
}

const int Gate::getLevel() const {
    return level;
}

const logic Gate::getState() const{
    return state;
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

void Gate::setLevel(int level){
    this->level = level;
}

void Gate::setState(logic state){
    this->state = state;
}

void Gate::addFaninGate(Gate* faninGate) {
    faninGates.push_back(faninGate);        //push_back may not be the most efficient for performance, we will see how this handles big tests
}

void Gate::addFanoutGate(Gate* fanoutGate) {
    fanoutGates.push_back(fanoutGate);
}