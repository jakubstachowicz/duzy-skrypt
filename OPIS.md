# algre

## Przeznaczenie

Skrypt `algre` jest skryptem do przeprowadzania testów rozwiązań algorytmicznych napisanych w C++. 

Po przekazaniu mu pliku wykonywalnego przeprowadzi on serię testów działania tego programu
z testami zawartymi w folderze `./tests/`. Pliki znajdujące się w folderze `./tests/in/`
trafią na wejście programu wykonywalnego, którego wyjście zostanie porównane z odpowiedziami
zawartymi w folderze `./tests/out/`. Ta podstawowa działalność skryptu rozszerzona jest
wieloma możliwościami personalizacji. M. in. przez wskazywanie folderów z testami (zamiast
domyślnego `./tests/`), wzkazywanie numerów testów, które mają być przeprowadzone,
przez wskazanie time limitu na pojedynczy test, żeby sprawdzić prędkość działania rozwiązania,
a także poprzez wiele innych ułatwień.

Możliwe do przekazania są również dwa pliki wykonywalne, wówczas pierwszy traktowany jest
jako testowany, a drugi jako rozwiązanie brute force - dające wzorcowe wyniki. Rozwiązanie to
jest świetnym narzędziem do testowania, kiedy dostępne są jedynie pliki wejściowe.

Jednak i brak plików wejściowych nie jest przeszkodą dla `algre`, ponieważ podając trzy pliki
wykonywalne, ten trzeci traktowany będzie jako generator testów wejściowych. Plik ten
powinien przyjmować 1 parametr wywołania, którym będzie liczba całkowita (seed).
Dzięki temu rozwiązaniu nawet brak testów nie jest straszny.

Pliki wykonywalne jednak trzeba kompilować. `algre` zwalnia programistę z tego obowiązku
rozpoznając automatycznie, czy podany został plik wykonywalny, czy plik źródłowy.
W przypadku tego drugiego kompilacja nastąpi automatycznie z użyciem kompilatora `g++`.
Domyśne flagi kompilacji będzie można również zmieniać do własnych potrzeb.

Całość znacząco przyspiesza proces testowania, zwłaszcza dla użytkowników `vscode`.
Skrypt bowiem zawiera automatyczną generację taska uruchomieniowego, umożliwiającego
uruchomienie `algre` z flagami poprzez kliknięcie jednego przycisku w edytorze.
