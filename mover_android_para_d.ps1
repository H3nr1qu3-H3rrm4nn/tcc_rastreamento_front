# ================================================
# Script: mover_android_para_d.ps1
# Função: Move o Android SDK e as pastas dos AVDs (emuladores)
# Autor: ChatGPT
# ================================================

$origemSDK = "$env:LOCALAPPDATA\Android\Sdk"
$destinoSDK = "D:\Android\Sdk"

$origemAVD = "$env:USERPROFILE\.android\avd"
$destinoAVD = "D:\AndroidAVD"

# Cria as pastas de destino se não existirem
if (-not (Test-Path "D:\Android")) {
    New-Item -Path "D:\" -Name "Android" -ItemType "directory"
}
if (-not (Test-Path "D:\AndroidAVD")) {
    New-Item -Path "D:\" -Name "AndroidAVD" -ItemType "directory"
}

Write-Host "Copiando SDK de:`n$origemSDK`npara:`n$destinoSDK`n"
Copy-Item -Path $origemSDK -Destination $destinoSDK -Recurse -Force

Write-Host "Copiando AVDs de:`n$origemAVD`npara:`n$destinoAVD`n"
Copy-Item -Path $origemAVD -Destination $destinoAVD -Recurse -Force

Write-Host "Removendo pastas antigas e criando links simbólicos..."
Remove-Item -Path $origemSDK -Recurse -Force
Remove-Item -Path $origemAVD -Recurse -Force

cmd /c mklink /D "$origemSDK" "$destinoSDK"
cmd /c mklink /D "$origemAVD" "$destinoAVD"

# Atualiza variáveis de ambiente
[System.Environment]::SetEnvironmentVariable('ANDROID_HOME', $destinoSDK, [System.EnvironmentVariableTarget]::User)
[System.Environment]::SetEnvironmentVariable('ANDROID_SDK_ROOT', $destinoSDK, [System.EnvironmentVariableTarget]::User)

Write-Host "`n✅ SDK e AVDs movidos com sucesso para o disco D:"
Write-Host "   Novo SDK: $destinoSDK"
Write-Host "   Novos AVDs: $destinoAVD"

Write-Host "`n🔄 Reinicie o Visual Studio Code e o Android Studio."
Write-Host "   Depois, execute 'flutter doctor' novamente para verificar."
