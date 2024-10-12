@echo off
:: Vérifier les privilèges d'administrateur
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Ce script nécessite des privilèges d'administrateur.
    echo Veuillez l'exécuter en tant qu'administrateur.
    pause
    exit /b 1
)

:: Définir le chemin du fichier hosts et la nouvelle entrée
set "hostsFile=%windir%\System32\drivers\etc\hosts"
set "newEntry=140.82.121.3 github.com"

:: Vérifier si l'entrée existe déjà
findstr /c:"%newEntry%" "%hostsFile%" >nul
if %errorlevel% equ 0 (
    echo L'entrée existe déjà dans le fichier hosts.
) else (
    :: Ajouter la nouvelle entrée
    echo.>>"%hostsFile%"
    echo %newEntry%>>"%hostsFile%"
    echo L'entrée a été ajoutée avec succès au fichier hosts.
)

:: Afficher le contenu mis à jour du fichier hosts
type "%hostsFile%"

pause