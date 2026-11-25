defmodule NoctiaWeb.UserLive.SettingsTest do
  use NoctiaWeb.ConnCase, async: true

  alias Noctia.Accounts
  import Phoenix.LiveViewTest
  import Noctia.AccountsFixtures

  describe "Settings page" do
    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/users/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "update password form" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "updates the password and keeps the current session", %{conn: conn, user: user} do
      other_token = Accounts.generate_user_session_token(user)
      NoctiaWeb.Endpoint.subscribe("users_sessions:#{Base.url_encode64(other_token)}")

      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> form("#password_form", %{
          "user" => %{
            "current_password" => valid_user_password(),
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })
        |> render_submit()

      assert result =~ "Password updated successfully"
      assert Accounts.get_user_by_username_and_password(user.username, "new valid password")
      assert Accounts.get_user_by_session_token(get_session(conn, :user_token))
      refute Accounts.get_user_by_session_token(other_token)
      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect"}
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> element("#password_form")
        |> render_change(%{
          "user" => %{"password" => "too short", "password_confirmation" => "does not match"}
        })

      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end

    test "rejects a wrong current password", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> form("#password_form", %{
          "user" => %{
            "current_password" => "wrong password",
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })
        |> render_submit()

      assert result =~ "is not valid"
      assert Accounts.get_user_by_username_and_password(user.username, valid_user_password())
    end
  end
end
