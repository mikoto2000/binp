# encoding: UTF-8
require 'formatador'
require 'json'
require 'listen'
require 'optparse'
require 'pathname'
require 'yaml'

require_relative '../../binp.rb'

class Main
  def self.run(argv)
    # 引数パース
    opts, argv = parse_option(argv)

    # コンフィグファイル読み込み
    config = read_config_file(opts[:config])

    # watch オプションを確認し、フラグがたっていれば watch モードで実行
    if opts[:watch]
      watch(config, opts[:all], argv[0])
    else
      display(config, opts[:all], argv[0], false)
    end
  end

  def self.parse_option(argv)
    options = {
        all: false,
        watch: false
    }
    op = OptionParser.new
    op.banner = 'Usage: binp [options] FILE'

    op.on('-c VALUE', '--config VALUE', '設定ファイルパス') { |v| options[:config] = v }
    op.on('-a', '--all', 'name, value 以外のすべての項目(endianness, offset, size, type)を表示する') { |v| options[:all] = true }
    op.on('-w', '--watch', 'ファイル更新時に再表示します') { |v| options[:watch] = true }
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

  # watch モード(指定されたファイルが更新されるたびに結果を出力する)
  def self.watch(config, is_all, file)
    # 初回の出力
    display(config, is_all, file, true)
    
    # ファイルの変更を監視し、変更があればターミナルに出力
    directory = Pathname.new(file).dirname.to_s
    listener = Listen.to(directory) do |modified, _added, _removed|
      modified_file = Pathname.new(modified.first).expand_path

      # 変更されたファイルが監視対象でなければ何もしない
      next unless modified_file == Pathname.new(file).expand_path

      # 出力
      display(config, is_all, modified_file, true)
    end

    listener.start
    begin
      sleep
    rescue Interrupt
      # do nothing
    end
  end

  # バイナリファイルをパースして、出力用にフォーマットする
  def self.parse_and_format(config, is_all, file)
    uint8_array = read_binary_file(file);

    # バイナリパース
    raw_result = BinParser.parse(uint8_array, config)

    # パース結果を出力用に加工
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

    # all フラグが立っていない場合、 name と value のみ抽出
    if !is_all
        result.map! { |e| { 'name' => e['name'], 'value' => e['value']} }
    end

    result
  end

  def self.display(config, is_all, file, is_reset)
    # 表示用文字列を取得
    result = parse_and_format(config, is_all, file)

    # 一度ターミナルをリセットして表示し直す
    printf "\033c" if is_reset
    Formatador.display_compact_table(result)
  end
end

