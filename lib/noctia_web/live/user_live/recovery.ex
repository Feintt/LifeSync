defmodule NoctiaWeb.UserLive.Recovery do
  use NoctiaWeb, :live_view

  alias Noctia.Accounts
  alias Noctia.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm space-y-4">
        <div class="text-center">
          <.header>
            Reset your password
            <:subtitle>Use one of your recovery codes. Each code works only once.</:subtitle>
          </.header>
        </div>

        <.form for={@form} id="recovery_form" phx-submit="reset" phx-change="validate">
          <.input
            field={@form[:username]}
            type="text"
            label="Username"
            autocomplete="username"
            spellcheck="false"
            required
            phx-mounted={JS.focus()}
          />
          <.input
            field={@form[:code]}
            type="text"
            label="Recovery code"
            autocomplete="off"
            spellcheck="false"
            placeholder="XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XX"
            required
          />
          <.input
            field={@form[:password]}
            type="password"
            label="New password"
            autocomplete="new-password"
            required
          />
          <.input
            field={@form[:password_confirmation]}
            type="password"
            label="Confirm new password"
            autocomplete="new-password"
            required
          />
          <.button phx-disable-with="Resetting..." class="btn btn-primary w-full">
            Reset password
          </.button>
        </.form>

        <p class="text-center text-sm">
          <.link navigate={~p"/users/log-in"} class="link">Back to log in</.link>
        </p>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: ~p"/")}
  end

  def mount(_params, _session, socket) do
    {:ok, assign_form(socket, %{})}
  end

  @impl true
  def handle_event("validate", %{"user" => params}, socket) do
    {:noreply, assign_form(socket, params, :validate)}
  end

  def handle_event("reset", %{"user" => params}, socket) do
    %{"username" => username, "code" => code} = params

    case Accounts.reset_password_with_recovery_code(username, code, params) do
      {:ok, {_user, expired_tokens}} ->
        NoctiaWeb.UserAuth.disconnect_sessions(expired_tokens)

        {:noreply,
         socket
         |> put_flash(:info, "Password reset. You can now log in.")
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, :invalid_code} ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid username or recovery code.")
         |> assign_form(Map.delete(params, "code"))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: "user"))}
    end
  end

  # Form backed by the password changeset; username/code are read from params.
  defp assign_form(socket, params, action \\ nil) do
    changeset =
      %User{}
      |> Accounts.change_user_password(params, hash_password: false)
      |> Map.put(:action, action)

    assign(socket, form: to_form(changeset, as: "user"))
  end
end
