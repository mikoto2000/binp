# encoding: UTF-8
require 'formatador'
require 'json'
require 'optparse'
require 'yaml'

require_relative '../../binp.rb'

class Main
  def self.run(argv)
    # 引数パース
    opts, argv = parse_option(argv)

    # ファイル読み込み
    config = read_config_file(opts[:config])
    uint8_array = read_binary_file(argv[0])

    # バイナリパース
    raw_result = BinParser.parse(uint8_array, config)

    # 出力用に加工して出力
    result = raw_result.map { |e|
      e['type'] = e['type'][:name]

      # FLAGS では endianness が無い場合があるのでチェックしてから設定
      if e['endianness']
        e['endianness'] = e['endianness'][:name]
      end

      # layout は出力量が多すぎるので削除
      e.delete('layout')
      e
    }
    if  !opts[:all]
        result.map! { |e| { 'name' => e['name'], 'value' => e['value']} }
    end
    Formatador.display_compact_table(result)
  end

  def self.parse_option(argv)
    options = {
        all: false
    }
    op = OptionParser.new
    op.banner = 'Usage: binp [options] FILE'

    op.on('-c VALUE', '--config VALUE', '設定ファイルパス') { |v| options[:config] = v }
    op.on('-a', '--all', 'name, value 以外のすべての項目(endianness, offset, size, type)を表示する') { |v| options[:all] = true }
    begin
      op.parse!(argv)
    rescue OptionParser::InvalidOption => e
      STDERR.puts 'ERROR: オプションのパースに失敗しました。'
      STDERR.puts op.to_s
      exit(1);
    end

    # 必須オプション `-c` のチェック
    unless options[:config]
      STDERR.puts 'ERROR: 必須オプション `-c, --config` が指定されていません。'
      STDERR.puts op.to_s
      exit(1);
    end

    # ファイル指定があるかのチェック
    if argv.size == 0
      STDERR.puts 'ERROR: FILE が指定されていません。'
      STDERR.puts op.to_s
      exit(1);
    end

    [options, argv]
  end

  def self.read_config_file(config_file_path)
    config = File.open(config_file_path, 'rb') { |f|
      YAML.load_file(f)
    }
    config.each_with_index { |e, i|
      type = BinParserElement::Type.constants.find { |type|
        BinParserElement::Type.const_get(type)[:name] == e['type']
      }

      # YAML 記載の type に対応した Type オブジェクトに差し替える
      if type
        e['type'] = BinParserElement::Type.const_get(type)
      else
        STDERR.puts "#{i} 番目の type の値が不正です('#{e['type']}')。UINT8, UINT16, UINT32, UINT64, INT8, INT16, INT32 or INT64."
        exit(1)
      end

      endianness = BinParserElement::Endianness.constants.find { |endianness|
        BinParserElement::Endianness.const_get(endianness)[:name] == e['endianness']
      }

      # YAML 記載の endianness に対応した Endianness オブジェクトに差し替える
      if e['type'] != BinParserElement::Type::FLAGS
        if endianness
          e['endianness'] = BinParserElement::Endianness.const_get(endianness)
        else
          STDERR.puts "#{i} 番目の endianness の値が不正です('#{e['endianness']}')。LITTLE or BIG を指定してください。"
          exit(1)
        end
      end
    }

    config
  end

  def self.read_binary_file(binary_file_path)
    File.open(binary_file_path, 'rb') { |f|
      f.each_byte.to_a
    }
  end
end

