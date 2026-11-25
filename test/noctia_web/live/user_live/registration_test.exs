defmodule NoctiaWeb.UserLive.RegistrationTest do
  use NoctiaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Noctia.AccountsFixtures

  describe "Registration page" do
    test "renders while registration is open", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")
      assert has_element?(lv, "#registration_form")
    end

    test "redirects to log in once a user exists", %{conn: conn} do
      user_fixture()

      assert {:error, {:redirect, %{to: path, flash: flash}}} = live(conn, ~p"/users/register")
      assert path == ~p"/users/log-in"
      assert %{"error" => "Registration is closed."} = flash
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/register")

      assert {:error, {:redirect, %{to: "/"}}} = result
    end

    test "renders errors for invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      result =
        lv
        |> element("#registration_form")
        |> render_change(user: %{"username" => "a b", "password" => "short"})

      assert result =~ "only letters, numbers, dots, dashes and underscores"
      assert result =~ "should be at least 12 character"
    end
  end

  describe "register user" do
    test "creates the account and logs the user in", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      form =
        form(lv, "#registration_form",
          user: %{
            "username" => "owner",
            "password" => valid_user_password(),
            "password_confirmation" => valid_user_password()
          }
        )

      render_submit(form)
      conn = follow_trigger_action(form, conn)

      assert redirected_to(conn) == ~p"/"
      assert get_session(conn, :user_token)
      refute Noctia.Accounts.registration_open?()
    end
  end
end
