
# Scripts de configuration réseau pour la RoboCup

Ce projet regroupe les scripts PowerShell et leurs exécutables associés pour automatiser la configuration des paramètres réseau des robots du Robot Club Toulon, simplifiant leur connexion aux "Base Stations" de la RoboCup. 

Les scripts configurent une adresse IP statique, désactivent IPv6 et se connectent à un réseau Wi-Fi spécifique selon le terrain de jeu (A_a, B_a et B_b). Les scripts pour restaurer les paramètres réseau par défaut sont également inclus.

## Contenu des dossiers

Les deux dossiers présents contiennent les scripts et les exécutables fonctionnels :

- *RoboCup2024* : scripts utilisés durant la compétition et actuellement déployés sur les robots.
- *Univ* : scripts utilisés sur le terrain de test de l'université, avec le réseau du routeur de l'équipe.

Des scripts génériques servant de templates sont également fournis. Téléchargez et modifiez ces fichiers avec vos configurations réseau spécifiques si nécessaire.

## Scripts et exécutables

- `config_field.ps1` / `config_field.exe` : Configure les paramètres réseau pour la Base Station et se connecte au réseau Wi-Fi correspond au terrain choisi.
- `restore.ps1` / `restore.exe` : Restaure les paramètres réseau par défaut (DHCP et IPV6), se déconnecte de la Base Station et se connecte à un réseau Wi-Fi fournissant Internet.

## Utilisation

### Configuration réseau

Pour configurer les paramètres réseau, il y a deux méthodes : 
1. Exécuter les scripts depuis un terminal PowerShell en mode administrateur en vous plaçant dans le bon répertoire et en utilisant la commande `.\config_field.ps1`.
2. Ouvrir l'exécutable `config_field.exe` en tant qu'administrateur en double-cliquant dessus depuis son emplacement.
   
Puis suivez les instructions pour choisir le robot à configurer.

### Restauration des paramètres réseau

Pour restaurer les paramètres réseau par défaut, le fonctionnement est identique, exécutez `.\restore.ps1` ou `restore.exe` en tant qu'administrateur.

## Création des exécutables

Convertir les scripts PowerShell en exécutables élimine la nécessité de passer par un terminal PowerShell. Pour cela, utilisez le module PS2EXE.

### Installation

Installez PS2EXE à l'aide de la commande suivante dans PowerShell :

```powershell
Install-Module -Name PS2EXE -Scope CurrentUser
```

### Conversion des scripts

Placez-vous dans le bon répertoire puis utilisez la commande `Invoke-PS2EXE` pour convertir un script PowerShell en exécutable :

```powershell
Invoke-PS2EXE .\script.ps1 .\script.exe
```

## Exécution avec les droits d'administrateur

Les exécutables nécessitent des droits administratifs pour modifier les configurations réseau. Pour cela, modifiez leurs propriétés pour qu'ils s'exécutent automatiquement en tant qu'administrateur :

1. Clic droit sur l'exécutable > Propriétés > Compatibilité > Cocher "Exécuter ce programme en tant qu'administrateur".
2. Une fenêtre d'alerte s'ouvrira lors de l'exécution. Pour éviter cela, ajustez les réglages de l'UAC pour diminuer la fréquence d'alertes de Windows à "Ne jamais m'avertir".
   
<div align="center">
   <img src="https://github.com/user-attachments/assets/fe8521ef-b7d5-4013-a71b-90f2dec91464" alt="Exécuter en tant qu'administrateur" width="318">
   <img src="https://github.com/user-attachments/assets/9628c73a-cd49-4b41-ab9f-7575b27ec012" alt="Réglages UAC" width="500">
</div>

## Notes

Tous les scripts inclus dans ce projet ont été testés et validés sur les robots en conditions de match.

Les seules modifications nécessaires sont :
- Pour les prochaines compétitions, modifier les paramètres réseau selon les configurations futures.
- Renseigner le mot de passe du Wi-Fi du routeur pour le terrain de l'université dans le script `config_A_a_univ.ps1`. Ce mot de passe est intégré dans l'exécutable mais n'est pas publié ici pour des raisons de sécurité.

Si vous rencontrez des erreurs, exécutez plusieurs fois le script de restauration de la configuration réseau. Si les problèmes persistent, contactez-moi.
