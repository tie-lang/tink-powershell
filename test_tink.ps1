# test_tink.ps1 —— unit tests for tink.ps1. Run: pwsh -File test_tink.ps1
. $PSScriptRoot/tink.ps1

$failures = 0
function Check([bool]$Cond, [string]$Name) {
    if ($Cond) { Write-Host "[PASS] $Name" }
    else { $script:failures++; Write-Host "[FAIL] $Name" }
}

# crc32 check vector (0xCBF43926 = 3421780262 decimal)
Check ((Tink-Crc32 -Data ([Text.Encoding]::UTF8.GetBytes("123456789"))) -eq 3421780262) "crc32 vector"

# frame roundtrip
$p = [byte[]](1, 2, 3)
$frame = Tink-FrameEncode -Payload $p
Check ($frame.Length -eq ($p.Length + 8)) "frame length"
$got = Tink-FrameNext -Bytes $frame -Pos 0
Check ($null -ne $got) "frame present"
if ($null -ne $got) {
    Check ($got.Next -eq $frame.Length) "frame next == length"
    Check (($got.Payload -join ',') -eq ($p -join ',')) "frame payload roundtrip"
}

# empty frame roundtrip
$fe = Tink-FrameEncode -Payload ([byte[]]@())
$ge = Tink-FrameNext -Bytes $fe -Pos 0
Check (($null -ne $ge) -and ($ge.Next -eq $fe.Length) -and ($ge.Payload.Length -eq 0)) "empty frame roundtrip"

# CRC tamper rejected
$ft = Tink-FrameEncode -Payload $p
$ft[4] = $ft[4] + 1  # tamper payload[0]
Check ($null -eq (Tink-FrameNext -Bytes $ft -Pos 0)) "crc tamper rejected"

# frameSkip matches length
$fs = Tink-FrameEncode -Payload $p
Check ((Tink-FrameSkip -Bytes $fs -Pos 0) -eq $fs.Length) "frameSkip matches length"

# out of bounds
Check ($null -eq (Tink-FrameNext -Bytes $frame -Pos $frame.Length)) "frameNext out of bounds"
Check ($null -eq (Tink-FrameSkip -Bytes $frame -Pos $frame.Length)) "frameSkip out of bounds"
Check ($null -eq (Tink-FrameNext -Bytes ([byte[]]@()) -Pos 0)) "frameNext empty input"

if ($failures -gt 0) {
    Write-Host "$failures checks FAILED"
    exit 1
}
Write-Host "all tests passed"