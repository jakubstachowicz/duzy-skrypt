#include <cstring>
#include <cstdlib>
#include <iostream>

int main(int argc, char *argv[]) {
    std::srand(std::atoi(argv[1]));
    std::cout << rand() % 97 << " " << rand() % 101 << "\n";
}
