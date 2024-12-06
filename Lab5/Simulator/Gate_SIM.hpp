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

class Gate{
public:
    // Saab: XOR characters for 2^8 buckets for hash map (we pick 8 because each string character is 8 bits)
    Gate(const std::string& name, GateType type, size_t faninSize, size_t fanoutSize);

    std::string getName() const;            //Having const indicates calling this function will not change what it is accessing
    GateType getType() const;
    std::vector<unsigned int>& getFaninGates();        //First const indicates the method returns a constant reference
    std::vector<unsigned int>& getFanoutGates();       //Second indicates that the get function does not modify any member variables
    //std::shared_ptr<Gate> getNextGate() const;
    const int getLevel() const;
    const logic getState() const;
    const bool getIsOutput() const;

    void setName(const std::string& name);  //const here before a parameter means that it won't be changed by the constructor
    void setType(GateType type);
    void setFaninGates(const std::vector<unsigned int>& faninGates);
    void setFanoutGates(const std::vector<unsigned int>& fanoutGates);
    //void setNextGate(std::shared_ptr<Gate> nextGate);
    void setLevel(const int level);
    void setState(const logic state);
    void setIsOutput(const bool inOutput);
    void printGate();

private:
    std::string name;
    GateType type;
    std::vector<unsigned int> faninGates;   //Vector is a dynamic array
    std::vector<unsigned int> fanoutGates;
    //std::shared_ptr<Gate> nextGate;                     //Gate* is a pointer to the Gate class
    int level;                          //level is a value used to keep track of simluation order.
    logic state;                        //Holds the present output state of the gate during simlulation
    bool isOutput;


};

#endif