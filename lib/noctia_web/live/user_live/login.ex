defmodule NoctiaWeb.UserLive.Login do
  use NoctiaWeb, :live_view

  alias Noctia.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm space-y-4">
        <div class="text-center">
          <.header>Log in</.header>
        </div>

        <.form for={@form} id="login_form" action={~p"/users/log-in"} method="post">
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
            autocomplete="current-password"
            required
          />
          <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />
          <.button class="btn btn-primary w-full">
            Log in <span aria-hidden="true">→</span>
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
      {:ok, redirect(socket, to: ~p"/users/register")}
    else
      username = Phoenix.Flash.get(socket.assigns.flash, :username)
      {:ok, assign(socket, form: to_form(%{"username" => username}, as: "user"))}
    end
  end
end
