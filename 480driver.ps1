Import-Module '/home/liam/SYS480/Modules/480-utils.psm1'
$Path = '/home/liam/SYS480/480.json'
$global:config = Get-Content -Raw -Path $Path | ConvertFrom-json
ConnectTovCenter