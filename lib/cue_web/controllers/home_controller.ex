defmodule CueWeb.HomeController do
  use CueWeb, :controller

  def index(conn, _params) do
    case conn.assigns.current_user do
      nil ->
        # User is not logged in, redirect to login page
        redirect(conn, to: ~p"/users/log_in")

      _user ->
        # User is logged in, redirect to cues page
        redirect(conn, to: ~p"/cues")
    end
  end
end
