# Installiere das AzureAD Modul, falls es nicht installiert ist
# Install-Module -Name AzureAD

# Melde dich bei AzureAD an
Connect-AzureAD

# Eingabe der E-Mail-Adressen
$sourceUserEmail = Read-Host "Geben Sie die E-Mail des Quellbenutzers ein"
$targetUserEmail = Read-Host "Geben Sie die E-Mail des Zielbenutzers ein"

# Abrufen der Benutzerobjekte
$sourceUser = Get-AzureADUser -Filter "UserPrincipalName eq '$sourceUserEmail'"
$targetUser = Get-AzureADUser -Filter "UserPrincipalName eq '$targetUserEmail'"

if ($null -eq $sourceUser -or $null -eq $targetUser) {
    Write-Host "Benutzer konnten nicht gefunden werden. Überprüfen Sie die E-Mail-Adressen." -ForegroundColor Red
    exit
}

# Kopieren der Kontaktdaten, Position, Abteilung und Büro
Write-Host "Kontaktdaten, Position, Abteilung und Büro werden kopiert..."
$propertiesToCopy = @("StreetAddress", "City", "State", "PostalCode", "Country", "TelephoneNumber", "Mobile", "JobTitle", "Department", "PhysicalDeliveryOfficeName")

foreach ($property in $propertiesToCopy) {
    $value = $sourceUser.$property
    if ($null -ne $value) {
        Set-AzureADUser -ObjectId $targetUser.ObjectId -$property $value
        Write-Host "Eigenschaft $property kopiert: $value"
    }
}

# Gruppenzugehörigkeit kopieren
Write-Host "Gruppenzugehörigkeit wird kopiert..."
$sourceGroups = Get-AzureADUserMembership -ObjectId $sourceUser.ObjectId
$totalGroups = $sourceGroups.Count
$successfulCopies = 0

foreach ($group in $sourceGroups) {
    # Prüfen, ob der Zielbenutzer bereits in der Gruppe ist
    $isMember = Get-AzureADGroupMember -ObjectId $group.ObjectId | Where-Object { $_.ObjectId -eq $targetUser.ObjectId }
    if ($null -eq $isMember) {
        try {
            Add-AzureADGroupMember -ObjectId $group.ObjectId -RefObjectId $targetUser.ObjectId
            Write-Host "Zielbenutzer zur Gruppe $($group.DisplayName) hinzugefügt."
            $successfulCopies++
        } catch {
            Write-Host "Fehler beim Hinzufügen zur Gruppe $($group.DisplayName): $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Zielbenutzer ist bereits in der Gruppe $($group.DisplayName)."
    }
}

# Zusammenfassung anzeigen
Write-Host "`n"
Write-Host "Zusammenfassung:" -ForegroundColor Cyan
Write-Host "Gruppen insgesamt: $totalGroups"
Write-Host "Erfolgreich kopierte Gruppen: $successfulCopies"
Write-Host "Nicht kopierte Gruppen: $($totalGroups - $successfulCopies)"

Write-Host "Daten erfolgreich kopiert." -ForegroundColor Green
