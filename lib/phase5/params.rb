require 'uri'

module Phase5
  class Params
    # use your initialize to merge params from
    # 1. query string
    # 2. post body
    # 3. route params
    #
    # You haven't done routing yet; but assume route params will be
    # passed in as a hash to `Params.new` as below:
    def initialize(req, route_params = {})
      # decoded_string = if req.query_string
      #   parse_www_encoded_form(req.query_string)
      # else
      #   {}
      # end
      @params = decode_string(req.query_string)
                .merge(decode_string(req.body))
                .merge(route_params)
    end

    def [](key)
      @params[key.to_s]
    end

    def to_s
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
      debugger
      key_values = www_encoded_form.split('&')
      parsed_hash = {}
      key_values.each do |key_value|
        key_value = key_value.split('=')
        keys = key_value[0]
        value = key_value[-1]
        keys = parse_key(keys)
        new_value = parse_nested_keys(keys[1..-1], value)
        if parsed_hash[keys[0]].is_a?(Hash)
          parsed_hash[keys[0]] = friendly_merge(parsed_hash[keys[0]], new_value)
        else
          parsed_hash[keys[0]] = new_value
        end
      end
      parsed_hash
    end

    def friendly_merge(hash1, hash2)
      new_hash = {}
      hash1.each do |key, value|
        if value.is_a?(Hash) && hash2[key].is_a?(Hash)
          new_hash[key] = friendly_merge(value, hash2[key])
        else
          new_hash[key] = value
        end
      end
      hash2.merge(new_hash)
    end


    #   end
    #   URI.decode_www_form(www_encoded_form).to_h
    # end

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
