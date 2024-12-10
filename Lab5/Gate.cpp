#include "Gate.hpp"
#include <memory>

Gate::Gate(const std::string& name, GateType type)
    : name(name), type(type), nextGate(nullptr), level(-1) {}

std::string Gate::getName() const {
    return name;
}

GateType Gate::getType() const {
    return type;
}

const std::vector<std::shared_ptr<Gate>>& Gate::getFaninGates() const {
    return faninGates;
}

const std::vector<std::shared_ptr<Gate>>& Gate::getFanoutGates() const {
    return fanoutGates;
}

std::shared_ptr<Gate> Gate::getNextGate() const {
    return nextGate;
}

const int Gate::getLevel() const {
    return level;
}

const int Gate::getArrayLocation() const {
    return arrayLocation;
}

void Gate::setName(const std::string& name) {
    this->name = name;
}

void Gate::setType(GateType type) {
    this->type = type;
}

void Gate::setFaninGates(const std::vector<std::shared_ptr<Gate>>& faninGates) {
    this->faninGates = faninGates;
}

void Gate::setFanoutGates(const std::vector<std::shared_ptr<Gate>>& fanoutGates) {
    this->fanoutGates = fanoutGates;
}

void Gate::setNextGate(std::shared_ptr<Gate> nextGate) {
    this->nextGate = nextGate;
}

void Gate::setLevel(int level){
    this->level = level;
}

void Gate::setArrayLocation(int arrayLocation){
    this->arrayLocation = arrayLocation;
}

void Gate::addFaninGate(std::shared_ptr<Gate> faninGate) {
    faninGates.push_back(faninGate);        //push_back may not be the most efficient for performance, we will see how this handles big tests
}

void Gate::addFanoutGate(std::shared_ptr<Gate> fanoutGate) {
    fanoutGates.push_back(fanoutGate);
}

//void Gate::removeFaninGate(std::shared_ptr<Gate> faninGate) {
//    faninGates.erase(std::remove(faninGates.begin(), faninGates.end(), faninGate), faninGates.end());
//}
void Gate::removeFaninGate(std::shared_ptr<Gate> faninGate) {
    for (auto it = faninGates.begin(); it != faninGates.end(); ++it) {
        if (*it == faninGate) {
            faninGates.erase(it);
            break;
        }
    }
}

void Gate::removeFanoutGate(std::shared_ptr<Gate> fanoutGate) {
    for (auto it = fanoutGates.begin(); it != fanoutGates.end(); ++it) {
        if (*it == fanoutGate) {
            fanoutGates.erase(it);
            break;
        }
    }
}