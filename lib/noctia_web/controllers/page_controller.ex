defmodule NoctiaWeb.PageController do
  use NoctiaWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
