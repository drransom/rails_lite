require 'json'
require 'webrick'

module Phase8

  class Flash
    def initialize(req)
      cookie = req.cookies.find do |cookie|
        cookie.name == '_rails_lite_app_flash'
      end
      if cookie
        content = JSON.parse(cookie.value)
      end
      flash = cookie ? content : {}
      @flash = {}
      flash.each { |key, value | @flash[key.to_sym] = value }
      @flash[:now] = @flash.dup #shallow dup is ok
    end

    def [](key)
      #returns anything in flash.now
      @flash.merge(@flash[:now])[key.to_sym]
    end

    def []=(key, value)
      @flash[key.to_sym] = value
    end

    def now
      @flash[:now]
    end

    def store_flash(res)
      stored_flash = @flash.reject do |key, value|
        key == :now || @flash[:now][key] == value
      end
      res.cookies << WEBrick::Cookie.new('_rails_lite_app_flash',
                                         stored_flash.to_json)
    end
  end
end
