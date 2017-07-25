require 'fluent/filter'
require 'nkf'

module Fluent
  class DetectorFilter < Filter
    Fluent::Plugin.register_filter('detector', self)

    config_param :quantifier, :string, default: 'all', required: true

    config_section :allow, required: false do
      config_param :encoding, :string, required: true
    end
    config_section :deny, required: false do
      config_param :encoding, :string, required: true
    end

    def initialize
      super
    end

    def configure(conf)
      super

      conf.elements.each do |section|
        # Encoding
        @enc_list = section.fetch('encoding', '').split(/, */).map{ |enc| Encoding.find(enc) }
        # Allow/Deny & All/Any
        case section.name
        when 'allow'
          @pass_flag = @quantifier.downcase == 'all'
        when 'deny'
          @pass_flag = @quantifier.downcase != 'all'
        else
          raise Fluent::ConfigError, 'detector: specified element name is neither `allow` nor `deny`.'
        end

        if @quantifier.downcase == 'all'
          @validator = -> enc { @enc_list.include?(enc) }
        else
          @validator = -> enc { !@enc_list.include?(enc) }
        end
      end
    end

    def start
      super
    end

    def shutdown
      super
    end

    def filter(tag, time, record)
      if @pass_flag
        detect(record)? record : nil
      else
        !detect(record)? record : nil
      end
    rescue => e
      log.warn "detector: #{e.class} #{e.message} #{e.backtrace.first}"
    end

    private

    def detect(record)
      case record
      when Array
        record.all?{|v| detect(v)}
      when Hash
        record.all?{|k,v| detect(v)}
      when String
        @validator.call(NKF.guess(record))
      else
        true
      end
    end

  end
end if defined?(Fluent::Filter)
