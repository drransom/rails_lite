require 'uri'

module Phase5
  class Params

    def initialize(req, route_params = {})
      @params = decode_string(req.query_string)
        .merge(decode_string(req.body))
        .merge(route_params)
    end

    def [](key)
      @params[key.to_s]
    end

    def to_sn
      @params.to_json.to_s
    end

    class AttributeNotFoundError < ArgumentError; end;

    private
    # this should return deeply nested hash
    # argument format
    # user[address][street]=main&user[address][zip]=89436
    # should return
    # { "user" => { "address" => { "street" => "main", "zip" => "89436" } } }
    def parse_nested_keys(keys, value)
      if keys.empty?
        value
      else
        { keys[0] => parse_nested_keys(keys[1..-1], value) }
      end
    end

    def parse_www_encoded_form(www_encoded_form)

      key_values = www_encoded_form.split('&')
      parsed_hash = {}
      key_values.each do |key_value|
        key_value = key_value.split('=')
        keys = key_value[0]
        value = key_value[-1]
        keys = parse_key(keys)
        new_value = parse_nested_keys(keys[1..-1], value)
        if parsed_hash[keys[0]].is_a?(Hash)
          parsed_hash[keys[0]] = parsed_hash[keys[0]].deep_merge(new_value)
        else
          parsed_hash[keys[0]] = new_value
        end
      end
      parsed_hash
    end

    # this should return an array
    # user[address][street] should return ['user', 'address', 'street']
    def parse_key(key)
      key.split(/\]\[|\[|\]/)
    end

    def decode_string(query_string)
      if query_string
        parse_www_encoded_form(query_string)
      else
        {}
      end
    end
  end
end
