@'
@echo off
set "PATH=C:\Windows\System32;C:\Windows\System32\WindowsPowerShell\v1.0;C:\Program Files\Git\cmd;C:\Windows\flutter\bin\cache\dart-sdk\bin;%PATH%"
call "%LOCALAPPDATA%\Pub\Cache\bin\fvm.bat" flutter %*
'@ | Set-Content -Encoding ASCII ".\run_fvm.cmd"
