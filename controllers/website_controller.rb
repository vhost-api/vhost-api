# frozen_string_literal: true
get '/login' do
  haml :login, layout: :layout_login
end

get '/logout' do
  status, headers, body = call env.merge('PATH_INFO' => '/api/v1/auth/logout')
  [status, headers, body]
end

namespace '/user' do
  before do
    @sidebar_title = 'Users'
    @sidebar_elements = ['Users']
  end

  get do
    authenticate!
    _status, _headers, body = call env.merge('PATH_INFO' =>
                                           '/api/v1/users.json')
    @users = JSON.parse(body[0])
    haml :users
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
    @domains = JSON.parse(body[0])
    haml :domains
  end
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
      @domains = JSON.parse(body[0])
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
      @mailaccounts = JSON.parse(body[0])
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
      @mailaliases = JSON.parse(body[0])
      haml :mailaliases
    end
  end

  namespace '/sources' do
    get do
      authenticate!
      _status, _headers, body = call env.merge('PATH_INFO' =>
                                             '/api/v1/mailsources.json')
      @mailsources = JSON.parse(body[0])
      haml :mailsources
    end
  end

  namespace '/dkim' do
    get do
      authenticate!
      _status, _headers, body = call env.merge('PATH_INFO' =>
                                             '/api/v1/dkims.json')
      @dkims = JSON.parse(body[0])
      _status, _headers, body = call env.merge('PATH_INFO' =>
                                             '/api/v1/dkimsignings.json')
      @dkimsignings = JSON.parse(body[0])
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

namespace '/webhosting' do
  before do
    @sidebar_title = 'Webhosting'
    @sidebar_elements = %w(VHosts SFTPUsers ShellUsers)
  end

  get do
    authenticate!
    _status, _headers, body = call env.merge('PATH_INFO' =>
                                           '/api/v1/phpruntimes.json')
    @phpruntimes = JSON.parse(body[0])
    _status, _headers, body = call env.merge('PATH_INFO' =>
                                           '/api/v1/ipv4addresses.json')
    @ipv4addresses = JSON.parse(body[0])
    _status, _headers, body = call env.merge('PATH_INFO' =>
                                           '/api/v1/ipv6addresses.json')
    @ipv6addresses = JSON.parse(body[0])
    haml :webhostinghome
  end

  namespace '/vhosts' do
    get do
      authenticate!
      _status, _headers, body = call env.merge('PATH_INFO' =>
                                             '/api/v1/vhosts.json')
      @vhosts = JSON.parse(body[0])
      haml :vhosts
    end
  end

  namespace '/sftpusers' do
    get do
      authenticate!
      _status, _headers, body = call env.merge('PATH_INFO' =>
                                             '/api/v1/sftpusers.json')
      @sftpusers = JSON.parse(body[0])
      haml :sftpusers
    end
  end

  namespace '/shellusers' do
    get do
      authenticate!
      _status, _headers, body = call env.merge('PATH_INFO' =>
                                             '/api/v1/shellusers.json')
      @shellusers = JSON.parse(body[0])
      haml :shellusers
    end
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
      @domains = JSON.parse(body[0])
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
end
