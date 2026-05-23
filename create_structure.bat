@echo off
REM Create directory structure for Flutter project

mkdir lib\app 2>nul
mkdir lib\core\constants 2>nul
mkdir lib\core\enums 2>nul
mkdir lib\core\errors 2>nul
mkdir lib\core\services 2>nul
mkdir lib\core\utils 2>nul
mkdir lib\core\extensions 2>nul
mkdir lib\data\models 2>nul
mkdir lib\data\repositories 2>nul
mkdir lib\data\datasources 2>nul
mkdir lib\data\firebase 2>nul
mkdir lib\features\auth\screens 2>nul
mkdir lib\features\auth\widgets 2>nul
mkdir lib\features\auth\providers 2>nul
mkdir lib\features\auth\services 2>nul
mkdir lib\features\dashboard 2>nul
mkdir lib\features\labour 2>nul
mkdir lib\features\attendance 2>nul
mkdir lib\features\advances 2>nul
mkdir lib\features\expenses 2>nul
mkdir lib\features\invoices 2>nul
mkdir lib\features\payments 2>nul
mkdir lib\features\reports 2>nul
mkdir lib\features\sites 2>nul
mkdir lib\features\settings 2>nul
mkdir lib\shared\widgets 2>nul
mkdir lib\shared\dialogs 2>nul
mkdir lib\shared\forms 2>nul
mkdir lib\shared\layouts 2>nul

echo Folder structure created successfully!
