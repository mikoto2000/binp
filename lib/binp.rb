# encoding: UTF-8
require "binp/version"

class BinParser
  def self.parse(uint8_array, config)
    flatten_config = config.flat_map { |e|
      new_e = e.clone
      # ビットフラグかどうかを確認
      if e['type'] == BinParserElement::Type::FLAGS
        new_e = BinParserElement.get_flags(uint8_array, e)
      else
        new_e['value'] = BinParserElement.get_value(uint8_array, e['offset'], e['size'], e['type'], e['endianness'], e['value_label'])
      end
      new_e
    }
    end
end

class BinParserElement
  attr_reader :name, :offset, :size, :endianness

  def initialize(name, offset, size, endianness)
    @name = name
    @offset = offset
    @size = size
    @endianness = endianness
  end

  module Type
    UINT8 = { name: 'UINT8', value: 'C' }
    UINT16 = { name: 'UINT16', value: 'S' }
    UINT32 = { name: 'UINT32', value: 'L' }
    UINT64 = { name: 'UINT64', value: 'Q' }
    INT8 = { name: 'INT8', value: 'c' }
    INT16 = { name: 'INT16', value: 's' }
    INT32 = { name: 'INT32', value: 'l' }
    INT64 = { name: 'INT64', value: 'q' }
    FLAGS = { name: 'FLAGS', value: 'C' }
  end

  module Endianness
    BIG_ENDIAN = { name: 'BIG', value: '>' }
    LITTLE_ENDIAN = { name: 'LITTLE', value: '<' }
  end

  # see: https://docs.ruby-lang.org/ja/latest/doc/pack_template.html
  def self.calculate_unpack_template_string(type, endianness)

    # 特殊な条件
    case type
    when BinParserElement::Type::UINT16
      if endianness == BinParserElement::Endianness::BIG_ENDIAN
        # ビッグエンディアン、符号なし 16 bit 整数
        return 'n'
      else
        # リトルエンディアン、符号なし 16 bit 整数
        return 'v'
      end
    when BinParserElement::Type::UINT32
      if endianness == BinParserElement::Endianness::BIG_ENDIAN
        # ビッグエンディアン、符号あり 32 bit 整数
        return 'N'
      else
        # リトルエンディアン、符号あり 32 bit 整数
        return 'V'
      end
    when BinParserElement::Type::UINT8
      # 符号なし 8 bit 整数
      return 'C'
    when BinParserElement::Type::INT8
      # 符号あり 8 bit 整数
      return 'c'
    end

    # その他
    type[:value] + endianness[:value]
  end

  def self.calculate_pack_template_string(size)
    'C' * size
  end

  def self.get_value(uint8_array, offset, size, type, endianness, value_labels={})
    target = uint8_array.slice(offset, size)
    pack_template_string = calculate_pack_template_string(size)
    unpack_template_string = calculate_unpack_template_string(type, endianness)
    value = target.pack(pack_template_string).unpack(unpack_template_string)[0]

    # value_label が設定されている数値であれば、それに置き換える
    value_labels ||= {}
    value_labels.fetch(value, value)
  end

  def self.get_flags(uint8_array, config)
    offset = config['offset']
    layout = config['layout']
    target = uint8_array.slice(offset, 1)
    layout.map { |e|
      c = config.dup
      c['name'] = e['name']

      # ビットが立っているかの確認
      c['value'] = target[0] & (1 << e['position'])

      # true_label, false_label が存在すればそれに設定。
      # 存在しなければデフォルト値('ON', 'OFF')に設定。
      if c['value'] != 0
        c['value'] = e.fetch('true_label', 'ON')
      else
        c['value'] = e.fetch('false_label', 'OFF')
      end
      c
    }
  end
end

