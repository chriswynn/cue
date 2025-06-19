defmodule CueWeb.CueLive.Index do
  use CueWeb, :live_view

  alias Cue.Groups
  alias Cue.Groups.CueGroup

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :cues, list_cues())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Cue")
    |> assign(:cue, %CueGroup{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Cues")
    |> assign(:cue, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    cue = Groups.get_cue!(id)
    {:ok, _} = Groups.delete_cue(cue)

    {:noreply, assign(socket, :cues, list_cues())}
  end

  defp list_cues do
    Groups.list_cues()
  end
end
