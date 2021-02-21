require "test_helper"

require_relative '../lib/binp/cli/main.rb'
require_relative '../lib/binp.rb'

class TestMain < Test::Unit::TestCase
  sub_test_case "configfile_to_hash" do
    test "simple" do

      expected = [{
        "name" => "UINT16_12345",
        "type" => BinParserElement::Type::UINT16,
        "offset" => 0,
        "size" => 2,
        "endianness"=> BinParserElement::Endianness::BIG_ENDIAN
      }]

      config_file_path = './test/resource/test.yaml'
      actual = Main.read_config_file(config_file_path)

      assert_equal(expected, actual)
    end
  end
end

class TestBinaryParser < Test::Unit::TestCase

  sub_test_case "parse" do
    test "UINT8 value" do
      config = [
        {
          'name' => 'UINT8_value',
          'offset' => 0,
          'size' => 1,
          'type' => BinParserElement::Type::UINT8,
          'endianness' => BinParserElement::Endianness::LITTLE_ENDIAN
        },
        {
          'name' => 'UINT16_value',
          'offset' => 1,
          'size' => 2,
          'type' => BinParserElement::Type::UINT16,
          'endianness' => BinParserElement::Endianness::LITTLE_ENDIAN
        }
      ]
      actual = BinParser.parse([8, 0, 1], config)
      expected_1 = {
        'name' => 'UINT8_value',
        'offset' => 0,
        'size' => 1,
        'type' => BinParserElement::Type::UINT8,
        'endianness' => BinParserElement::Endianness::LITTLE_ENDIAN,
        'value' => 8
      }
      expected_2 = {
        'name' => 'UINT16_value',
        'offset' => 1,
        'size' => 2,
        'type' => BinParserElement::Type::UINT16,
        'endianness' => BinParserElement::Endianness::LITTLE_ENDIAN,
        'value' => 256
      }

      assert_equal(expected_1, actual[0])
      assert_equal(expected_2, actual[1])
    end
  end
end

