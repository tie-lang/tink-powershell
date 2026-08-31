# tink.ps1 —— tink data-flow node frame protocol (universal, language-agnostic).
#
# Frame = [len u32 BE][payload][crc u32 BE]; crc = CRC32-IEEE (0xEDB88320).
# Mirrors std/tink.tie (tie standard library) and the other-language tink
# libraries; pure functions over [byte[]], IO (stdin/stdout) left to the
# caller. PowerShell, no external dependencies.
#
#   $frame = @([byte]1,2,3) | ConvertFrom-TinkPayload
#   ---
#   $f = Tink-FrameEncode ([byte[]](1,2,3))
#   $got = Tink-FrameNext $f 0   # [pscustomobject]@{ Payload=...; Next=... } or $null

<#
.SYNOPSIS
CRC32-IEEE over a byte array. Check vector: (Tink-Crc32 ([Text.Encoding]::UTF8.GetBytes("123456789"))) -eq 0xCBF43926
#>
function Tink-Crc32 {
    param([byte[]]$Data)
    # NOTE: PowerShell 里 0xFFFFFFFF 十六进制字面量按 Int32 溢出回绕为 -1，
    # 这里统一用十进制 Int64 常量保证 32 位无符号语义。
    # 0xEDB88320 = 3988292384（CRC32-IEEE 反射多项式）。
    $crc = [int64]4294967295
    foreach ($b in $Data) {
        $crc = $crc -bxor [int64]$b
        for ($k = 0; $k -lt 8; $k++) {
            if (($crc -band [int64]1) -ne 0) { $crc = ($crc -shr 1) -bxor [int64]3988292384 }
            else { $crc = $crc -shr 1 }
        }
    }
    [uint32]($crc -bxor [int64]4294967295)
}

<#
.SYNOPSIS
Encode a payload into a full frame: [len u32 BE][payload][crc u32 BE].
#>
function Tink-FrameEncode {
    param([byte[]]$Payload)
    $n = $Payload.Length
    $out = New-Object byte[] ($n + 8)
    $out[0] = [byte](($n -shr 24) -band 0xFF)
    $out[1] = [byte](($n -shr 16) -band 0xFF)
    $out[2] = [byte](($n -shr 8) -band 0xFF)
    $out[3] = [byte]($n -band 0xFF)
    [Array]::Copy($Payload, 0, $out, 4, $n)
    $c = [int64](Tink-Crc32 -Data $Payload)
    $out[$n + 4] = [byte](($c -shr 24) -band 0xFF)
    $out[$n + 5] = [byte](($c -shr 16) -band 0xFF)
    $out[$n + 6] = [byte](($c -shr 8) -band 0xFF)
    $out[$n + 7] = [byte]($c -band 0xFF)
    , $out
}

<#
.SYNOPSIS
Parse one frame at pos (verifies CRC). Returns [pscustomobject]@{Payload; Next}
or $null on out-of-bounds / CRC mismatch.
#>
function Tink-FrameNext {
    param([byte[]]$Bytes, [int]$Pos)
    if ($Pos -lt 0 -or $Bytes.Length -lt ($Pos + 8)) { return $null }
    $n = Read-TinkBe32 $Bytes $Pos
    $e = $Pos + 8 + $n
    if ($Bytes.Length -lt $e) { return $null }
    $payload = New-Object byte[] $n
    [Array]::Copy($Bytes, $Pos + 4, $payload, 0, $n)
    $want = Read-TinkBe32 $Bytes ($e - 4)
    if ((Tink-Crc32 -Data $payload) -ne $want) { return $null }
    [pscustomobject]@{ Payload = $payload; Next = $e }
}

<#
.SYNOPSIS
Skip one frame at pos without copying or verifying (zero-copy).
Returns the position after the frame, or $null on out-of-bounds.
#>
function Tink-FrameSkip {
    param([byte[]]$Bytes, [int]$Pos)
    if ($Pos -lt 0 -or $Bytes.Length -lt ($Pos + 8)) { return $null }
    $n = Read-TinkBe32 $Bytes $Pos
    $e = $Pos + 8 + $n
    if ($Bytes.Length -lt $e) { return $null }
    $e
}

function Read-TinkBe32 {
    param([byte[]]$B, [int]$Off)
    (( [int64]$B[$Off] -band 0xFF) -shl 24) -bor (( [int64]$B[$Off + 1] -band 0xFF) -shl 16) -bor (( [int64]$B[$Off + 2] -band 0xFF) -shl 8) -bor ([int64]$B[$Off + 3] -band 0xFF)
}