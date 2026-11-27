defmodule NoctiaWeb.UserLive.Registration do
  use NoctiaWeb, :live_view

  alias Noctia.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <div :if={@recovery_codes} id="recovery-codes" class="space-y-4">
          <.header>
            Save your recovery codes
            <:subtitle>
              They are the only way to reset your password. Each code works once and
              they will not be shown again.
            </:subtitle>
          </.header>
          <ul class="grid grid-cols-1 gap-1 rounded-box bg-base-200 p-4 font-mono text-sm">
            <li :for={code <- @recovery_codes}>{code}</li>
          </ul>
          <.button id="continue-button" phx-click="continue" class="btn btn-primary w-full">
            I saved my codes, continue
          </.button>
        </div>

        <div :if={!@recovery_codes} class="text-center">
          <.header>
            Create your account
            <:subtitle>This is a one-time setup. Registration closes afterwards.</:subtitle>
          </.header>
        </div>

        <%!-- Kept in the DOM (hidden) after saving, so "continue" can submit it to log in. --%>
        <.form
          for={@form}
          id="registration_form"
          class={[@recovery_codes && "hidden"]}
          phx-submit="save"
          phx-change="validate"
          action={~p"/users/log-in?_action=registered"}
          method="post"
          phx-trigger-action={@trigger_submit}
        >
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
            field={@form[:password]}
            type="password"
            label="Password"
            autocomplete="new-password"
            required
          />
          <.input
            field={@form[:password_confirmation]}
            type="password"
            label="Confirm password"
            autocomplete="new-password"
            required
          />

          <.button phx-disable-with="Creating account..." class="btn btn-primary w-full">
            Create account
          </.button>
        </.form>
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
    if Accounts.registration_open?() do
      {:ok,
       socket
       |> assign(trigger_submit: false, recovery_codes: nil)
       |> assign_form(Accounts.change_user_registration())}
    else
      {:ok,
       socket
       |> put_flash(:error, "Registration is closed.")
       |> redirect(to: ~p"/users/log-in")}
    end
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, {_user, codes}} ->
        {:noreply, assign(socket, recovery_codes: codes)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%Accounts.User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  # Submit the (hidden) form over HTTP to the session controller to log in.
  def handle_event("continue", _params, socket) do
    {:noreply, assign(socket, trigger_submit: true)}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset, as: "user"))
  end
end
