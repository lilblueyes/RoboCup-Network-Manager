$interfaceName = "Wi-Fi"
$wifiName = "MSL_FIELD_B_b"

# Demander à l'utilisateur de choisir un robot
do {
    Write-Host ""
    $robotChoice = Read-Host "Entrez numero robot (1-2-3-4-5)"
    if ($robotChoice -notin '1','2','3','4','5') {
        Write-Host ""
        Write-Host "Choix invalide. Veuillez recommencer."
        Write-Host ""
    }
} while ($robotChoice -notin '1','2','3','4','5')

# Déterminer l'adresse IP en fonction du choix de l'utilisateur
switch ($robotChoice) {
    1 { $ipAddressSuffix = 100 }
    2 { $ipAddressSuffix = 101 }
    3 { $ipAddressSuffix = 102 }
    4 { $ipAddressSuffix = 103 }
    5 { $ipAddressSuffix = 104 }
}

$ipAddress = "172.16.79.$ipAddressSuffix"
$subnetMask = 16  # Correspond à 255.255.0.0
$gateway = "172.16.2.1"
$dnsPrimary = "172.16.2.1"
$dnsSecondary = ""

Write-Host ""

# Désactiver IPv6
try {
    Set-NetAdapterBinding -Name $interfaceName -ComponentID ms_tcpip6 -Enabled $False
    Write-Host ""
    Write-Host "IPv6 OFF"
    Write-Host ""
} catch {
    Write-Host ""
    Write-Host "Erreur : Impossible de desactiver IPv6. $_"
    Write-Host ""
    exit
}

# Supprimer toutes les configurations IP et passerelles existantes pour éviter les conflits
try {
    Get-NetIPAddress -InterfaceAlias $interfaceName | ForEach-Object { Remove-NetIPAddress -InterfaceAlias $interfaceName -IPAddress $_.IPAddress -Confirm:$false }
    Get-NetRoute -InterfaceAlias $interfaceName | Remove-NetRoute -Confirm:$false
} catch {
    Write-Host ""
    Write-Host "Erreur : Impossible de supprimer les configurations IP ou les routes existantes. $_"
    Write-Host ""
    exit
}

# Configurer IPv4 avec une adresse IP statique et des paramètres de serveur DNS
try {
    New-NetIPAddress -InterfaceAlias $interfaceName -IPAddress $ipAddress -PrefixLength $subnetMask -DefaultGateway $gateway
    Set-DnsClientServerAddress -InterfaceAlias $interfaceName -ServerAddresses ($dnsPrimary, $dnsSecondary).Where({$_})
    Write-Host ""
    Write-Host "Configuration IP et DNS OK. Adresse IP: $ipAddress"
    Write-Host ""
} catch {
    Write-Host ""
    Write-Host "Erreur : Impossible de configurer l'adresse IP ou les serveurs DNS. $_"
    Write-Host ""
    exit
}

# Redémarrer l'adaptateur pour appliquer les changements
try {
    Restart-NetAdapter -Name $interfaceName
    Start-Sleep -Seconds 5
} catch {
    Write-Host ""
    Write-Host "Erreur : Impossible de redemarrer l'adaptateur reseau. $_"
    Write-Host ""
    exit
}

# Ajouter un profil WiFi sans mot de passe
try {
    $profileXml = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
    <name>$wifiName</name>
    <SSIDConfig>
        <SSID>
            <name>$wifiName</name>
        </SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>auto</connectionMode>
    <MSM>
        <security>
            <authEncryption>
                <authentication>open</authentication>
                <encryption>none</encryption>
                <useOneX>false</useOneX>
            </authEncryption>
        </security>
    </MSM>
</WLANProfile>
"@

    $profilePath = [System.IO.Path]::Combine($env:TEMP, "$wifiName.xml")
    [System.IO.File]::WriteAllText($profilePath, $profileXml)
    netsh wlan add profile filename="$profilePath"
} catch {
    Write-Host ""
    Write-Host "Erreur : Impossible d'ajouter le profil WiFi. $_"
    Write-Host ""
    exit
}

# Vérifier si le réseau WiFi est disponible
try {
    $availableNetworks = netsh wlan show networks interface="$interfaceName" | Select-String -Pattern $wifiName
    if (-not $availableNetworks) {
        Write-Host ""
        Write-Host "Erreur : Wi-Fi $wifiName n'existe pas ou n'est pas disponible."
        Write-Host ""
        exit
    }
} catch {
    Write-Host ""
    Write-Host "Erreur : Impossible de tester la disponibilite du WiFi. $_"
    Write-Host ""
    exit
}

# Tentative de connexion au réseau WiFi 
try {
    Write-Host ""
    Write-Host "Connexion $wifiName en cours" -NoNewline
    $cmd = "netsh wlan connect name=`"$wifiName`" interface=`"$interfaceName`""
    $job = Start-Job -ScriptBlock { Invoke-Expression $using:cmd }

    # Animation de connexion en cours
    while ($job.State -eq 'Running') {
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 1
    }
    Remove-Job $job
} catch {
    Write-Host ""
    Write-Host "Erreur : Impossible de se connecter au WiFi. $_"
    Write-Host ""
    exit
}

# Vérifier le résultat de la connexion
try {
    $connected = netsh wlan show interfaces | Select-String -Pattern $wifiName
    if ($connected) {
        Write-Host ""
        Write-Host "Connexion $wifiName OK."
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "Erreur : Connexion $wifiName impossible."
        Write-Host ""
    }
} catch {
    Write-Host ""
    Write-Host "Erreur : Impossible de tester la connexion. $_"
    Write-Host ""
}

# Nettoyer le fichier de profil WiFi
Remove-Item $profilePath
