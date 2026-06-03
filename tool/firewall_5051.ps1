# Execute como Administrador
New-NetFirewallRule -DisplayName "Oria Flutter Web 5051" -Direction Inbound -Protocol TCP -LocalPort 5051 -Action Allow -ErrorAction SilentlyContinue
Write-Host "Regra de firewall criada/liberada para porta 5051."
