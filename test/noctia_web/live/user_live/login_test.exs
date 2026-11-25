defmodule NoctiaWeb.UserLive.LoginTest do
  use NoctiaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Noctia.AccountsFixtures

  describe "login page" do
    test "redirects to registration while no user exists", %{conn: conn} do
      assert {:error, {:redirect, %{to: path}}} = live(conn, ~p"/users/log-in")
      assert path == ~p"/users/register"
    end

    test "renders the login form once a user exists", %{conn: conn} do
      user_fixture()
      {:ok, lv, _html} = live(conn, ~p"/users/log-in")
      assert has_element?(lv, "#login_form")
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/log-in")

      assert {:error, {:redirect, %{to: "/"}}} = result
    end
  end

  describe "user login" do
    test "redirects if user logs in with valid credentials", %{conn: conn} do
      user = user_fixture()
      {:ok, lv, _html} = live(conn, ~p"/users/log-in")

      form =
        form(lv, "#login_form",
          user: %{"username" => user.username, "password" => valid_user_password()}
        )

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/"
      assert get_session(conn, :user_token)
    end
  end
end
