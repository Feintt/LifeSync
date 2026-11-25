defmodule Noctia.AccountsTest do
  use Noctia.DataCase, async: true

  alias Noctia.Accounts
  alias Noctia.Accounts.{User, UserToken}

  import Noctia.AccountsFixtures

  describe "register_user/1" do
    test "registers the first user and closes registration" do
      assert Accounts.registration_open?()
      assert {:ok, %User{} = user} = Accounts.register_user(valid_user_attributes())
      assert user.username == valid_username()
      assert is_binary(user.hashed_password)
      assert is_nil(user.password)
      refute Accounts.registration_open?()
    end

    test "rejects any registration once a user exists" do
      user_fixture()

      assert {:error, changeset} =
               Accounts.register_user(valid_user_attributes(username: "someone_else"))

      assert "registration is closed" in errors_on(changeset).username
      assert Repo.aggregate(User, :count) == 1
    end

    test "validates username and password" do
      {:error, changeset} =
        Accounts.register_user(%{
          username: "no spaces!",
          password: "short",
          password_confirmation: "other"
        })

      assert %{
               username: ["only letters, numbers, dots, dashes and underscores"],
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end
  end

  describe "get_user_by_username_and_password/2" do
    test "returns the user only with valid credentials" do
      %{id: id} = user_fixture()

      assert %User{id: ^id} =
               Accounts.get_user_by_username_and_password(
                 String.upcase(valid_username()),
                 valid_user_password()
               )

      refute Accounts.get_user_by_username_and_password(valid_username(), "wrong password!")
      refute Accounts.get_user_by_username_and_password("unknown", valid_user_password())
    end
  end

  describe "update_user_password/4" do
    setup do
      user = user_fixture()
      %{user: user, token: Accounts.generate_user_session_token(user)}
    end

    test "requires the current password", %{user: user, token: token} do
      {:error, changeset} =
        Accounts.update_user_password(user, "invalid", %{password: "new valid password"}, token)

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "validates the new password", %{user: user, token: token} do
      {:error, changeset} =
        Accounts.update_user_password(user, valid_user_password(), %{password: "short"}, token)

      assert %{password: ["should be at least 12 character(s)"]} = errors_on(changeset)
    end

    test "updates the password and expires every other session", %{user: user, token: token} do
      other_token = Accounts.generate_user_session_token(user)

      {:ok, {user, [%UserToken{token: ^other_token}]}} =
        Accounts.update_user_password(
          user,
          valid_user_password(),
          %{password: "new valid password"},
          token
        )

      assert Accounts.get_user_by_username_and_password(user.username, "new valid password")
      assert Accounts.get_user_by_session_token(token)
      refute Accounts.get_user_by_session_token(other_token)
    end
  end

  describe "session tokens" do
    setup do
      user = user_fixture()
      %{user: user, token: Accounts.generate_user_session_token(user)}
    end

    test "returns the user for a valid token", %{user: user, token: token} do
      assert {session_user, %DateTime{}} = Accounts.get_user_by_session_token(token)
      assert session_user.id == user.id
      refute Accounts.get_user_by_session_token("oops")
    end

    test "does not return the user for an expired token", %{token: token} do
      offset_user_token(token, -15, :day)
      refute Accounts.get_user_by_session_token(token)
    end

    test "delete_user_session_token/1 deletes the token", %{token: token} do
      assert Accounts.delete_user_session_token(token) == :ok
      refute Accounts.get_user_by_session_token(token)
    end
  end
end