class TestBinaryParserElement < Test::Unit::TestCase

  sub_test_case "calculate_unpack_template_string" do
    test "UINT8, LITTLE_ENDIAN is C" do
      actual = BinParserElement.calculate_unpack_template_string(BinParserElement::Type::UINT8, BinParserElement::Endianness::LITTLE_ENDIAN)
      assert_equal('C', actual)
    end

    test "UINT8, BIG_ENDIAN is C" do
      actual = BinParserElement.calculate_unpack_template_string(BinParserElement::Type::UINT8, BinParserElement::Endianness::BIG_ENDIAN)
      assert_equal('C', actual)
    end

    test "UINT16, LITTLE_ENDIAN is v" do
      actual = BinParserElement.calculate_unpack_template_string(BinParserElement::Type::UINT16, BinParserElement::Endianness::LITTLE_ENDIAN)
      assert_equal('v', actual)
    end

    test "UINT16, BIG_ENDIAN is n" do
      actual = BinParserElement.calculate_unpack_template_string(BinParserElement::Type::UINT16, BinParserElement::Endianness::BIG_ENDIAN)
      assert_equal('n', actual)
    end

    test "UINT32, LITTLE_ENDIAN is V" do
      actual = BinParserElement.calculate_unpack_template_string(BinParserElement::Type::UINT32, BinParserElement::Endianness::LITTLE_ENDIAN)
      assert_equal('V', actual)
    end

    test "UINT32, BIG_ENDIAN is N" do
      actual = BinParserElement.calculate_unpack_template_string(BinParserElement::Type::UINT32, BinParserElement::Endianness::BIG_ENDIAN)
      assert_equal('N', actual)
    end

    test "UINT64, LITTLE_ENDIAN is Q<" do
      actual = BinParserElement.calculate_unpack_template_string(BinParserElement::Type::UINT64, BinParserElement::Endianness::LITTLE_ENDIAN)
      assert_equal('Q<', actual)
    end

    test "UINT64, BIG_ENDIAN is Q>" do
      actual = BinParserElement.calculate_unpack_template_string(BinParserElement::Type::UINT64, BinParserElement::Endianness::BIG_ENDIAN)
      assert_equal('Q>', actual)
    end

    test "INT8, LITTLE_ENDIAN is c" do
      actual = BinParserElement.calculate_unpack_template_string(BinParserElement::Type::INT8, BinParserElement::Endianness::LITTLE_ENDIAN)
      assert_equal('c', actual)
    end

    test "INT8, BIG_ENDIAN is c" do
      actual = BinParserElement.calculate_unpack_template_string(BinParserElement::Type::INT8, BinParserElement::Endianness::BIG_ENDIAN)
      assert_equal('c', actual)
    end

    test "INT16, LITTLE_ENDIAN is s<" do
      actual = BinParserElement.calculate_unpack_template_string(BinParserElement::Type::INT16, BinParserElement::Endianness::LITTLE_ENDIAN)
      assert_equal('s<', actual)
    end

    test "INT16, BIG_ENDIAN is s>" do
      actual = BinParserElement.calculate_unpack_template_string(BinParserElement::Type::INT16, BinParserElement::Endianness::BIG_ENDIAN)
      assert_equal('s>', actual)
    end
  end

  sub_test_case "calculate_pack_template_string" do
    test "size == 1 is C" do
      actual = BinParserElement.calculate_pack_template_string(1)
      assert_equal('C', actual)
    end

    test "size == 6 is CCCCCC" do
      actual = BinParserElement.calculate_pack_template_string(6)
      assert_equal('CCCCCC', actual)
    end
  end

  sub_test_case "get_value" do
    test "data: '\\30\\39' and {offset: 0, size: 2, type: UINT16, endianness: BIG_ENDIAN} is 12345" do
      data = [48, 57]

      actual = BinParserElement.get_value(data, 0, 2, BinParserElement::Type::UINT16, BinParserElement::Endianness::BIG_ENDIAN)
      assert_equal(12345, actual)
    end

    test "data: '\\30\\39' and {offset: 0, size: 2, type: UINT16, endianness: BIG_ENDIAN}, value_labels: {12345 => 'value is 12345'} is 'value is 12345'" do
      data = [48, 57]

      actual = BinParserElement.get_value(data, 0, 2, BinParserElement::Type::UINT16, BinParserElement::Endianness::BIG_ENDIAN, {12345 => 'value is 12345'})
      assert_equal('value is 12345', actual)
    end

    test "data: '\\30\\39' and {offset: 0, size: 2, type: UINT16, endianness: BIG_ENDIAN}, value_labels: {54321 => 'value is 54321'} is '12345'" do
      data = [48, 57]

      actual = BinParserElement.get_value(data, 0, 2, BinParserElement::Type::UINT16, BinParserElement::Endianness::BIG_ENDIAN, {54321 => 'value is 54321'})
      assert_equal(12345, actual)
    end

    test "data: '\\39\\30' and {offset: 0, size: 2, type: UINT16, endianness: LITTLE_ENDIAN} is 12345" do
      data = [57, 48]

      actual = BinParserElement.get_value(data, 0, 2, BinParserElement::Type::UINT16, BinParserElement::Endianness::LITTLE_ENDIAN)
      assert_equal(12345, actual)
    end
  end

  sub_test_case "get_flags" do
    test "data: '\\AA' " do
      data = [170]

      config = {
          'name' => 'test',
          'offset' => 0,
          'type' => 'FLAGS',
          'layout' => [
              { 'name' => 'LED1', 'position' => 0 }, # 0
              { 'name' => 'LED2', 'position' => 1 }, # 1
              { 'name' => 'LED3', 'position' => 2 }, # 0
              { 'name' => 'LED4', 'position' => 3 }, # 1
              { 'name' => 'LED5', 'position' => 4 }, # 0
              { 'name' => 'LED6', 'position' => 5 }, # 1
              { 'name' => 'LED7', 'position' => 6 }, # 0
              { 'name' => 'LED8', 'position' => 7 }  # 1
          ]
      }

      actual = BinParserElement.get_flags(data, config)
      assert_equal('OFF', actual[0]['value'])
      assert_equal('ON', actual[1]['value'])
      assert_equal('OFF', actual[2]['value'])
      assert_equal('ON', actual[3]['value'])
      assert_equal('OFF', actual[4]['value'])
      assert_equal('ON', actual[5]['value'])
      assert_equal('OFF', actual[6]['value'])
      assert_equal('ON', actual[7]['value'])
    end
  end
end

