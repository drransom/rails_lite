module Phase6
  class Route
    attr_reader :pattern, :http_method, :controller_class, :action_name

    def initialize(pattern, http_method, controller_class, action_name)
      @pattern = Regexp.new(pattern.to_s)
      @http_method = http_method.to_s
      @controller_class = controller_class
      @action_name = action_name.to_s
    end

    # checks if pattern matches path and method matches request method
    def matches?(req)
      !!@pattern.match(req.path) && (http_method == req.request_method.downcase.to_s)
    end

    # use pattern to pull out route params (save for later?)
    # instantiate controller and call controller action
    def run(req, res)
      matched_params = @pattern.match(req.path)
      route_params = {}
      if matched_params.names
        matched_params.names.each do |name|
          route_params[name] = matched_params[name]
        end
      end
      @controller_class.new(req, res, route_params).invoke_action(action_name)
    end
  end

  class Router
    attr_reader :routes

    def initialize
      @routes = []
    end

    # simply adds a new route to the list of routes
    def add_route(pattern, method, controller_class, action_name)
      @routes << Route.new(pattern, method, controller_class, action_name)
    end

    # evaluate the proc in the context of the instance
    # for syntactic sugar :)
    def draw(&proc)
      proc.call
    end

    # make each of these methods that
    # when called add route
    [:get, :post, :put, :delete].each do |http_method|
      define_method(http_method) do | pattern, controller_class, action_name |
        add_route(pattern, http_method, controller_class, action_name)
      end
    end

    # should return the route that matches this request
    def match(req)
      @routes.find { |route| route.matches?(req) }
    end

    # either throw 404 or call run on a matched route
    def run(req, res)
      route = match(req)
      route_params =
      if route
        route.run(req, res)
      else
        res.status = 404
      end
    end
  end
end
