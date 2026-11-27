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

      <div class="divider" />

      <.header>
        Recovery codes
        <:subtitle>
          <span id="recovery-codes-count">{@recovery_codes_count}</span>
          unused codes left. Generating new codes invalidates the old ones.
        </:subtitle>
      </.header>

      <div :if={@new_recovery_codes} id="new-recovery-codes" class="space-y-2">
        <p class="text-sm font-semibold">Save these now, they will not be shown again:</p>
        <ul class="grid grid-cols-1 gap-1 rounded-box bg-base-200 p-4 font-mono text-sm">
          <li :for={code <- @new_recovery_codes}>{code}</li>
        </ul>
      </div>

      <.form for={@recovery_form} id="recovery_codes_form" phx-submit="regenerate_codes">
        <.input
          field={@recovery_form[:current_password]}
          type="password"
          label="Current password"
          autocomplete="current-password"
          required
        />
        <.button variant="primary" phx-disable-with="Generating...">
          Generate new codes
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
     |> assign(:password_form, to_form(Accounts.change_user_password(user)))
     |> assign(:recovery_codes_count, Accounts.count_recovery_codes(user))
     |> assign(:new_recovery_codes, nil)
     |> assign(:recovery_form, to_form(%{}, as: "recovery"))}
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

  def handle_event("regenerate_codes", %{"recovery" => %{"current_password" => password}}, socket) do
    case Accounts.regenerate_recovery_codes(socket.assigns.current_scope.user, password) do
      {:ok, codes} ->
        {:noreply,
         socket
         |> assign(new_recovery_codes: codes, recovery_codes_count: length(codes))
         |> assign(recovery_form: to_form(%{}, as: "recovery"))}

      {:error, :invalid_password} ->
        form =
          to_form(%{"current_password" => ""},
            as: "recovery",
            errors: [current_password: {"is not valid", []}]
          )

        {:noreply, assign(socket, recovery_form: form)}
    end
  end
end
