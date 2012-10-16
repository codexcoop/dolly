class UserSessionsController < ApplicationController
  before_filter :require_user, :only => :destroy
  layout "login"

  def new
    if current_user
      redirect_to dashboard_url
    else
      @user_session = UserSession.new
    end
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
#     flash[:notice] = t :login_successful, :scope => [:application]
      flash[:notice] = nil
      redirect_to dashboard_url
    else
      flash[:notice] = t :login_failed, :scope => [:application]
      render :action => :new
    end
  end

  def destroy
    current_user_session.destroy
    flash[:notice] = t :logout_successful, :scope => [:application]
    redirect_to root_url
  end
end

