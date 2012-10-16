# this module is thought to be plugged in the application controller

module UserSessionsControl
  # private methods required by AUTHLOGIC, CANCAN, ACL9...
  private

  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.record
  end

  def require_user
    unless current_user
      store_location
      flash[:notice] = t :require_user, :scope => [:application]
      redirect_to dashboard_url
      return false
    end
  end

#  def require_no_user
#    if current_user
#      store_location
#      flash[:notice] = t :require_no_user, :scope => [:application]
#      redirect_to dashboard_url
#      return false
#    end
#  end

  def store_location
    session[:return_to] = request.request_uri
  end

  def redirect_back_or_default(default)
    store_location
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  # / AUTHLOGIC

end

