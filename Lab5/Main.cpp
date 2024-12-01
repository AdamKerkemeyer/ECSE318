#include "Parser.hpp"
#include <iostream>

int main() {
    std::string filename;
    std::cout << "Enter the name of the .v file to parse: ";
    std::cin >> filename;

    Parser parser(filename);
    parser.parse();

    const std::vector<Gate*>& gates = parser.getGates();
    std::cout << "Parsed " << gates.size() << " gates from the file." << std::endl;

    // Print details of each gate, including fanin and fanout gates
    for (const Gate* gate : gates) {
        std::cout << "Gate: " << gate->getName() << ", Type: " << gateTypeToString(gate->getType()) << std::endl;

        // Print fanin gates
        std::cout << "  Fanin gates: ";
        for (const Gate* faninGate : gate->getFaninGates()) {
            std::cout << faninGate->getName() << " ";
        }
        std::cout << std::endl;

        // Print fanout gates
        std::cout << "  Fanout gates: ";
        for (const Gate* fanoutGate : gate->getFanoutGates()) {
            std::cout << fanoutGate->getName() << " ";
        }
        std::cout << std::endl;
    }

    return 0;
}