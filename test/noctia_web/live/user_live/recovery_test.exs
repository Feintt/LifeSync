defmodule NoctiaWeb.UserLive.RecoveryTest do
  use NoctiaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Noctia.AccountsFixtures

  alias Noctia.Accounts

  setup do
    {user, [code | _]} = user_with_recovery_codes_fixture()
    %{user: user, code: code}
  end

  defp submit(lv, params) do
    lv |> form("#recovery_form", user: params) |> render_submit()
  end

  test "resets the password with a valid code", %{conn: conn, user: user, code: code} do
    {:ok, lv, _html} = live(conn, ~p"/users/recover")

    {:ok, _login_lv, html} =
      lv
      |> submit(%{
        "username" => user.username,
        "code" => code,
        "password" => "new valid password",
        "password_confirmation" => "new valid password"
      })
      |> follow_redirect(conn, ~p"/users/log-in")

    assert html =~ "Password reset"
    assert Accounts.get_user_by_username_and_password(user.username, "new valid password")
  end

  test "rejects an invalid code", %{conn: conn, user: user} do
    {:ok, lv, _html} = live(conn, ~p"/users/recover")

    html =
      submit(lv, %{
        "username" => user.username,
        "code" => "AAAA-BBBB-CCCC",
        "password" => "new valid password",
        "password_confirmation" => "new valid password"
      })

    assert html =~ "Invalid username or recovery code"
    assert Accounts.get_user_by_username_and_password(user.username, valid_user_password())
  end

  test "is linked from the login page", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/users/log-in")
    assert has_element?(lv, "#recover-link")
  end
end
