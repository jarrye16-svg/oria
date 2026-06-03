cd $PSScriptRoot\..

Write-Host "== Flutter analyze =="
flutter analyze

Write-Host ""
Write-Host "== Procurando possiveis segredos no projeto =="
$patterns = @(
  "service_role",
  "sb_secret",
  "SUPABASE_SERVICE_ROLE",
  "postgres://",
  "password=",
  "JWT_SECRET"
)

foreach ($p in $patterns) {
  Write-Host ""
  Write-Host "Pattern: $p"
  Get-ChildItem -Recurse -File |
    Where-Object {
      $_.FullName -notmatch "\\build\\" -and
      $_.FullName -notmatch "\\.dart_tool\\" -and
      $_.FullName -notmatch "\\.git\\"
    } |
    Select-String -Pattern $p -SimpleMatch -ErrorAction SilentlyContinue |
    Select-Object Path, LineNumber, Line
}

Write-Host ""
Write-Host "Se aparecer service_role, sb_secret ou senha real em arquivo commitado, NAO suba para o GitHub."
