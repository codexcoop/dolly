class SiteController < ApplicationController

  def index
    redirect_to login_url
  end

  def dashboard
    redirect_to login_url unless current_user
  end

end

