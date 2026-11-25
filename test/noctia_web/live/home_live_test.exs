defmodule NoctiaWeb.HomeLiveTest do
  use NoctiaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Noctia.AccountsFixtures

  test "redirects to log in when not logged in", %{conn: conn} do
    assert {:error, {:redirect, %{to: path}}} = live(conn, ~p"/")
    assert path == ~p"/users/log-in"
  end

  test "shows the settings link when logged in", %{conn: conn} do
    {:ok, lv, _html} = conn |> log_in_user(user_fixture()) |> live(~p"/")
    assert has_element?(lv, "#settings-link")
  end
end
