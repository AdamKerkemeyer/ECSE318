#include "Gate_SIM.hpp"
#include <memory>
#include <iostream>

Gate::Gate(const std::string& name, GateType type, size_t faninSize, size_t fanoutSize)
    : name(name), type(type), level(-1), faninGates(std::vector<unsigned int>(faninSize)), fanoutGates(std::vector<unsigned int>(fanoutSize)), state(logic::X) {}

std::string Gate::getName() const {
    return name;
}

GateType Gate::getType() const {
    return type;
}

std::vector<unsigned int>& Gate::getFaninGates() {
    return faninGates;
}

std::vector<unsigned int>& Gate::getFanoutGates() {
    return fanoutGates;
}

/*
std::shared_ptr<Gate> Gate::getNextGate() const {
    return nextGate;
}
*/

const int Gate::getLevel() const {
    return level;
}

const logic Gate::getState() const{
    return state;
}

const bool Gate::getIsOutput() const{
    return isOutput;
}

void Gate::setName(const std::string& name) {
    this->name = name;
}

void Gate::setType(GateType type) {
    this->type = type;
}

void Gate::setFaninGates(const std::vector<unsigned int>& faninGates) {
    this->faninGates = faninGates;
}

void Gate::setFanoutGates(const std::vector<unsigned int>& fanoutGates) {
    this->fanoutGates = fanoutGates;
}

/*
void Gate::setNextGate(std::shared_ptr<Gate> nextGate) {
    this->nextGate = nextGate;
}
*/

void Gate::setLevel(int level){
    this->level = level;
}

void Gate::setState(logic state){
    this->state = state;
}

void Gate::setIsOutput(const bool isOutput){
    this->isOutput = isOutput;
}

void Gate::printGate(){

    std::cout << "NAME:   " << this->getName() <<"\n";

    std::string typeString = "";
    if (this->getType() == GateType::AND) typeString = "AND";
    else if (this->getType() == GateType::OR) typeString = "OR";
    else if (this->getType() == GateType::NAND) typeString = "NAND";
    else if (this->getType() == GateType::NOR) typeString = "NOR";
    else if (this->getType() == GateType::INPUT) typeString = "INPUT";
    else if (this->getType() == GateType::OUTPUT) typeString = "OUTPUT";
    else if (this->getType() == GateType::DFF) typeString = "DFF";
    else if (this->getType() == GateType::BUFFER) typeString = "BUFFER";
    else if (this->getType() == GateType::NOT) typeString = "NOT";
    std::cout << "type:   " << typeString << "\n";

    for (unsigned int num : this->getFaninGates()){
        std::cout << "FANIN:  " << num << "\n";
    }
    for (unsigned int num : this->getFanoutGates()){
        std::cout << "fanout: " << num << "\n";
    }

    std::cout << "LEVEL:  " << this->getLevel() << "\n";

    std::string stateString = "";
    if (this->getState() == logic::X) stateString = "X";
    else if (this->getState() == logic::zero) stateString = "0";
    else if (this->getState() == logic::one) stateString = "1";
    std::cout << "state:  " << stateString << "\n";

    std::cout << "OUTPUT: " << this->getIsOutput() << "\n";
}
