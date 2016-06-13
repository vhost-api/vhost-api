# frozen_string_literal: true
get '/login' do
  haml :login, layout: :layout_login
end

get '/logout' do
  status, headers, body = call env.merge('PATH_INFO' => '/api/v1/auth/logout')
  [status, headers, body]
end

namespace '/mail' do
  before do
    @sidebar_title = 'Mail'
    @sidebar_elements = %w(Domains Accounts Aliases Sources Forwardings DKIM)
  end

  get do
    authenticate!
    haml :mailhome
  end

  namespace '/domains' do
    get do
      authenticate!
      _status, _headers, body = call env.merge('PATH_INFO' =>
                                             '/api/v1/domains.json')
      @domains = JSON.parse(body[0])['domains']
      haml :domains
    end

    before %r{\A/(?<id>\d+)/?.*} do
      @domain = Domain.get(params[:id])
      # 404 = Not Found
      halt 404 if @domain.nil?
    end

    namespace '/:id' do
      get do
        authenticate!
        return_resource object: @domain
      end

      get '/edit' do
        authenticate!
        unless @user.admin? || @user.owner_of?(@domain)
          @domain = nil
          flash[:error] = 'Not authorized!'
          session[:return_to] = nil
          redirect '/'
        end
        haml :edit_domain
      end
    end
  end

  namespace '/accounts' do
    get do
      authenticate!
      _status, _headers, body = call env.merge('PATH_INFO' =>
                                             '/api/v1/mailaccounts.json')
      @mailaccounts = JSON.parse(body[0])['mailaccounts']
      haml :mailaccounts
    end

    before %r{\A/(?<id>\d+)/?.*} do
      @mailaccount = MailAccount.get(params[:id])
      # 404 = Not Found
      halt 404 if @mailaccount.nil?
    end

    namespace '/:id' do
      get do
        authenticate!
        return_resource object: @mailaccount
      end

      get '/edit' do
        authenticate!
        unless @user.admin? || @user.owner_of?(@mailaccount)
          @mailaccount = nil
          flash[:error] = 'Not authorized!'
          session[:return_to] = nil
          redirect '/'
        end
        haml :edit_mailaccount
      end
    end
  end

  namespace '/aliases' do
    get do
      authenticate!
      _status, _headers, body = call env.merge('PATH_INFO' =>
                                             '/api/v1/mailaliases.json')
      @mailaliases = JSON.parse(body[0])['mailaliases']
      haml :mailaliases
    end
  end

  namespace '/sources' do
    get do
      authenticate!
      _status, _headers, body = call env.merge('PATH_INFO' =>
                                             '/api/v1/mailsources.json')
      @mailsources = JSON.parse(body[0])['mailsources']
      haml :mailsources
    end
  end

  namespace '/dkim' do
    get do
      authenticate!
      _status, _headers, body = call env.merge('PATH_INFO' =>
                                             '/api/v1/dkims.json')
      @dkims = JSON.parse(body[0])['dkims']
      _status, _headers, body = call env.merge('PATH_INFO' =>
                                             '/api/v1/dkimsignings.json')
      @dkimsignings = JSON.parse(body[0])['dkimsignings']
      haml :dkim
    end

    before %r{\A/(?<id>\d+)/?.*} do
      @mailaccount = MailAccount.get(params[:id])
      # 404 = Not Found
      halt 404 if @mailaccount.nil?
    end

    namespace '/:id' do
      get do
        authenticate!
        return_resource object: @mailaccount
      end

      get '/edit' do
        authenticate!
        unless @user.admin? || @user.owner_of?(@mailaccount)
          @mailaccount = nil
          flash[:error] = 'Not authorized!'
          session[:return_to] = nil
          redirect '/'
        end
        haml :edit_mailaccount
      end
    end
  end
end

namespace '/domains' do
  before do
    @sidebar_title = 'Domains'
    @sidebar_elements = ['Domains']
  end

  get do
    authenticate!
    _status, _headers, body = call env.merge('PATH_INFO' =>
                                           '/api/v1/domains.json')
    @domains = JSON.parse(body[0])['domains']
    haml :domains
  end
end

namespace '/dns' do
  before do
    @sidebar_title = 'DNS'
    @sidebar_elements = %w(Domains Zones Templates)
  end

  get do
    authenticate!
    haml :dnshome
  end

  namespace '/domains' do
    get do
      authenticate!
      _status, _headers, body = call env.merge('PATH_INFO' =>
                                             '/api/v1/domains.json')
      @domains = JSON.parse(body[0])['domains']
      haml :domains
    end

    before %r{\A/(?<id>\d+)/?.*} do
      @domain = Domain.get(params[:id])
      # 404 = Not Found
      halt 404 if @domain.nil?
    end

    namespace '/:id' do
      get do
        authenticate!
        return_resource object: @domain
      end

      get '/edit' do
        authenticate!
        unless @user.admin? || @user.owner_of?(@domain)
          @domain = nil
          flash[:error] = 'Not authorized!'
          session[:return_to] = nil
          redirect '/'
        end
        haml :edit_domain
      end
    end
  end

  namespace '/zones' do
    get do
      haml :dns_zones
    end
  end
end
