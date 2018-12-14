class SlackAuthorizer
  UNAUTHORIZED_MESSAGE = 'Application not authorized.  Unrecognized token provided.'.freeze
  UNAUTHORIZED_RESPONSE = ['200', {'Content-Type' => 'text'}, [UNAUTHORIZED_MESSAGE]]

  def initialize(app)
    @app = app
  end

  def call(env)
    req = Rack::Request.new(env)
    params = JSON.parse(req.body.read)
    req.body.rewind

    if params['token'] && params['token'] == ENV['PIVNETBOT_VERIFICATION_TOKEN']
      @app.call(env)
    else
      UNAUTHORIZED_RESPONSE
    end
  end
end