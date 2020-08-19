# Binp - Binary Parser

バイナリファイルからデータを抽出するツール。

`offset`, `size` `type`, `endianness` を指定して、バイナリファイルのどこからどこまでをどのように解釈するかを指定できる。


# 使い方

以下内容のバイナリファイルをパースする場合について説明する。

■ `example.bin`

```
+----+----+----+----+----+----+----+----+----+----+----+----+----+----+-------+
|  0 |  1 |  2 |  3 |  4 |  5 |  6 |  7 |  8 |  9 | 10 | 11 | 12 | 13 |    14 |
+----+----+----+----+----+----+----+----+----+----+----+----+----+----+-------+
| 00 | 00 | 00 | 00 | 00 | 00 | 00 | 01 | 00 | 00 | 00 | 01 | 00 | 01 |    01 |
+---------------------------------------+-------------------+---------+-------+
| UINT64                                | UINT32            |  UINT16 | UINT8 |
+---------------------------------------+-------------------+---------+-------+
※ エンディアンはリトルエンディアン
```

以下のように、設定ファイルに `name`, `offset`, `size`, `type` を記述する。

■ `setting.yaml`

```yaml
- name: UINT64_value
  offset: 0
  size: 8
  type: UINT64
  endianness: LITTLE
- name: UINT32_value
  offset: 8
  size: 4
  type: UINT32
  endianness: LITTLE
- name: UINT16_value
  offset: 2
  size: 2
  type: UINT16
  endianness: LITTLE
- name: UINT8_value
  offset: 14
  size: 1
  type: UINT8
  endianness: LITTLE
```

`binary_parser.rb` に設定ファイルとバイナリファイルを指定して実行する。

実行結果は以下のようになる。

json 形式で出力されるので、 `jq` 等でよしなに pretty-print してください。

```sh
$ ruby binary_parser.rb -c setting.yaml example.bin | jq '.'
[
  {
    "name": "UINT64_72057594037927936",
    "offset": 0,
    "size": 8,
    "type": "UINT64",
    "endianness": "LITTLE",
    "value": 72057594037927940
  },
...(snip)
  {
    "name": "UINT8_value",
    "offset": 14,
    "size": 1,
    "type": "UINT8",
    "endianness": "LITTLE",
    "value": 1
  }
]
```

# TODO:

- [x] : テーブル形式で表示
- [ ] : 文字列型サポート
    - [ ] : UTF8
- [ ] : ビットフラグサポート
- [ ] : type からの size 自動設定

