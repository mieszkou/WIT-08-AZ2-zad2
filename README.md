```
ObjectId                             DisplayName Description
--------                             ----------- -----------
103836c6-b214-4354-9641-93dc137ba548 Serwis      mail-enabled security group - serwis
81b0c641-9888-4ec3-8f57-366e86fb0d03 All Company This is the default group for everyone in the network
92cf5aac-5c05-45c4-83b2-e03a49916036 praca       distribution group - praca
bc825870-1a61-4369-b3d8-22919c15be18 ProjektKUO  ProjektKUO
c56f3ce2-2fc3-4c49-a47c-26cf55e06b4f pracownicy  office 365 group - pracownicy
e1b8cf50-8201-4b98-b9f4-c0a06b8cdff7 All Company This is the default group for everyone in the network
ed5ce245-be11-4c87-9f97-9c686b27cb5a biuro       mail-enabled security group - biuro
```

Napisz skrypt w Powershell 7.3 który automatycznie założy konta w AzureAD firmy. 
Konta zakładane są na podstawie informacji z plików csv - osobny plik dla każdego użytkownika.

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
- zapisywać operacje do pliku logu, który znajduje w się w katalogu log 
- po zakończeniu działania skrypt ma przygotować plik testowy z loginem użytkownika (email), który utworzył i zapisać go w katalogu out - nazwa pliku to  
data wykonania operacji wraz z godzina (plik txt) 
- wszystkie możliwe dane opisujemy w zmiennych lub pobieramy z pliku (staramy się nie zaszywać danych w skrypcie) 
- Skrypt ma wykrywać błędy w pliku, które mogą doprowadzić do nie wykonania procedury w całości. W przypadku wystąpienia błędu, skrypt nie tworzy użytkownika tylko przenosi plik do katalogu error - w logu musi się pojawić stosowny komentarz. 

wymagana struktura katalogów 
\skrypt\newusers.ps1 
\skrypt\in
\skrypt\log 
\skrypt\out 
\skrypt\error 


```
Get-Content -Encoding OEM '.\baza kruk.csv'|select -first 1|%{$_ -replace ";CenaDetal:;WP", ';CenaDetal1:;WP'}|Out-File '.\tymczasowy_plik_z_poprawionym_naglowkiem.csv' -Encoding OEM
Get-Content -Encoding OEM '.\baza kruk.csv'|select -skip 1|Out-File '.\tymczasowy_plik_z_poprawionym_naglowkiem.csv' -Append -Encoding oem
Import-Csv -Path '.\tymczasowy_plik_z_poprawionym_naglowkiem.csv' -Delimiter ';' -Encoding OEM | ForEach-Object {
$_.('Grupa towarowa:') = "(1|" + $_.('Stan:') + ")"
$_.('AktMarza:') = $_.('AktMarza:').Replace('%', '')
$_
} | Export-Csv -Path '.\baza_wynik_do_importu.csv' -NoTypeInformation -Encoding OEM -Delimiter ';' 
Get-Content -Encoding OEM '.\baza_wynik_do_importu.csv' | Foreach-Object { $_ -replace '"' ,''} |Out-File '.\baza_wynik_do_importu_final.csv' -Encoding OEM
```


```powershell
# Ustawienie ścieżki do pliku logu
$LogFilePath = "C:\Path\To\Log\File.log"

# Funkcja do zapisu wpisów w pliku logu
function Write-Log {
param(
[Parameter(ValueFromPipeline=$true)]
[string]$Message
)

$FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$LogMessage = "$FormattedDate : $Message"
Add-Content -Path $LogFilePath -Value $LogMessage
}

# Zaimportuj moduł Azure AD
Import-Module AzureAD

# Ustaw zmienne do połączenia z Azure AD
$TenantName = "mytenantname.onmicrosoft.com"
$Credentials = Get-Credential
Connect-AzureAD -TenantName $TenantName -Credential $Credentials

# Ustaw zmienne dla katalogu z plikami CSV
$CSVPath = "C:\Path\To\CSV\Directory"
$CSVFiles = Get-ChildItem $CSVPath -Filter *.csv

# Przejdź przez każdy plik CSV i stwórz użytkowników w Azure AD
foreach ($CSVFile in $CSVFiles) {
$UserData = Import-Csv $CSVFile.FullName

foreach ($User in $UserData) {
# Sprawdź, czy użytkownik istnieje w Azure AD
if (!(Get-AzureADUser -Filter "UserPrincipalName eq '$($User.Email)'")) {
Write-Log "Użytkownik $($User.FirstName) $($User.LastName) nie istnieje w Azure AD. Pomijanie."
continue
}

# Sprawdź, czy dział istnieje w Azure AD
if (!(Get-AzureADGroup -Filter "DisplayName eq '$($User.Department)'")) {
Write-Log "Dział $($User.Department) nie istnieje w Azure AD. Pomijanie."
continue
}

# Stwórz nowego użytkownika w Azure AD
$NewUser = New-AzureADUser -AccountEnabled $true -DisplayName "$($User.FirstName) $($User.LastName)" `
-GivenName $User.FirstName -Surname $User.LastName -UserPrincipalName $User.Email `
-Department $User.Department -UsageLocation "US" -MailNickName $User.FirstName `
-ImmutableId $User.ExternalId

# Dodaj użytkownika do odpowiedniej grupy w Azure AD
$Group = Get-AzureADGroup -Filter "DisplayName eq '$($User.Department)'"
Add-AzureADGroupMember -ObjectId $Group.ObjectId -RefObjectId $NewUser.ObjectId

Write-Log "Dodano użytkownika $($User.FirstName) $($User.LastName) do grupy $($User.Department)."
}
}
```