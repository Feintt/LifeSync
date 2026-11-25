defmodule NoctiaWeb.UserLive.Settings do
  use NoctiaWeb, :live_view

  alias Noctia.Accounts
  alias Noctia.Accounts.Scope

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="text-center">
        <.header>
          Account Settings
          <:subtitle>Change your password</:subtitle>
        </.header>
      </div>

      <.form
        for={@password_form}
        id="password_form"
        phx-change="validate_password"
        phx-submit="update_password"
      >
        <input
          name={@password_form[:username].name}
          type="hidden"
          id="hidden_user_username"
          autocomplete="username"
          value={@current_scope.user.username}
        />
        <.input
          field={@password_form[:current_password]}
          type="password"
          label="Current password"
          autocomplete="current-password"
          required
        />
        <.input
          field={@password_form[:password]}
          type="password"
          label="New password"
          autocomplete="new-password"
          required
        />
        <.input
          field={@password_form[:password_confirmation]}
          type="password"
          label="Confirm new password"
          autocomplete="new-password"
        />
        <.button variant="primary" phx-disable-with="Saving...">
          Save Password
        </.button>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    user = socket.assigns.current_scope.user

    {:ok,
     socket
     |> assign(:user_token, session["user_token"])
     |> assign(:password_form, to_form(Accounts.change_user_password(user)))}
  end

  @impl true
  def handle_event("validate_password", %{"user" => user_params}, socket) do
    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  def handle_event("update_password", %{"user" => user_params}, socket) do
    %{current_scope: %{user: user}, user_token: user_token} = socket.assigns
    current_password = Map.get(user_params, "current_password", "")

    case Accounts.update_user_password(user, current_password, user_params, user_token) do
      {:ok, {user, expired_tokens}} ->
        # Log out every other browser/device.
        NoctiaWeb.UserAuth.disconnect_sessions(expired_tokens)

        {:noreply,
         socket
         |> put_flash(:info, "Password updated successfully.")
         |> assign(:current_scope, Scope.for_user(user))
         |> assign(:password_form, to_form(Accounts.change_user_password(user)))}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset, action: :update))}
    end
  end
end
