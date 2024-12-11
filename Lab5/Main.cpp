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
    parser.assignGateLevels();
    parser.sortGates();
    parser.makeTXT(filename);
    std::cout << "Parsed " << parser.getGates().size() << " gates from the file." << std::endl;

    char userResponse;
    std::cout << "Would you like to generate a makeReadableTXT file? (y/n): ";
    std::cin >> userResponse;
    if (userResponse == 'y' || userResponse == 'Y') {
        parser.makeReadableTXT(filename);
    }

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
*/