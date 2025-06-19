defmodule CueWeb.CueLive.Show do
  use CueWeb, :live_view

  alias Cue.Groups
  alias Cue.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    cue = Groups.get_cue!(id)
    current_user = socket.assigns.current_user

    {:noreply,
     socket
     |> assign(:page_title, "Cue: #{cue.name}")
     |> assign(:cue, cue)
     |> assign(:is_member, Groups.is_member?(current_user, cue))
     |> assign(:user_role, Groups.get_user_role(current_user, cue))
     |> assign(:is_creator, cue.creator_id == current_user.id)}
  end

  @impl true
  def handle_event("join", _, socket) do
    current_user = socket.assigns.current_user
    cue = socket.assigns.cue

    case Groups.add_user_to_cue(current_user, cue) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:is_member, true)
         |> assign(:user_role, "member")
         |> put_flash(:info, "You have joined the cue.")}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Unable to join the cue.")}
    end
  end

  @impl true
  def handle_event("leave", _, socket) do
    current_user = socket.assigns.current_user
    cue = socket.assigns.cue

    case Groups.remove_user_from_cue(current_user, cue) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:is_member, false)
         |> assign(:user_role, nil)
         |> put_flash(:info, "You have left the cue.")}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Unable to leave the cue.")}
    end
  end
end
