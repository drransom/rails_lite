require_relative '../phase6/controller_base'
require_relative './flash'

module Phase8
  class ControllerBase < Phase6::ControllerBase
    def redirect_to(url)
      super(url)
      flash.store_flash(res)
    end

    def render_content(content, content_type)
      super(content, content_type)
      flash.store_flash(res)
    end

    def flash
      @flash ||= Flash.new(@req)
    end
  end
end
