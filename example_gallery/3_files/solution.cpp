#include <cstdlib>
#include <ctime>
#include <iostream>

int main() {
    int a, b;
    std::cin >> a >> b;
    std::srand(std::time(nullptr));
    std::cout << a + b + rand() % 2 << "\n";
}
