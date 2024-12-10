#include "Parser.hpp"
#include <iostream>
#include <fstream>      //Need to create, read from, and write to files

int main() {
    std::string filename;
    std::cout << "Enter the name of the .v file to parse: ";
    std::cin >> filename;

    // Check if the filename already includes the "Tests/" folder
    std::string folder = "Tests/";
    if (filename.find(folder) != 0) {       //Search for a substring here
        filename = folder + filename;       //If it is not there, append it
    }

    Parser parser(filename);
    parser.parse();

    std::vector<std::shared_ptr<Gate>>& gates = parser.getGates();              //By not putting const in front we are calling the non constant getGates();
    std::cout << "Parsed " << gates.size() << " gates from the file." << std::endl;
    
    parser.assignGateLevels(gates);
    parser.sortGates(gates);
    parser.makeTXT(filename, gates);

    /* Original Printout:
    Don't delete, I am going to put this in a function that will run on the terminal because it puts the information in the most readable format
    // Print details of each gate, including fanin and fanout gates
    for (const Gate* gate : gates) {
        std::cout << "Gate: " << gate->getName() << ", Type: " << gateTypeToString(gate->getType()) << std::endl;

        std::cout << "  Fanin gates: ";
        for (const Gate* faninGate : gate->getFaninGates()) {
            std::cout << faninGate->getName() << " ";
        }
        std::cout << std::endl;

        std::cout << "  Fanout gates: ";
        for (const Gate* fanoutGate : gate->getFanoutGates()) {
            std::cout << fanoutGate->getName() << " ";
        }
        std::cout << std::endl;
    }
    */
    return 0;
}

/*
# Compile the program
g++ -o main main.cpp Parser.cpp Gate.cpp

# Run the program
./main

TODO:
printout should also write to a .txt file the simulator can read. 

Potentially rework parser to not use a vector of gates when instantiating.
Rework parser input/output to parse by semicolon instead of line.
Split wires that go to multiple gates into multiple buffers

Write a prospectus to submit with it
    Explain that buffers are used to "split" gate outputs
*/