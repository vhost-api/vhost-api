# frozen_string_literal: true
namespace '/api/v1/auth' do
  post '/login' do
    params['user'] && params['user']['login'] && params['user']['password']

    user = User.first(login: params['user']['login'])

    if user.nil? || !user.enabled
      flash[:error] = 'Invalid Login'
      redirect '/login'
    end

    if user.authenticate(params['user']['password'])
      # store stuff for later use
      session[:user_id] = user.id
      session[:group] = user.group.name

      # flashmsg = 'Successfully logged in.'
      # if settings.environment == :development
      # flashmsg = flashmsg.dup
      # flashmsg << '</br><pre>' + gen_session_json(session: session) + '</pre>'
      # end
      # flash[:success] = flashmsg

      status 200

      # if session[:return_to].nil?
      # redirect '/'
      # else
      # original_request = session[:return_to]
      # session[:return_to] = nil
      # redirect original_request
      # end
    else
      flash[:error] = 'Invalid Login'
      redirect '/login'
    end
  end

  get '/logout' do
    authenticate!
    flashmsg = 'Successfully logged out.'
    if settings.environment == :development
      flashmsg = flashmsg.dup
      flashmsg << '</br>previus session:</br>' \
                  '<pre>' + gen_session_json(session: session) + '</pre>'
    end
    session[:user_id] = nil
    session[:group] = nil
    if settings.environment == :development
      flashmsg = flashmsg.dup
      flashmsg << '</br>now:</br>' \
                  '<pre>' + gen_session_json(session: session) + '</pre>'
    end
    flash[:success] = flashmsg
    redirect '/login'
  end
end
