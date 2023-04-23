# WIT AZ2 Zad2

Automatyzacja zakładania kont w AzureAD Twojej firmy. 
Konta zakładane są na podstawie informacji z systemu HR, którym jest plikiem csv. 

Plik csv zawiera następujące informacje: 

- imię 
- nazwisko 
- stanowisko 
- manager (email) 
- lokalizacja (biuro) 
- nazwa działu 
- numer pracownika 

każdy pracownik w momencie utworzenia dostaje grupę która reprezentuje jego zespól/dział. 
Skrypt ma: 
zapisywać operacje do pliku logu, który znajduje w się w katalogu log 
po zakończeniu działania skrypt ma przygotować plik testowy z loginem użytkownika (email), który utworzył i zapisać go w katalogu out - nazwa pliku to  
data wykonania operacji wraz z godzina (plik txt) 
wszystkie możliwe dane opisujemy w zmiennych lub pobieramy z pliku (staramy się nie zaszywać danych w skrypcie) 
Skrypt ma wykrywać błędy w pliku, które mogą doprowadzić do nie wykonania procedury w całości. W przypadku wystąpienia błędu, skrypt nie tworzy użytkownika tylko przenosi plik do katalogu error - w logu musi się pojawić stosowny komentarz. 
jako wynik zadania przygotuj sprawozdanie, które opisuje proces tworzenia użytkownika 
sprawozdanie ma być napisane w formie dokumentacji, dla innej osoby 
Ma zawierać stronę tytułową, spis treści, spis ilustracji jeżeli wstawiane 
W sprawozdaniu umieszczamy screen, świadczące o poprawnym wykonaniu się skryptu 
plik sprawozdanie pdf 

Dołączamy także plik skryptu. 

