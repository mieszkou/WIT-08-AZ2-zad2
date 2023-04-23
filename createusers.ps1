# Urbanowski Mieszko nr alb 3421
# Skrypt zakładający konta w Azure AD na podstawie plików csv w folderze $inFolder
#
# Przy problemach z logowaniem: 
# (...)
# One or more errors occurred. (Could not load type 'System.Security.Cryptography.SHA256Cng' from assembly 'System.Core, Version=4.0.0.0, Culture=neutral, PublicKeyToken=...'.): Could not load type
#      | 'System.Security.Cryptography.SHA256Cng' from assembly 'System.Core, Version=4.0.0.0, Culture=neutral, PublicKeyToken=...'.
# (...)
# to pomoglo: Import-Module AzureAD -UseWindowsPowerShell 
# 🤷


$inFolder = ".\in"
$outFolder = ".\out"
$errorFolder = ".\error"
$logFolder = ".\log"

$tenantid = "5a652136-437b-4def-ba0f-b7ae2ea2da58"
$externalIdExtensionProperty = "extension_bf88dea2157f4090ad834774ae1602e6_externalid"

$logFile = "$logfolder\$(get-date -uformat %Y%m%d)_user_create.log"
$fileList = Get-ChildItem -Path $inFolder -Filter *.csv

# Logowanie danymi odczytanymi z pliku
$Credentials = Import-CliXml "credentials.xml"
# Logowanie interaktywne - prompt o login/hasło
# $Credentials = Get-Credential

# Tworzenie pliku z hasłami (aby przyspieszyć testowanie)
# $Credentials = Get-Credential
# $Credentials | Export-CliXml "credentials.xml"

function Write-Log 
{ 
    Param ([string]$LogString)
    $Stamp = (Get-Date).toString("yyyy-MM-dd HH:mm:ss")
    $LogMessage = "$Stamp $LogString"
    Add-content $logFile -value $LogMessage
}

function New-Password 
{
   Param ([int]$length=12)
   $guid = New-Guid
   "PA" + $guid.Guid.Replace('-','').Substring(0,$length) + "!"
}

# https://lazywinadmin.com/2015/05/powershell-remove-diacritics-accents.html + poprawki
function Remove-StringLatinCharacters
{
    PARAM ([string]$String)
    $result = $String
    $result = [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($result))
    $result = [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding(1250).GetBytes($result))
    $result
}

function Write-UserData
{
    Param(
        [string]$outFolder,
        [string]$login,
        [string]$pass
    )

    $outFile = "$outFolder/$(get-date -uformat %Y%m%d%H%M%S).txt"
    Add-content $outFile -Value $login
    Add-content $outFile -Value $pass
}

Import-Module AzureAD

try {
    Connect-AzureAD -TenantId $tenantid -Credential $Credentials
} catch { 
    Write-Host "🛑 $_"
    Write-Log "ERROR $_"
    exit
}

ForEach ($file in $fileList) {

    Write-Host "📄 $file"

    try {
    
        $data = Import-Csv $file
        Write-Log("Przetwarzam plik $file.")

        if(
            $null -eq $data.imie -or 
            $data.imie -eq '' -or 
            $null -eq $data.nazwisko -or 
            $data.nazwisko -eq '' -or 
            $null -eq $data.dzial -or 
            $data.dzial -eq '' -or 
            $null -eq $data.email -or 
            $data.email -eq '' -or 
            $null -eq $data.lokalizacja -or 
            $data.lokalizacja -eq '' -or 
            $null -eq $data.stanowisko -or 
            $data.stanowisko -eq '' -or 
            $null -eq $data.numer -or
            $data.numer -eq '') { 
            Throw("Bład danych w pliku $file")
        }

        if((Get-AzureADUser -ObjectId "$($data.email)" -ErrorAction SilentlyContinue)) {
            Throw("Uzytkownik $($data.email) już istnieje w AD")
        }

        if(!($group = Get-AzureADGroup -SearchString $($data.dzial))) {
            Throw("Grupa $($data.dzial) nie istnieje w AD (dla $($data.email))")
        }

        if($group.MailEnabled -or !$group.SecurityEnabled) {
            Throw("Grupa $($data.dzial) ma zly typ")
        }

        $displayName = "$($data.imie) $($data.nazwisko)"
        $userPrincipalName = $data.email
        $mailNick = Remove-StringLatinCharacters -String $data.imie + $data.nazwisko.Substring(0,2)
        $passwordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
        $passwordProfile.Password = New-Password 16
        $externalId = $data.numer

        if(!($newUser = New-AzureADUser -DisplayName $displayName -UserPrincipalName $userPrincipalName -AccountEnabled $true -PasswordProfile $passwordProfile -MailNickName $mailNick -Department $data.dzial -City $data.lokalizacja)) {
            Throw("Błąd przy tworzeniu konta")
        }
             
        if(!(Add-AzureADGroupMember -ObjectId $group.ObjectId -RefObjectId $newUser.ObjectId)) {
            Throw("Błąd przy przypisaniu grupy")            
        }
        
        # jak utwurzyć https://learn.microsoft.com/en-us/azure/active-directory/external-identities/user-flow-add-custom-attributes
        if(!(Set-AzureADUserExtension -ObjectId $newUser.ObjectId -ExtensionName $externalIdExtensionProperty -ExtensionValue $externalId)) {
            Throw("Błąd przy przypisaniu external ID")            
        }

        Write-Host "✅ Użytkownik $($data.imie) $($data.nazwisko) został dodany."
        Write-Log "SUCCESS: Użytkownik $($data.email) $($data.imie) $($data.nazwisko) został dodany."
        
        Write-UserData($outFolder, $userPrincipalName, $passwordProfile.Password)
               
        $file | Move-Item -Destination "$outFolder\arch\$(get-date -uformat %Y%m%d%H%M%S)_$($file.BaseName).csv"
    } catch {
        Write-Host "🛑 $_"
        Write-Log "ERROR $_"
        
        $file | Move-Item -Destination "$errorFolder\$(get-date -uformat %Y%m%d%H%M%S)_$($file.BaseName).csv"
    }
    Write-Host
}
Read-Host -Prompt "Naciśnij enter"

