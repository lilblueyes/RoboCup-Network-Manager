$interfaceName = "Wi-Fi"
$wifiName = "NOM_DU_RESEAU_WIFI_AVEC_INTERNET" # Réseau auquel le robot se reconnectera par défaut
# Si le réseau wifi nécessite un mot de passe, reprendre la logique du script ./Univ/config_A_a_univ.ps1

# Déconnecter le réseau WiFi actuel
try {
    $cmdDisconnect = "netsh wlan disconnect interface=`"$interfaceName`""
    Invoke-Expression $cmdDisconnect
} catch {
    Write-Host ""
    Write-Host "Erreur : Impossible de se deconnecter du reseau WiFi. $_"
    Write-Host ""
    exit
}

# Réactiver IPv6
try {
    Set-NetAdapterBinding -Name $interfaceName -ComponentID ms_tcpip6 -Enabled $True
    Write-Host ""
    Write-Host "Activation IPv6 OK"
} catch {
    Write-Host ""
    Write-Host "Erreur : Impossible d'activer IPv6. $_"
    Write-Host ""
    exit
}

# Configurer IPv4 pour obtenir une adresse IP automatiquement via DHCP
try {
    Set-NetIPInterface -InterfaceAlias $interfaceName -Dhcp Enabled
} catch {
    Write-Host ""
    Write-Host "Erreur : Impossible de configurer IPv4 pour DHCP. $_"
    Write-Host ""
    exit
}

# Effacer les adresses IP statiques configurées précédemment
try {
    Get-NetIPAddress -InterfaceAlias $interfaceName | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host ""
    Write-Host "Effacement des adresses IP statiques OK"
} catch {
    Write-Host ""
    Write-Host "Erreur : Impossible d'effacer les adresses IP statiques. $_"
    Write-Host ""
    exit
}

# Réinitialiser les serveurs DNS pour obtenir automatiquement via DHCP
try {
    Set-DnsClientServerAddress -InterfaceAlias $interfaceName -ResetServerAddresses
    Write-Host ""
    Write-Host "Initialisation des serveurs DNS OK"
    Write-Host ""
} catch {
    Write-Host ""
    Write-Host "Erreur : Impossible de reinitialiser les serveurs DNS. $_"
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
    } else {
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
