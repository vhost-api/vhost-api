# frozen_string_literal; false
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
      session[:user] = user
      session[:user_id] = user.id
      session[:group] = Group.get(user.group_id).name

      flashmsg = 'Successfully logged in.'
      if settings.environment == :development
        flashmsg << "</br><pre>#{gen_session_json(session: session)}</pre>"
      end
      flash[:success] = flashmsg

      if session[:return_to].nil?
        redirect '/'
      else
        original_request = session[:return_to]
        session[:return_to] = nil
        redirect original_request
      end
    else
      flash[:error] = 'Invalid Login'
      redirect '/login'
    end
  end

  get '/logout' do
    authenticate!
    flashmsg = 'Successfully logged out.'
    if settings.environment == :development
      flashmsg << '</br>previus session:</br>' \
                  "<pre>#{gen_session_json(session: session)}</pre>"
    end
    session[:user] = nil
    session[:user_id] = nil
    session[:group] = nil
    if settings.environment == :development
      flashmsg << '</br>now:</br>' \
                  "<pre>#{gen_session_json(session: session)}</pre>"
    end
    flash[:success] = flashmsg
    redirect '/'
  end

  get '/protected' do
    authenticate!
    my_logger.debug request.env.inspect
    haml :protected
  end

  get '/admin' do
    if @user.admin?
      haml :admin
    else
      flash[:error] = 'not authorized'
      redirect '/'
    end
  end
end
