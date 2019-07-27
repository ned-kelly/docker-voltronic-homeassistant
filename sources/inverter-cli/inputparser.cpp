// @author iain

#include <algorithm>
#include <string>
#include <vector>
#include "inputparser.h"

// This class simply finds cmd line args and parses them for use in a program.
// It is not posix compliant and wont work with args like:   ./program -xf filename
// You must place each arg after its own seperate dash like: ./program -x -f filename

InputParser::InputParser (int &argc, char **argv) {
    for (int i=1; i < argc; ++i)
        this->tokens.push_back(std::string(argv[i]));
}

const std::string& InputParser::getCmdOption(const std::string &option) const {
    std::vector<std::string>::const_iterator itr;
    itr =  std::find(this->tokens.begin(), this->tokens.end(), option);
    if (itr != this->tokens.end() && ++itr != this->tokens.end())
    {
        return *itr;
    }
    static const std::string empty_string("");
    return empty_string;
}

bool InputParser::cmdOptionExists(const std::string &option) const {
    return std::find(this->tokens.begin(), this->tokens.end(), option)
           != this->tokens.end();
}

std::vector <std::string> tokens;