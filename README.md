# tink-powershell

tink data-flow node frame protocol — `tsh` shell script module (tie shell
role, host `tshell`; `type tie<tsh>`, extension `.tsh.tie`; no dependencies).
Universal and language-agnostic: any component that obeys the frame protocol
can join a tink pipeline.

```
帧 = [ len: u32 BE ][ payload: len 字节 ][ crc: u32 BE ]
len = payload 字节数
crc = CRC32-IEEE(payload)（多项式 0xEDB88320）
```

Mirrors `std/tink.tie` (tie standard library) and the other-language tink
libraries. Pure functions over byte tables (`table<i64>`), IO (stdin/stdout)
left to the caller. Ported from the original `tink.ps1` (PowerShell) to the
`tsh` role: `t_crc32` / `t_crc` / `t_frame_encode` / `t_read_be32` are
single-line recursion functions (tsh single-line functions cannot contain
loops); frame parse/skip is multi-guard procedural logic demonstrated by the
test script.

## API

| function | description |
| --- | --- |
| `t_crc(p: table<i64>) -> i64` | CRC32-IEEE over a byte table. Check vector: `t_crc("123456789") = 3421780262` (0xCBF43926) |
| `t_frame_encode(p: table<i64>) -> table<i64>` | encode a payload into a full frame `[len][payload][crc]` |
| `t_read_be32(b: table<i64>, off: i64) -> i64` | read a big-endian u32 (e.g. the `len` field) |

## Usage

```sh
# tsh script (run by tshell / tsh_main.exe -f)
var frame = t_frame_encode(pay)
```

## Test

```bash
tsh_main.exe -f test_tink.tsh.tie
# or: tshell -f test_tink.tsh.tie   （输出与 test_tink.ps1 对齐：逐项 [PASS]/[FAIL] + all tests passed）
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
| PowerShell | `tink-powershell`（原 `tink.ps1`，已移植为 `tsh` 角色 `.tsh.tie`） |

## License

本仓库使用 **Tie Public License v2.0 (TPL 2.0)**，完整文本见 [LICENSE](LICENSE)。
This repository is distributed under the **Tie Public License v2.0 (TPL 2.0)** — see [LICENSE](LICENSE) for the full text.