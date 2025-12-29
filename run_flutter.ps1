param(
  [Parameter(ValueFromRemainingArguments=$true)]
  [string[]]$FlutterArgs
)

$flutterBat = "C:\Windows\flutter\bin\flutter.bat"
$gitCmd     = "C:\Program Files\Git\cmd"
$sys32      = "$env:WINDIR\System32"

# PATH mínimo y limpio
$cleanPath  = "$sys32;$gitCmd;C:\Windows\flutter\bin"

# args en una sola línea (con comillas seguras)
$argLine = ($FlutterArgs | ForEach-Object {
  if ($_ -match '\s') { '"' + ($_ -replace '"','\"') + '"' } else { $_ }
}) -join ' '

$cmd = "$env:WINDIR\System32\cmd.exe"

# /d evita AutoRun del registro (muchas veces ahí se rompe todo)
& $cmd /d /c "set PATH=$cleanPath&& `"$flutterBat`" $argLine"
