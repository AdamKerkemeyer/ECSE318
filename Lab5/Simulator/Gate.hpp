#ifndef GATE_H  //When the preprocessor encounters #ifndef GATE_H, it checks if GATE_H is already defined. 
                //If it is not, it processes the code between #ifndef and #endif. 
                //If GATE_H is already defined (because the header file has been included before), 
                //it skips the code between #ifndef and #endif.
#define GATE_H

#include <string>
#include <vector>
#include <memory>

//#include "Simlulator.hpp"

enum class GateType {
    AND,
    OR,
    NOT,
    NOR,
    NAND,
    DFF,
    INPUT,
    OUTPUT,
    BUFFER
};                                         //Without this the compiler sees one declaration with two types. 

enum class logic{//Three valued logic has... three values
    zero = 0,
    one = 1,
    X = 2
};

class Gate {
private:
    std::string name;
    GateType type;
    std::vector<std::shared_ptr<Gate>> faninGates;      //Vector is a dynamic array
    std::vector<std::shared_ptr<Gate>> fanoutGates;
    std::shared_ptr<Gate> nextGate;                     //Gate* is a pointer to the Gate class
    int level;                          //level is a value used to keep track of simluation order.
    logic state;                        //Holds the present output state of the gate during simlulation

public:
    // Saab: XOR characters for 2^8 buckets for hash map (we pick 8 because each string character is 8 bits)
    Gate(const std::string& name, GateType type);

    std::string getName() const;            //Having const indicates calling this function will not change what it is accessing
    GateType getType() const;
    const std::vector<std::shared_ptr<Gate>> & getFaninGates() const;        //First const indicates the method returns a constant reference
    const std::vector<std::shared_ptr<Gate>> & getFanoutGates() const;       //Second indicates that the get function does not modify any member variables
    std::shared_ptr<Gate> getNextGate() const;
    const int getLevel() const;
    const logic getState() const;

    void setName(const std::string& name);  //const here before a parameter means that it won't be changed by the constructor
    void setType(GateType type);
    void setFaninGates(const std::vector<std::shared_ptr<Gate>> & faninGates);
    void setFanoutGates(const std::vector<std::shared_ptr<Gate>> & fanoutGates);
    void setNextGate(std::shared_ptr<Gate> nextGate);
    void setLevel(const int level);
    void setState(const logic state);

    void addFaninGate(std::shared_ptr<Gate> faninGate);
    void addFanoutGate(std::shared_ptr<Gate> fanoutGate);
};

#endif