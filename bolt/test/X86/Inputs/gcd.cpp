#include <iostream>
using namespace std;

int main() {
  int X, Y, Result;
  cout << "Enter two numbers: ";
  cin >> X >> Y;

  // swapping variables n1 and n2 if n2 is greater than n1.
  if (Y > X) {
    int Temp = Y;
    Y = X;
    X = Temp;
  }

  for (int I = 1; I <= Y; ++I) {
    if (X % I == 0 && Y % I == 0) {
      Result = I;
    }
  }

  cout << "Greatest common divisor = " << Result << "\n";

  return 0;
}
