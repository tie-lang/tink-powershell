# tink-powershell

tink data-flow node frame protocol — PowerShell script module (no
dependencies). Universal and language-agnostic: any component that obeys the
frame protocol can join a tink pipeline.

```
帧 = [ len: u32 BE ][ payload: len 字节 ][ crc: u32 BE ]
len = payload 字节数
crc = CRC32-IEEE(payload)（多项式 0xEDB88320）
```

Mirrors `std/tink.tie` (tie standard library) and the other-language tink
libraries; pure functions over `[byte[]]`, IO (stdin/stdout) left to the
caller. Function names follow the PowerShell convention (Verb-Noun:
`Tink-Crc32`, `Tink-FrameEncode`, `Tink-FrameNext`, `Tink-FrameSkip`).

## API

| function | description |
| --- | --- |
| `Tink-Crc32 -Data [byte[]] -> [uint32]` | CRC32-IEEE over a byte array. Check vector: `Tink-Crc32 "123456789" = 0xCBF43926` |
| `Tink-FrameEncode -Payload [byte[]] -> [byte[]]` | encode a payload into a full frame `[len][payload][crc]` |
| `Tink-FrameNext -Bytes [byte[]] -Pos int -> object \| $null` | parse one frame at `pos`, verify CRC; `{Payload, Next}` object on success, `$null` on out-of-bounds / mismatch |
| `Tink-FrameSkip -Bytes [byte[]] -Pos int -> int \| $null` | skip one frame at `pos` without copying or verifying; `$null` on out-of-bounds |

## Usage

```powershell
. ./tink.ps1
$frame = Tink-FrameEncode -Payload ([byte[]](1, 2, 3))
$got = Tink-FrameNext -Bytes $frame -Pos 0   # { Payload=...; Next=... } or $null
```

## Test

```bash
pwsh -File test_tink.ps1
```

## Cross-language

tink 帧协议各语言实现（API 语义与校验向量一致）：

| language | library |
| --- | --- |
| tie | `std/tink.tie` |
| Rust | `tink-rust`（tink crate） |
| C | `tink-c`（`tink.h` + `tink.c`） |
| Python | `tink-python`（`tink.py`） |
| JavaScript | `tink-js`（`tink.js` + `tink.d.ts`） |
| C++ | `tink-cpp`（`tink.hpp`） |
| Java | `tink-java`（`org.tielang.tink`） |
| C# | `tink-csharp`（namespace `Tink`） |
| Go | `tink-go`（package `tink`） |
| Zig | `tink-zig`（`tink.zig`） |
| Lua | `tink-lua`（`tink.lua`） |
| GDScript | `tink-godot`（`tink.gd`） |
| F# | `tink-fsharp`（`Tink.fs`） |
| PowerShell | this module（`tink-powershell`） |

## License

本仓库使用 **Tie Public License v1.2 (TPL 1.2)**，完整文本见 [LICENSE](LICENSE)。
This repository is distributed under the **Tie Public License v1.2 (TPL 1.2)** — see [LICENSE](LICENSE) for the full text.