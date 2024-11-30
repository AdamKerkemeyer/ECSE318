#ifndef GATE_H  //include guard
#define GATE_H  //When the preprocessor encounters #ifndef GATE_H, it checks if GATE_H is already defined. 
                //If it is not, it processes the code between #ifndef and #endif. 
                //If GATE_H is already defined (because the header file has been included before), 
                //it skips the code between #ifndef and #endif.

#include <string>
#include <vector>

enum class GateType {
    AND,         //I tried to use lowercase but that will throw an erorr because these are keywords in c++
    OR,
    NOT,
    NOR,
    NAND,
    DFF,
    INPUT,
    OUTPUT,
    BUFFER
};              //Without this the compiler sees one declaration with two types. 

class Gate {
private:
    std::string name;
    std::string type;
    std::vector<Gate*> faninGates;      //Vector is a dynamic array
    std::vector<Gate*> fanoutGates;
    Gate* nextGate;                     //Gate* is a pointer to the Gate class

public:
    // Saab: XOR characters for 2^8 buckets for hash map (we pick 8 because each string character is 8 bits)
    Gate(const std::string& name, GateType type);

    std::string getName() const;        //Having const indicates calling this function will not change what it is accessing
    GateType getType() const;        
    std::vector<Gate*> getFaninGates() const;
    std::vector<Gate*> getFanoutGates() const;
    Gate* getNextGate() const;

    void setName(const std::string& name);  //const here before a parameter means that it won't be changed by the constructor
    void setType(GateType type);
    void setFaninGates(const std::vector<Gate*>& faninGates);
    void setFanoutGates(const std::vector<Gate*>& fanoutGates);
    void setNextGate(Gate* nextGate);

    void addFaninGate(Gate* faninGate);
    void addFanoutGate(Gate* fanoutGate);
};

#endif