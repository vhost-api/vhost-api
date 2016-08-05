# frozen_string_literal: true
def css(*stylesheets)
  stylesheets.map do |stylesheet|
    ['<link href="/', stylesheet, '.css" media="screen, projection"',
     ' rel="stylesheet" />'].join
  end.join
end

def set_title
  @title ||= settings.site_title
end

def set_sidebar_title
  @sidebar_title ||= 'Sidebar'
end

def nav_current?(path = '/')
  req_path = request.path.to_s.split('/')[1]
  req_path == path || req_path == path + '/' ? 'current' : nil
end

def sidebar_current?(path = '/')
  req_path = request.path.to_s.split('/')[2]
  req_path == path || req_path == path + '/' ? 'current' : nil
end
