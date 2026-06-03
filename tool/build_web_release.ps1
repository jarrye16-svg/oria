cd $PSScriptRoot\..

flutter clean
flutter pub get
flutter analyze

flutter build web --release `
  --dart-define=SUPABASE_URL="https://hrfsphtwslcjnpvcwdxl.supabase.co" `
  --dart-define=SUPABASE_ANON_KEY="sb_publishable__C7YM-EoJQgqdduVFb0WTQ_53AXMEgp"

Write-Host ""
Write-Host "Build gerado em: build\web"
Write-Host "Para testar local, rode:"
Write-Host "flutter run -d web-server --release --web-hostname=0.0.0.0 --web-port=5051 --dart-define=SUPABASE_URL='https://hrfsphtwslcjnpvcwdxl.supabase.co' --dart-define=SUPABASE_ANON_KEY='sb_publishable__C7YM-EoJQgqdduVFb0WTQ_53AXMEgp'"
