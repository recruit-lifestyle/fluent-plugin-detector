require 'helper'
require 'fluent/plugin/filter_detector'
require 'nkf'

class DetectorFilterTest < Test::Unit::TestCase

  def setup
    omit('Use Fluentd v0.12 or later.') unless defined?(Fluent::Filter)
    Fluent::Test.setup
  end

  CONFIG_allow = %[
    <allow>
      encoding UTF-8
    </allow>
  ]
  CONFIG_allow_list = %[
    quantifier all
    <allow>
      encoding UTF-8,ASCII
    </allow>
  ]
  CONFIG_allow_any = %[
    quantifier any
    <allow>
      encoding Shift_JIS
    </allow>
  ]
  CONFIG_deny_any = %[
    quantifier any
    <deny>
      encoding Shift_JIS
    </deny>
  ]
  CONFIG_deny_list = %[
    quantifier all
    <deny>
      encoding UTF-8,ASCII
    </deny>
  ]
  CONFIG_deny_any_list = %[
    quantifier any
    <deny>
      encoding UTF-8,ASCII
    </deny>
  ]
  str_utf8 = 'テスト'.encode!(Encoding::UTF_8)
  str_sjis = 'テスト'.encode!(Encoding::Shift_JIS)
  str_euc = 'テスト'.encode!(Encoding::EucJP)
  str_us_ascii = 'test'.encode!(Encoding::US_ASCII)
  bool_obj = true
  int_obj = Integer(3)
  time_obj = Time.now
  float_obj = int_obj.to_f


  def create_driver(conf = CONFIG,tag = 'test')
    Fluent::Test::FilterTestDriver.new(Fluent::DetectorFilter,tag).configure(conf)
  end

  sub_test_case 'configure' do
    test 'allow' do
      d = create_driver(CONFIG_allow)
      assert_equal 'all', d.instance.quantifier
      conf = Fluent::Config.parse(CONFIG_allow, 'hoge')
      assert_equal 'allow', conf.elements[0].name
      assert_equal 'UTF-8', conf.elements.first.values[0]
    end

    test 'deny any' do
      d = create_driver(CONFIG_deny_any)
      assert_not_equal 'all', d.instance.quantifier
      conf = Fluent::Config.parse(CONFIG_deny_any, 'hoge')
      assert_equal 'deny', conf.elements[0].name
      assert_equal 'Shift_JIS', conf.elements.first.values[0]
    end

    test 'deny list' do
      d = create_driver(CONFIG_deny_list)
      assert_equal 'all', d.instance.quantifier
      conf = Fluent::Config.parse(CONFIG_deny_list, 'hoge')
      assert_equal 'deny', conf.elements[0].name
      assert_equal 'UTF-8,ASCII', conf.elements.first.values[0]
    end

    test 'allow any' do
      d = create_driver(CONFIG_allow_any)
      assert_not_equal 'all', d.instance.quantifier
      conf = Fluent::Config.parse(CONFIG_allow_any, 'hoge')
      assert_equal 'allow', conf.elements[0].name
      assert_equal 'Shift_JIS', conf.elements.first.values[0]
    end

    test 'deny any list' do
      d = create_driver(CONFIG_deny_any_list)
      assert_not_equal 'all', d.instance.quantifier
      conf = Fluent::Config.parse(CONFIG_deny_any_list, 'hoge')
      assert_equal 'deny', conf.elements[0].name
      assert_equal 'UTF-8,ASCII', conf.elements.first.values[0]
    end

  end

  sub_test_case 'pass' do
    test 'conf=allow, pass utf8' do
      d = create_driver(CONFIG_allow)
      assert_equal 'UTF-8', NKF.guess(str_utf8).name
      d.run do
        d.filter('a' => str_utf8)
      end
      expected = {'a' => str_utf8}
      assert_equal expected, d.filtered_as_array[0][2]
    end

    test 'conf=deny, pass utf8' do
      d = create_driver(CONFIG_deny_any)
      assert_equal 'UTF-8', NKF.guess(str_utf8).name
      d.run do
        d.filter('a' => str_utf8)
      end
      expected = {'a' => str_utf8}
      assert_equal expected, d.filtered_as_array[0][2]
    end

    test 'conf=allow, pass nested utf8' do
      d = create_driver(CONFIG_allow)
      assert_equal 'UTF-8', NKF.guess(str_utf8).name
      d.run do
        d.filter({'a' => {'b' => str_utf8} } )
      end
      expected = {'a' => {'b' => str_utf8} }
      assert_equal expected, d.filtered_as_array[0][2]
    end

    test 'conf=deny, pass nested utf8' do
      d = create_driver(CONFIG_deny_any)
      assert_equal 'UTF-8', NKF.guess(str_utf8).name
      d.run do
        d.filter({'a' => {'b' => str_utf8} } )
      end
      expected = {'a' => {'b' => str_utf8}}
      assert_equal expected, d.filtered_as_array[0][2]
    end

    test 'conf=allow list, pass utf8 and ascii' do
      d = create_driver(CONFIG_allow_list)
      assert_equal 'UTF-8', NKF.guess(str_utf8).name
      assert_equal 'US-ASCII', NKF.guess(str_us_ascii).name
      d.run do
        d.filter('a' => str_utf8)
        d.filter('a' => str_us_ascii)
      end
      expected = [{'a' => str_utf8},{'a' => str_us_ascii}]
      assert_equal expected[0], d.filtered_as_array[0][2]
      assert_equal expected[1], d.filtered_as_array[1][2]
    end

    test 'conf=deny list, pass sjis and euc' do
      d = create_driver(CONFIG_deny_list)
      assert_equal 'Shift_JIS', NKF.guess(str_sjis).name
      assert_equal 'EUC-JP', NKF.guess(str_euc).name
      d.run do
        d.filter('a' => str_sjis)
        d.filter('a' => str_euc)
      end
      expected = [{'a' => str_sjis},{'a' => str_euc}]
      assert_equal expected[0], d.filtered_as_array[0][2]
      assert_equal expected[1], d.filtered_as_array[1][2]
    end
  end

  sub_test_case 'filter' do
    test 'conf=allow, block sjis' do
      d = create_driver(CONFIG_allow)
      assert_equal 'Shift_JIS', NKF.guess(str_sjis).name
      d.run do
        d.filter('a' => str_sjis)
      end
      assert_nil d.filtered_as_array[0]
    end

    test 'conf=deny, block sjis' do
      d = create_driver(CONFIG_deny_any)
      assert_equal 'Shift_JIS', NKF.guess(str_sjis).name
      d.run do
        d.filter('a' => str_sjis)
      end
      assert_nil d.filtered_as_array[0]
    end

    test 'conf=allow, block nested sjis' do
      d = create_driver(CONFIG_allow)
      assert_equal 'Shift_JIS', NKF.guess(str_sjis).name
      d.run do
        d.filter({'a' => {'b' => str_sjis} } )
      end
      assert_nil d.filtered_as_array[0]
    end

    test 'conf=deny, block nested sjis' do
      d = create_driver(CONFIG_deny_any)
      assert_equal 'Shift_JIS', NKF.guess(str_sjis).name
      d.run do
        d.filter({'a' => {'b' => str_sjis} } )
      end
      assert_nil d.filtered_as_array[0]
    end

    test 'conf=allow, block sjis and pass utf8' do
      d = create_driver(CONFIG_allow)
      assert_equal 'Shift_JIS', NKF.guess(str_sjis).name
      assert_equal 'UTF-8', NKF.guess(str_utf8).name
      d.run do
        d.filter('a' => str_sjis)
        d.filter('a' => str_utf8)
      end
      expected = {'a' => str_utf8}
      assert_equal 1, d.filtered_as_array.length
      assert_equal expected, d.filtered_as_array[0][2]
    end

    test 'conf=deny, block sjis and pass utf8' do
      d = create_driver(CONFIG_deny_any)
      assert_equal 'Shift_JIS', NKF.guess(str_sjis).name
      assert_equal 'UTF-8', NKF.guess(str_utf8).name
      d.run do
        d.filter('a' => str_sjis)
        d.filter('a' => str_utf8)
      end
      expected = {'a' => str_utf8}
      assert_equal 1, d.filtered_as_array.length
      assert_equal expected, d.filtered_as_array[0][2]
    end

    test 'conf=allow, block' do
      d = create_driver(CONFIG_allow)
      assert_equal 'Shift_JIS', NKF.guess(str_sjis).name
      assert_equal 'US-ASCII', NKF.guess(str_us_ascii).name
      d.run do
        d.filter('a' => str_sjis,'b' => str_us_ascii)
      end
      assert_nil d.filtered_as_array[0]
    end

    test 'conf=deny, block' do
      d = create_driver(CONFIG_deny_any)
      assert_equal 'Shift_JIS', NKF.guess(str_sjis).name
      assert_equal 'UTF-8', NKF.guess(str_utf8).name
      d.run do
        d.filter('a' => str_sjis,'b' => str_utf8)
      end
      assert_nil d.filtered_as_array[0]
    end

    test 'conf=allow list, pass utf8 and ascii, block sjis' do
      d = create_driver(CONFIG_allow_list)
      assert_equal 'UTF-8', NKF.guess(str_utf8).name
      assert_equal 'US-ASCII', NKF.guess(str_us_ascii).name
      assert_equal 'Shift_JIS', NKF.guess(str_sjis).name
      d.run do
        d.filter('a' => str_utf8)
        d.filter('a' => str_us_ascii)
        d.filter('a' => str_sjis)
        d.filter('a' => str_sjis, 'b' => str_utf8)
      end
      expected = [{'a' => str_utf8},{'a' => str_us_ascii}]
      assert_equal expected[0], d.filtered_as_array[0][2]
      assert_equal expected[1], d.filtered_as_array[1][2]
    end

    test 'conf=allow any, pass any sjis' do
      d = create_driver(CONFIG_allow_any)
      assert_equal 'UTF-8', NKF.guess(str_utf8).name
      assert_equal 'US-ASCII', NKF.guess(str_us_ascii).name
      assert_equal 'Shift_JIS', NKF.guess(str_sjis).name
      d.run do
        d.filter('a' => str_utf8)
        d.filter('a' => str_us_ascii)
        d.filter('a' => str_sjis)
        d.filter('a' => str_sjis, 'b' => str_utf8)
      end
      expected = [{'a' => str_sjis},{'a' => str_sjis, 'b' => str_utf8}]
      assert_equal expected[0], d.filtered_as_array[0][2]
      assert_equal expected[1], d.filtered_as_array[1][2]
    end

    test 'conf=deny list, pass sjis, block utf8 and ascii' do
      d = create_driver(CONFIG_deny_list)
      assert_equal 'UTF-8', NKF.guess(str_utf8).name
      assert_equal 'US-ASCII', NKF.guess(str_us_ascii).name
      assert_equal 'Shift_JIS', NKF.guess(str_sjis).name
      d.run do
        d.filter('a' => str_utf8)
        d.filter('a' => str_us_ascii)
        d.filter('a' => str_us_ascii, 'b' => str_utf8, 'c' => str_sjis)
        d.filter('a' => str_sjis)
        d.filter('a' => str_sjis, 'b' => str_utf8)
      end
      expected = [{'a' => str_us_ascii, 'b' => str_utf8, 'c' => str_sjis},{'a' => str_sjis},{'a' => str_sjis, 'b' => str_utf8}]
      assert_equal expected[0], d.filtered_as_array[0][2]
      assert_equal expected[1], d.filtered_as_array[1][2]
      assert_equal expected[2], d.filtered_as_array[2][2]
    end

    test 'conf=deny any list, pass any sjis, block utf8 and ascii' do
      d = create_driver(CONFIG_deny_any_list)
      assert_equal 'UTF-8', NKF.guess(str_utf8).name
      assert_equal 'US-ASCII', NKF.guess(str_us_ascii).name
      assert_equal 'Shift_JIS', NKF.guess(str_sjis).name
      d.run do
        d.filter('a' => str_utf8)
        d.filter('a' => str_us_ascii)
        d.filter('a' => str_sjis)
        d.filter('a' => str_sjis, 'b' => str_utf8)
      end
      expected = [{'a' => str_sjis}]
      assert_equal expected[0], d.filtered_as_array[0][2]
    end
  end

  sub_test_case 'non-string types should pass' do
    test 'pass bool' do
      d = create_driver(CONFIG_allow)
      assert_equal true, bool_obj
      d.run do
        d.filter('a' => bool_obj)
      end
      expected = {'a' => bool_obj}
      assert_equal expected, d.filtered_as_array[0][2]
    end

    test 'pass int' do
      d = create_driver(CONFIG_allow)
      assert_equal true, int_obj.is_a?(Integer)
      d.run do
        d.filter('a' => int_obj)
      end
      expected = {'a' => int_obj}
      assert_equal expected, d.filtered_as_array[0][2]
    end

    test 'pass time' do
      d = create_driver(CONFIG_allow)
      assert_equal true, time_obj.is_a?(Time)
      d.run do
        d.filter('a' => time_obj)
      end
      expected = {'a' => time_obj}
      assert_equal expected, d.filtered_as_array[0][2]
    end

    test 'pass float' do
      d = create_driver(CONFIG_allow)
      assert_equal true, float_obj.is_a?(Float)
      d.run do
        d.filter('a' => float_obj)
      end
      expected = {'a' => float_obj}
      assert_equal expected, d.filtered_as_array[0][2]
    end
  end

end
