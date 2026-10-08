# Lance Godot sur le projet, capture la sortie et tue le processus s'il dépasse le délai.
# Exemples :
#   .\game\tools\godot.ps1 -Tests
#   .\game\tools\godot.ps1 -GodotArgs '--', '--shot=C:\tmp\shot.png'
param(
	[string[]] $GodotArgs = @(),
	[switch] $Tests,
	[switch] $Headless,
	[int] $TimeoutSeconds = 60,
	[string] $Godot = $env:GODOT
)

if (-not $Godot) {
	$Godot = 'D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe'
}
if (-not (Test-Path $Godot)) {
	Write-Error "Godot introuvable : $Godot. Renseigner la variable d'environnement GODOT."
	exit 2
}

$project = Split-Path -Parent $PSScriptRoot
$allArgs = @('--path', "`"$project`"")
if ($Tests) { $allArgs += @('--headless', '--script', 'res://tests/run_tests.gd') }
elseif ($Headless) { $allArgs += '--headless' }
$allArgs += $GodotArgs

$out = [System.IO.Path]::GetTempFileName()
$err = [System.IO.Path]::GetTempFileName()
$process = Start-Process -FilePath $Godot -ArgumentList $allArgs -PassThru -NoNewWindow `
	-RedirectStandardOutput $out -RedirectStandardError $err
# Sans cet accès, PowerShell ne conserve pas le code de sortie d'un processus lancé avec -PassThru.
$null = $process.Handle
if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
	$process.Kill()
	Get-Content $out -Encoding UTF8
	Get-Content $err -Encoding UTF8
	Write-Output "DELAI DEPASSE ($TimeoutSeconds s) : processus arrêté."
	exit 3
}
$process.WaitForExit()
Get-Content $out -Encoding UTF8
$errors = Get-Content $err -Encoding UTF8
if ($errors) { Write-Output '--- stderr'; $errors }
Remove-Item $out, $err -ErrorAction SilentlyContinue
exit $process.ExitCode
