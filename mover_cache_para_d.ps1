# =============================================
# Script: mover_cache_para_d.ps1
# Objetivo: Mover cache do Gradle, Flutter e temp p/ D:
# =============================================

# Definições das pastas de origem e destino
$usuario = $env:trabalho
$origemGradle = "$env:USERPROFILE\.gradle"
$destinoGradle = "D:\GradleCache"
$origemPub = "$env:LOCALAPPDATA\Pub"
$destinoPub = "D:\FlutterCache\Pub"
$origemFlutter = "$env:LOCALAPPDATA\Flutter"
$destinoFlutter = "D:\FlutterCache\Flutter"
$destinoTemp = "D:\TempAndroid"

function MoverEPonto {
    param (
        [string]$origem,
        [string]$destino
    )

    # Se a pasta de destino não existir, cria
    if (-not (Test-Path $destino)) {
        New-Item -ItemType Directory -Path $destino -Force
    }

    # Copia a pasta, se existir origem
    if (Test-Path $origem) {
        Write-Host "Copiando $origem para $destino ..."
        Copy-Item -Path $origem -Destination $destino -Recurse -Force

        # Remove a pasta antiga
        Write-Host "Removendo pasta antiga $origem ..."
        Remove-Item -Path $origem -Recurse -Force
    }
    else {
        Write-Host "Origem $origem não encontrada, pulando..."
    }
    
    # Cria link simbólico
    Write-Host "Criando link simbólico para $origem apontando para $destino ..."
    cmd /c mklink /D "$origem" "$destino"
}

# Executa movimentações
MoverEPonto -origem $origemGradle -destino $destinoGradle
MoverEPonto -origem $origemPub -destino $destinoPub
MoverEPonto -origem $origemFlutter -destino $destinoFlutter

# Configura a variável TEMP e TMP para apontar para D:\TempAndroid
if (-not (Test-Path $destinoTemp)) {
    New-Item -ItemType Directory -Path $destinoTemp -Force
}

Write-Host "Configurando variáveis TEMP e TMP para $destinoTemp ..."
setx TEMP $destinoTemp
setx TMP $destinoTemp

Write-Host "`n✅ Processo concluído! Reinicie o terminal, VS Code e Android Studio para aplicar as mudanças."
Write-Host "Use agora 'flutter doctor' para confirmar que está tudo ok."