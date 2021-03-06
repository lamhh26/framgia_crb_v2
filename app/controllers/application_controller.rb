class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  include ApplicationHelper

  protect_from_forgery with: :exception
  before_action :authenticate_user!
  before_action :set_locale
  before_action :configure_permitted_parameters, if: :devise_controller?
  after_action :store_location

  rescue_from CanCan::AccessDenied do |exception|
    flash[:alert] = exception.message
    redirect_to unauthenticated_root_path
  end

  def api
    str = File.open("#{Rails.root}/doc/api.md").read

    str.gsub!(":event_id", Event.all.sample.id.to_s)
      .gsub!(":auth_token", User.all.sample.auth_token)

    str = BlueCloth.new(str).to_html
    html = to_html(str, "Room Booking API")
    render text: html.html_safe
  end

  protected
  def authenticate_user! opts={}
    if current_user
      super
    else
      redirect_to unauthenticated_root_path,
        alert: t("devise.failure.unauthenticated")
      ## if you want render 404 page
      ## render :file => File.join(Rails.root, 'public/404'), :formats => [:html], :status => 404, :layout => false
    end
  end

  private
  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit :sign_up, keys: User::ATTR_PARAMS
    devise_parameter_sanitizer.permit :account_update, keys: User::ATTR_PARAMS
  end

  def validate_permission_change_of_calendar calendar
    unless current_user.permission_make_change?(calendar) ||
      current_user.permission_manage?(calendar)
      redirect_to root_path
    end
  end

  def validate_permission_see_detail_of_calendar calendar
    if !current_user.has_permission?(calendar) ||
      (current_user.permission_hide_details?(calendar) && !calendar.share_public?)
      redirect_to root_path
    end
  end

  def store_location
    unless (request.path == "/users/sign_in" ||
      request.path == "/users/sign_up" ||
      request.path == "/users/password/new" ||
      request.path == "/users/password/edit" ||
      request.path == "/users/confirmation" ||
      request.path == "/users/sign_out" ||
      request.xhr?)
      session[:previous_url] = request.fullpath
    end
  end

  def after_sign_in_path_for _
    session[:previous_url] || root_path
  end

  def to_html str, title
    <<-HTML
      <html lang="en">
        <head>
          <title>#{title}</title>
          <link href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7" crossorigin="anonymous">
        </head>
        <body style="background: #fff;">
          <div class="container">
            #{str}
          </div>
        </body>
      </html>
    HTML
  end
end
