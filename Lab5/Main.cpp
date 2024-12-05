#include "Parser.hpp"
#include <iostream>
#include <fstream>      //Need to create, read from, and write to files
void makeTXT(const std::string& filename, const std::vector<std::shared_ptr<Gate>>& gates) {
    // Replace the ".v" extension from the filename to ".txt"
    std::string txtFilename = filename.substr(0, filename.find_last_of('.')) + ".txt";
    
    std::ofstream outFile(txtFilename);
    if (!outFile) {
        std::cerr << "Error creating file: " << txtFilename << std::endl;
        return;
    }

    // Write gate details to the file
    for (const auto& gate : gates) {
        outFile << "GATETYPE{" << gateTypeToString(gate->getType()) << "} ";
        outFile << "OUTPUT{" << (gate->getType() == GateType::OUTPUT ? "TRUE" : "FALSE") << "} ";        
        outFile << "GATELEVEL{" << gate->getLevel() << "} ";
        outFile << "FANIN{";
        if (gate->getType() != GateType::BUFFER && gate->getType() != GateType::INPUT && gate->getType() != GateType::OUTPUT) {
            for (size_t i = 0; i < gate->getFaninGates().size(); ++i) {
                outFile << gate->getFaninGates()[i]->getName();
                if (i < gate->getFaninGates().size() - 1) {
                    outFile << ",";         //Make sure we don't add a last unecessary comma
                }
            }
        }
        outFile << "} ";
        
        outFile << "FANOUT{";
        if (gate->getType() != GateType::BUFFER && gate->getType() != GateType::INPUT && gate->getType() != GateType::OUTPUT) {
            for (size_t i = 0; i < gate->getFanoutGates().size(); ++i) {
                outFile << gate->getFanoutGates()[i]->getName();
                if (i < gate->getFanoutGates().size() - 1) {
                    outFile << ",";         //Make sure we don't add a last unecessary comma
                }
            }
        }
        outFile << "} ";
        outFile << "GATENAME{" << gate->getName() << "}\n";
    }

    outFile.close();
    std::cout << "File " << txtFilename << " created successfully." << std::endl;
}

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

    const std::vector<std::shared_ptr<Gate>>& gates = parser.getGates();
    std::cout << "Parsed " << gates.size() << " gates from the file." << std::endl;

    makeTXT(filename, gates);

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
Change main to ask if the user would like a printout of gates
Make printout a callable function that uses the getNextGate() instead of vector array.
printout should also write to a .txt file the simulator can read. 

Potentially rework parser to not use a vector of gates when instantiating.
Rework parser input/output to parse by semicolon instead of line.
Split wires that go to multiple gates into multiple buffers

Write a prospectus to submit with it
*/